local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-adoption-cold-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-adoption-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-adoption%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-adoption-cold-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.DisarmAdoptionStore');local models=assert(require('Training.FlowerPractice').models());local actor='wuyun'
  local saved=assert(S.loadAsync(actor,models));assert(saved.id==prior.active);r.coldRead=true
  -- A second request can change the revision while native source rebuilding yields.
  local P=require('Training.DisarmPolicy');local build=P.buildAsync;local count=0;local expected=S.state(actor)
  P.buildAsync=function(...)
   local result,why=build(...);count=count+1
   if count==2 then assert(D.DB:exec("UPDATE lsd.Game0DisarmAdoptionState SET revision=revision+1 WHERE actor='wuyun'")==1)end
   return result,why
  end
  local yes,reason=S.adoptAsync(saved.bundle,{accepted=true,comparisonId=saved.bundle.comparison.id,review=saved.proof.review},models,expected)
  P.buildAsync=build;assert(not yes and reason=='ADOPTION_CHANGED',reason);assert(S.state(actor).current==saved.id);r.changedDuringRebuildRejected=true
  assert(D.DB:exec('DELETE FROM lsd.Game0DisarmCandidates')>=0 and D.DB:exec('DELETE FROM lsd.Game0DisarmComparisons')>=0)
  assert(S.loadAsync(actor,models).id==saved.id);r.frozenSourceSurvivesCleanup=true
  local invalid,reason=S.loadAsync(actor,{});assert(not invalid and reason=='BASE_MODELS_CHANGED')
  local Rules=require('Training.DisarmRules');local version=Rules.version;Rules.version='qa-different-rules'
  local invalid,reason=S.loadAsync(actor,models);assert(not invalid and reason=='ENCOUNTER_CHANGED');assert(S.inspectAsync(actor).id==saved.id);Rules.version=version;r.runtimeRulesAndModelsChecked=true
  local row=assert(D.DB:query('SELECT payload FROM lsd.Game0DisarmAdoptions WHERE id=?',{saved.id}))[1][1]
  local broken=D.json.decode(row,32);broken.bundle.candidate.payload='{}'
  assert(D.DB:exec('UPDATE lsd.Game0DisarmAdoptions SET payload=? WHERE id=?',{D.json.encode(broken,false,true),saved.id})==1)
  local invalid,reason=S.loadAsync(actor,models);assert(not invalid and reason=='INVALID_SOURCE');r.corruptSourceRejected=true
  assert(D.DB:exec('UPDATE lsd.Game0DisarmAdoptions SET payload=? WHERE id=?',{row,saved.id})==1);assert(S.loadAsync(actor,models).id==saved.id)
  assert(D.DB:exec("UPDATE lsd.Game0DisarmAdoptions SET parent='invalid' WHERE id=?",{saved.id})==1)
  local invalid,reason=S.loadAsync(actor,models);assert(not invalid and reason=='INVALID_ADOPTION')
  assert(D.DB:exec('UPDATE lsd.Game0DisarmAdoptions SET parent=? WHERE id=?',{saved.parent,saved.id})==1)
  local revision=S.state(actor).revision
  assert(D.DB:exec("UPDATE lsd.Game0DisarmAdoptionState SET revision='invalid' WHERE actor=?",{actor})==1)
  local invalid,reason=S.loadAsync(actor,models);assert(not invalid and reason=='READ_FAILED')
  assert(D.DB:exec('UPDATE lsd.Game0DisarmAdoptionState SET revision=? WHERE actor=?',{revision,actor})==1);r.corruptMetadataRejected=true
  local yes,reason=S.rollbackAsync(actor,S.state(actor));assert(yes and reason=='RESTORED_BASIC');r.coldRollback=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
