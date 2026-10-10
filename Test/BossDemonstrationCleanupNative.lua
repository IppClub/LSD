-- Reproduce world-first cleanup using actual Boss physics and original HUD.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=D.Path(root,'Test/boss-demonstration-cleanup-result.json')
local r={status='RUNNING',osInput=false,virtual=true,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),64)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-'))
  r.source=prior.database;r.database=D.Path(D.Content.writablePath,'boss-cleanup-'..os.time()..'.db')
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(r.source,r.database));assert(D.DB:exec("ATTACH DATABASE '"..r.database.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerPractice').models())
  for _,kind in ipairs({'demonstration','formal-controls'})do
   local supplies=assert(require('Economy.CombatSession').virtual('cleanup:'..kind,{{actor='mentor',item='kinetic',quantity=3},{actor='ninilite',item='emp',quantity=3},{actor='wuyun',item='blade',quantity=3}}))
   local level= require('Factory.PatrolLevel').openAsync(models,function()end,{battleFactory=function()
    local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true,physicalSupport=true})
    if kind=='demonstration'then require('Training.YingzhaoDemonstration').attach(b,'ninilite')end
    return b
   end})
   local b=level.battle;assert(b.world.parent and b.arena.student.parent);level.start:emit('Tapped');D.sleep(.15);assert(b.phase=='playing')
   level.hud.move:emit('Left',true);D.sleep(.1);level.hud.move:emit('Left',false);D.sleep(.1)
   local allowed,reason=b:command('stop');assert(allowed~=false or reason=='ACTION_BUSY','Live stop refused')
   -- Shut down world before independent HUD, matching native shutdown order.
   b.world:removeFromParent();D.sleep(.05);assert(b.arena.closed)
   if kind=='demonstration'then local accepted,reason=b:command('stop');assert(accepted==false and reason=='CLOSED','Closed demonstrator accepted stop')end
   level.controls:removeFromParent();level.hud:removeFromParent();D.sleep(.1)
   r.cases[#r.cases+1]={kind=kind,worldClosed=true,uiRemoved=true,liveStopPreserved=true};save()
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save();print('LSD_BOSS_DEMONSTRATION_CLEANUP_'..r.status)
end)
