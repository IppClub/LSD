-- A separate C4.5 decision stage: choose a part after deciding to shoot.
-- It cannot be passed off as a character combat-action model.
local Recorder=require('Training.Recorder');local Model=require('Training.Model')
local T={parts={head='head',gem='head-gem',front_back='back-front',rear_back='back-rear',front_leg='front-leg',rear_leg='rear-leg',tail='tail'}}
local actions,legal,labels={},{},{}
for action,part in pairs(T.parts)do actions[#actions+1]=action;legal[action]=true;labels[part]=action end
table.sort(actions)
function T.validate(candidate,characterId,enemyAsset)
 if type(candidate)~='table' or candidate.schemaVersion~=1 or candidate.purpose~='part-target' or candidate.partSetVersion~=1 or candidate.weapon~='emp' or candidate.enemyAsset~='dataotie' or (enemyAsset and candidate.enemyAsset~=enemyAsset) then return false,'INCOMPATIBLE_TARGET_POLICY'end
 if not require('Training.Characters')[candidate.characterId] or (characterId and candidate.characterId~=characterId)then return false,'INCOMPATIBLE_CHARACTER'end
 if candidate.traceId~=nil and (type(candidate.traceId)~='string' or #candidate.traceId>100 or not candidate.traceId:match('^[%w%-]+$'))then return false,'INVALID_TRACE_ID'end
 if candidate.q then
  if candidate.tree or not candidate.traceId then return false,'AMBIGUOUS_TARGET_MODEL'end
  return require('Training.PartQ').validate(candidate.q,candidate.characterId)
 end
 local tree=candidate.tree
 if type(tree)~='table' or tree.algorithm=='qlearning' or (tree.featureSchemaVersion~=3 and tree.featureSchemaVersion~=4) then return false,'INVALID_TARGET_TREE'end
 return Model.validate(tree,candidate.characterId,legal)
end
function T.recordDemonstrations(characterId,demonstrations,version)
 local rec=Recorder.new({characterId=characterId,actions=actions,featureSchemaVersion=version or 4});local rounds={}
 for _,demo in ipairs(demonstrations)do
  local step=demo.step;local label=labels[demo.intendedPart]
  if label and step and step.sealed and not step.truncated and type(step.action)=='table' and step.action.controller=='demo' and step.action.intendedPart==demo.intendedPart and (step.action.emitted or 0)>0 and not step.action.shotRejected and type(step.action.aimAngle)=='number' and math.abs(step.action.aimAngle)<=45 then
   -- Each emitted shot is a demonstration, even when state and part repeat.
   rec.lastKey=nil
   local ok,why=rec:record(demo.state,label,true);if not ok then return nil,why end
   rounds[demo.round]=true
  end
 end
 return rec,rounds
end
function T.buildAsync(characterId,enemyAsset,demonstrations)
 if not require('Training.Characters')[characterId] or enemyAsset~='dataotie'then return nil,'UNSUPPORTED_TARGET'end
 local rec,rounds=T.recordDemonstrations(characterId,demonstrations);if not rec then return nil,rounds end
 local variety=0;for _ in pairs(rec.counts)do variety=variety+1 end
 if #rec.samples<6 or variety<2 then return nil,'INSUFFICIENT_TARGET_COVERAGE'end
 local tree,why=Model.buildAsync(rec);if not tree then return nil,why end
 local roundCount=0;for _ in pairs(rounds)do roundCount=roundCount+1 end
 local candidate={traceId='part-'..os.time()..'-'..math.floor(require('Dora').App.runningTime*1000000),schemaVersion=1,purpose='part-target',weapon='emp',roundCount=roundCount,partSetVersion=1,characterId=characterId,enemyAsset=enemyAsset,tree=tree}
 local ok,err=T.validate(candidate,characterId,enemyAsset);if not ok then return nil,err end
 return candidate
end
function T.predict(candidate,state,available,characterId,enemyAsset)
 local ok,why=T.validate(candidate,characterId,enemyAsset);if not ok then return nil,why end
 local predict=candidate.q and require('Training.PartQ').predict or Model.predict
 local label,reason=predict(candidate.q or candidate.tree,state,function(action)return available(T.parts[action])end)
 return label and T.parts[label] or nil,reason
end
-- Only coverage gaps in a validated Q policy may use ordinary shooting.
function T.resolve(candidate,state,available,characterId,enemyAsset)
 local part,why=T.predict(candidate,state,available,characterId,enemyAsset)
 local fallback=not part and type(candidate)=='table' and candidate.q and (why=='UNSEEN_STATE' or why=='UNSEEN_ACTIONS') or false
 return part,why,fallback
end
return T
