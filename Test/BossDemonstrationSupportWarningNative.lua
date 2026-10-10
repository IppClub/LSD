-- Earned parent archive, original training/loadout/movement and withdrawal UI.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/boss-demonstration-support-warning-result.json'
local r={status='RUNNING',osInput=false,shotsNotRequired=true,screenshots={}}
local c
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(parent.status=='PASS'and parent.protectedStateUnchanged)
  local db=D.Content.writablePath..'/boss-demonstration-support-warning-'..os.time()..'.db';r.database=db;r.parentDatabase=parent.database
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(parent.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn,t)local endAt=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<endAt,'Warning route deadline');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
  c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  c.hud.move:emit('Right',true)
  wait(function()return b.phase~='playing'or b.arena.student.x>=2800 end,20)
  c.hud.move:emit('Right',false);assert(b.phase=='playing','Machine fell before reaching warning position')
  for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
   D.App.winSize=D.Size(size[1],size[2]);D.sleep(.2)
   assert(b.cameraFrame and b.controlledUnit==b.arena.student,'Camera did not own the demonstrated actor')
   assert(b.bossCombat.boss.enemy.unitDef.scale==1,'Boss authored scale changed')
   local text=require('Ground.BigYingzhaoLevel').supportWarningText(b)
   assert(text~=''and c.status.text:find(text,1,true),'Demonstration dropped actual support warning')
   assert(c.headerHeight>=c.status.height+50,'Warning extends past header')
   assert(c.status.textWidth<=c.controls.width-390,'Warning entered button column')
   local holder=c.targetButtons.head.parent
   assert(holder.y+16<=c.status.y-c.status.height,'Selector overlaps status text')
   assert(holder.y-16>=c.controls.height-c.headerHeight,'Selector extends past header')
   local path=D.Path(D.Content.writablePath,'demonstration-support-warning-'..size[3]..'.tga');D.App:saveScreenshot(path);D.sleep(.05)
   r.screenshots[#r.screenshots+1]={path=path,text=text,status=c.status.text,height=c.status.height,headerHeight=c.headerHeight,width=D.App.bufferSize.width,bufferHeight=D.App.bufferSize.height,machineX=b.support.x,machineHP=b.support.machineHP,gold=b.support.gold,ownX=b.arena.student.x};save()
  end
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'or c.phase=='save-error'end)
  assert(c.phase=='result'and b.demonstrationSourceId,'Withdrawal did not save observation')
  r.sourceId=b.demonstrationSourceId;r.trace=b.bossTrace;r.actualWithdrawal=true
  c.result.baseButton:emit('Tapped');wait(controls);r.returnedToTraining=true
 end,debug.traceback)
 if not ok and c then
  if c.battle.phase=='playing'then c.withdraw:emit('Tapped')end
  local stop=D.App.runningTime+20;while c.phase~='result'and c.phase~='save-error'and D.App.runningTime<stop do D.sleep(.02)end
 end
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
