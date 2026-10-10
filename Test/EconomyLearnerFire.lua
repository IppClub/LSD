local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/economy-learner-fire-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local path=D.Content.writablePath..'/learner-economy-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and not D.Content:exist(path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  local S=require('Economy.Store');assert(S.open())
  for _,case in ipairs({{id='ninilite',action='laser',item='emp',cost=7},{id='wuyun',action='melee',item='blade',cost=2}})do
   local a=require('Training.Arena').createAsync({characterId=case.id,enemySpeed=0,enemyMaxHP=1000,manualUpdate=true})
   assert(S.beginAsync(case.id,{{actor=case.id,item=case.item,quantity=1}},0));a.supplies=assert(require('Economy.CombatSession').open(case.id))
   local emitted=0;a.observeProjectile=function()emitted=emitted+1;assert(S.load(case.id).stock[case.id..':'..case.item].used==1)end
   a.student.faceRight=true;a.enemy.x=a.student.x+600;D.sleep(.3)
   local function attack()
    local deadline=D.App.runningTime+8
    while not a:available(case.action)do assert(D.App.runningTime<deadline,'not available');D.sleep(.01)end
    assert(a.student:start(a.physical[case.action]));D.sleep(.1)
    while a:isAttacking()do assert(D.App.runningTime<deadline,'animation timeout');D.sleep(.01)end
   end
   -- Near-miss melee is still a resource expenditure, independent of hit count.
   attack();assert(a.supplies.emissions==1 and S.load(case.id).spent==case.cost)
   assert(not a:available(case.action));a.mode='trial';local accepted,why=a:request(case.action,'model');assert(not accepted and why=='ACTION_UNAVAILABLE');assert(a.supplies.emissions==1)
   assert(emitted==(case.action=='laser' and 1 or 0))
   r.cases[#r.cases+1]={actor=case.id,cost=case.cost,emitted=emitted,maxCommitMs=a.supplies.maxCommitSeconds*1000}
   a.closed=true;a.world:removeFromParent();assert(S.settleAsync(case.id,'aborted'));D.sleep(.1)
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
