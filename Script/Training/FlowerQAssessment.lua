-- A review binds the current candidate and every stored trial, never a best-case subset.
local D=require('Dora');local equal=require('Training.FlowerIdentity').equal;local A={}
local ids={'near','far','reproduction','field'}
function A.describe(saved,review)
 local trained={};local unknown=false
 for _,item in ipairs(saved.chain)do
  if item.source.kind=='explore' and require('Training.FlowerScenarios').get(item.source.profile)then trained[item.source.profile]=true else unknown=true end
 end
 local result={schemaVersion=1,candidate=saved.id,readyForDecision=true,profiles={},warnings={},blocked={},review=review}
 for _,id in ipairs(ids)do
  local p=review.profiles[id];local profile={training=trained[id] and 'trained' or unknown and 'unknown' or 'not-observed',basic=p.basic.count,candidate=p.evaluate.count}
  result.profiles[id]=profile
  if not p.delta then result.blocked[#result.blocked+1]=id..':missing-pair';result.readyForDecision=false end
  if p.basic.timed==0 or p.evaluate.timed==0 or p.evaluate.sourceGames==0 then result.blocked[#result.blocked+1]=id..':missing-telemetry';result.readyForDecision=false end
  if p.basic.count<2 or p.evaluate.count<2 then result.warnings[#result.warnings+1]=id..':limited-repetition'end
  if p.delta and p.delta.teamDamage>0 then result.warnings[#result.warnings+1]=id..':more-team-damage'end
  if p.evaluate.failed>0 then result.warnings[#result.warnings+1]=id..':candidate-losses'end
 end
 if unknown then result.warnings[#result.warnings+1]='training-profile-unknown'end
 -- Readiness is enough evidence for a player's choice, never a claim of benefit.
 result.warnings[#result.warnings+1]='stable-benefit-unproven'
 return result
end
local function capture(models)
 local Store=require('Training.FlowerQStore');local saved,why=Store.loadAsync();if not saved then return nil,why end
 if not equal(models,saved.source.baseModels)then return nil,'BASE_MODELS_CHANGED'end
 local sql='SELECT id,candidate,episode,payload FROM lsd.Game0FlowerQTrials WHERE candidate=? ORDER BY id DESC'
 -- Ensure trial table exists and capture exact rows before the yielding replay.
 local records,why=require('Training.FlowerQTrials').loadAsync(saved.id);if not records then return nil,why end
 local raw=D.DB:query(sql,{saved.id});if not raw then return nil,'READ_FAILED'end
 -- Match the raw read to the validated records, including their payload contents.
 if #raw~=#records then return nil,'Q_TRIALS_CHANGED'end
 for i,row in ipairs(raw)do
  local decoded=D.json.decode(row[4],32);local record={};for k,v in pairs(records[i])do if k~='facts' and k~='telemetry' and k~='id'then record[k]=v end end
  if row[1]~=records[i].id or not equal(decoded,record)then return nil,'Q_TRIALS_CHANGED'end
 end
 local sources={}
 for _,item in ipairs(saved.chain)do
  local rows=D.DB:query('SELECT parent,payload FROM lsd.Game0FlowerQSources WHERE id=?',{item.id})
  if not rows or not rows[1] or rows[1][1]~=item.parent or rows[1][2]~=item.payload then return nil,'Q_SOURCE_CHANGED'end
  sources[#sources+1]={id=item.id,parent=item.parent,payload=item.payload}
 end
 local pointer=D.DB:query('SELECT current FROM lsd.Game0FlowerQDraft WHERE singleton=1')
 if not pointer or not pointer[1] or pointer[1][1]~=saved.id then return nil,'Q_DRAFT_CHANGED'end
 local review=require('Training.FlowerQReview').build(saved.id,records,require('Factory.Rules').hitReaction,7)
 return {schemaVersion=1,qFeatureVersion=7,hitReaction=require('Factory.Rules').hitReaction,candidate=saved.id,models=models,sources=sources,trials=raw,assessment=A.describe(saved,review)}
end
function A.captureAsync(models)
 -- Freeze the caller's baseline before any replay yields.
 local frozen=D.json.decode(D.json.encode(models,false,true),32)
 local ok,result,why=xpcall(function()return capture(frozen)end,debug.traceback)
 if not ok then return nil,'Q_ASSESSMENT_ERROR',result end
 if result then result=D.json.decode(D.json.encode(result,false,true),32)end
 return result,why
end
function A.verifyAsync(bundle,models)
 local frozen=D.json.decode(D.json.encode(bundle,false,true),32)
 local latest,why=A.captureAsync(models);if not latest then return false,why end
 if not equal(latest,frozen)then return false,'REVIEW_STALE'end
 return true
end
-- Archived adoption evidence survives new draft versions and additional evaluations.
-- Its own immutable dependencies must still exist and match exactly.
function A.readArchiveAsync(bundle)
 local ok,result=xpcall(function()
  bundle=D.json.decode(D.json.encode(bundle,false,true),32)
  assert(bundle.schemaVersion==1,'INVALID_Q_ARCHIVE')
  local saved,why=require('Training.FlowerQStore').loadVersionAsync(bundle.candidate);assert(saved,why)
  assert(equal(bundle.models,saved.source.baseModels) and #bundle.sources==#saved.chain,'Q_SOURCE_CHANGED')
  for i,item in ipairs(saved.chain)do assert(equal(bundle.sources[i],{id=item.id,parent=item.parent,payload=item.payload}),'Q_SOURCE_CHANGED')end
  local records={};local previous=math.huge
  for _,row in ipairs(bundle.trials)do
   assert(type(row[1])=='number' and row[1]>0 and row[1]<previous and row[2]==saved.id,'INVALID_TRIAL_ID');previous=row[1]
   local decoded=D.json.decode(row[4],32);assert(decoded.candidate==saved.id and decoded.episode.episode==row[3],'TRIAL_ID_MISMATCH')
   local record,why=require('Training.FlowerQTrials').validateRecordAsync(decoded);assert(record,why);records[#records+1]=record
  end
  local assessment=A.describe(saved,require('Training.FlowerQReview').build(saved.id,records,bundle.hitReaction,bundle.qFeatureVersion))
  assessment=D.json.decode(D.json.encode(assessment,false,true),32)
  assert(equal(assessment,bundle.assessment) and assessment.readyForDecision,'INVALID_ARCHIVED_REVIEW')
  for _,source in ipairs(bundle.sources)do
   local rows=D.DB:query('SELECT parent,payload FROM lsd.Game0FlowerQSources WHERE id=?',{source.id})
   assert(rows and rows[1] and rows[1][1]==source.parent and rows[1][2]==source.payload,'Q_SOURCE_CHANGED')
  end
  for _,row in ipairs(bundle.trials)do
   local rows=D.DB:query('SELECT id,candidate,episode,payload FROM lsd.Game0FlowerQTrials WHERE id=?',{row[1]})
   assert(rows and equal(rows[1],row),'Q_TRIALS_CHANGED')
  end
  return {models=saved.models,assessment=assessment,candidate=saved.id}
 end,debug.traceback)
 if not ok then return nil,'INVALID_Q_ARCHIVE',result end;return result
end
function A.text(assessment,id)
 local p=assessment.profiles[id]
 local label=({trained='该配置已用于训练',unknown='早期训练来源未记录配置，不能认定为未见场景',['not-observed']='完整来源链未使用该配置；尚未证明泛化收益'})[p.training]
 local text=label..string.format('；重复对照：基础%d场 / 候选%d场。',p.basic,p.candidate)
 if assessment.readyForDecision then return text..'\n证据可供玩家审查取舍；不代表推荐采用。'end
 return text..'\n审查证据未齐：四场景均需基础/候选对照及有效用时、候选决策来源。'
end
return A
