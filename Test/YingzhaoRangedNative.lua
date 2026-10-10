local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-ranged-result.json';local r={status='RUNNING',rounds={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-q-natural-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-q%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-ranged-'..os.time()..'.db';r.database=db;assert(not D.DB:existDB('lsd'))
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerPractice').models())
  local candidate=assert(require('Training.YingzhaoQStore').loadLatestAsync('ninilite'))
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true});assert(loadout)
  local report=require('Training.YingzhaoComparison').runAsync(models,candidate.model,loadout,function(round)
   local shots,farShots=0,0;local distances={}
   for _,step in ipairs(round.trace.steps)do if step.actor=='mentor'and step.action=='shoot'and step.before.bossVisible then
    shots=shots+1;local distance=step.before.distance;distances[#distances+1]=distance;if distance>=850 then farShots=farShots+1 end
   end end
   r.rounds[#r.rounds+1]={mode=round.mode,status=round.status,seconds=round.seconds,cost=round.cost,hp=round.hp,bossHP=round.bossHP,armor=round.armorDamage,damage=round.healthDamage,shots=shots,farShots=farShots,distances=distances};save()
  end)
  r.report=report;assert(report.controller==require('Training.YingzhaoMentor').version)
  assert(r.rounds[1].farShots>0 and r.rounds[2].farShots>0,'No actual ranged shots')
  local id,why=require('Training.YingzhaoComparisonStore').saveAsync(report);assert(id,why);r.saved=id
  assert(require('Training.FlowerIdentity').equal(assert(require('Training.YingzhaoQStore').loadLatestAsync('ninilite')).model,candidate.model))
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
