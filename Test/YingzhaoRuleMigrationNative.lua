-- Cold-read a real prior adopted checkpoint; never migrate or erase it.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-rule-migration-result.json';local r={status='RUNNING',osInput=false,checks={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS' and prior.algorithm=='yingzhao-c45' and prior.adoptedCheckpoint:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-ui%-adopted%-checkpoint%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-rule-migration-'..os.time()..'.db';r.database=db;r.parentEvidence=parent;save();assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.adoptedCheckpoint,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.YingzhaoAdoptionStore');local models=assert(require('Training.FlowerPractice').models());local before={}
  for _,tableName in ipairs({'Game0YingzhaoAdoptions','Game0YingzhaoAdoptionState','Game0YingzhaoCandidates','Game0YingzhaoComparisons','Game0Training','Game0Training_wuyun','Game0MissionAttempts'})do before[tableName]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..tableName..' ORDER BY 1'),false,true)end
  local wallet=require('Economy.Store');assert(wallet.open());local balance=wallet.wallet().available
  local saved=assert(S.inspectAsync('ninilite'));assert(saved.id==prior.active and saved.proof.record.setup.combatRules~=require('Training.YingzhaoRules').version)
  for _,scope in ipairs({'practice','mission'})do local active,why=S.loadAsync('ninilite',models,scope);assert(not active and why=='ENCOUNTER_CHANGED');r.checks[scope..'RejectsStale']=true end
  assert(S.state('ninilite').current==prior.active and S.state('wuyun').current==0)
  for tableName,rows in pairs(before)do assert(rows==D.json.encode(D.DB:query('SELECT * FROM lsd.'..tableName..' ORDER BY 1'),false,true),'Rule check changed '..tableName)end
  assert(wallet.wallet().available==balance and not wallet.active());r.balance=balance;r.active=prior.active;r.oldRules=saved.proof.record.setup.combatRules;r.currentRules=require('Training.YingzhaoRules').version;r.checks.recordsModelsWalletPreserved=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
