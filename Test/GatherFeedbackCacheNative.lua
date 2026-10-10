-- Real unified controls and virtual battle, attacks isolated for UI observation.
-- No formal victory or adopted model claim.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/gather-feedback-cache-result.json'
local r={status='RUNNING',controlledFixture=true,naturalVictory=false,osInput=false,screenshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local c=require('Factory.PatrolLevel').openAsync(models,function()return true end,{battleFactory=function(m)
   local supply=assert(require('Economy.CombatSession').virtual('gather-ui:'..D.App.runningTime,{{actor='ninilite',item='emp',quantity=4}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(m,supply,{virtual=true,physicalSupport=true})
   b.bossCombat.boss.guard.update=function()end;return b
  end,presentation={title='集合反馈专项',headerHeight=function()return 220 end}})
  local b=c.battle
  local function wait(fn,t)local limit=D.App.runningTime+(t or 5);while not fn()do assert(D.App.runningTime<limit,'Gather UI feedback timeout');D.sleep(.01)end end
  local frames=0;local monitor=D.Node();monitor:addTo(c.controls);monitor:schedule(function()frames=frames+1;return false end)
  D.sleep(.2);local writes=c.gatherLabelWrites or 0;local start=frames;D.sleep(1)
  r.ready={frames=frames-start,writes=(c.gatherLabelWrites or 0)-writes,text=c.gather.textLabel.text}
  assert(r.ready.frames>=30 and r.ready.writes==0 and r.ready.text=='集合 G\n长按恢复')
  D.App.winSize=D.Size(960,540);D.sleep(.1)
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end);D.sleep(.3)
  c.hud.move:emit('Left',true);D.sleep(1.4);c.hud.move:emit('Left',false);D.sleep(.1)
  c.gather:emit('TapBegan');c.gather:emit('TapEnded')
  wait(function()return c.gather.textLabel.text:find('集合中',1,true)end)
  assert(b.gatherMode=='normal'and b:gatherActive());r.normalText=c.gather.textLabel.text
  local original=D.App.winSize
  local function shot(name)
   local p=D.Path(D.Content.writablePath,name..'.tga');D.App:saveScreenshot(p);D.sleep(.03)
   r.screenshots[#r.screenshots+1]={path=p,text=c.gather.textLabel.text,width=D.App.bufferSize.width,height=D.App.bufferSize.height}
  end
  shot('gather-normal-1920')
  writes=c.gatherLabelWrites or 0;start=frames;D.sleep(.5)
  r.active={frames=frames-start,writes=(c.gatherLabelWrites or 0)-writes}
  assert(r.active.frames>=20 and r.active.writes<=8,'Countdown rebuilt more often than visible text changed')
  c.controls:emit('KeyDown','G');D.sleep(.1);c.controls:emit('KeyDown','G');c.controls:emit('KeyUp','G')
  assert(not b:gatherActive());wait(function()return c.gather.textLabel.text=='集合 G\n长按恢复'end)
  c.hud.move:emit('Right',true);D.sleep(1.5);c.hud.move:emit('Right',false);D.sleep(.1)
  c.gather:emit('TapBegan');D.sleep(.7);c.gather:emit('TapEnded')
  wait(function()return c.gather.textLabel.text:find('恢复集合',1,true)end)
  assert(b.gatherMode=='recover');r.recoveryText=c.gather.textLabel.text
  D.App.winSize=D.Size(683,384);D.sleep(.05);shot('gather-recovery-1366')
  c.gather:emit('TapBegan');c.gather:emit('TapEnded');wait(function()return not b:gatherActive()end)
  wait(function()return c.gather.textLabel.text=='集合 G\n长按恢复'end)
  r.cancelled=true;D.App.winSize=original
  writes=c.gatherLabelWrites or 0;start=frames;D.sleep(.5)
  r.cancelledIdle={frames=frames-start,writes=(c.gatherLabelWrites or 0)-writes};assert(r.cancelledIdle.writes==0)
  r.ammo=b.supplies:observation('ninilite').ammo.emp;assert(r.ammo==4)
  b:finish('aborted','Gather feedback cache fixture');r.totalWrites=c.gatherLabelWrites
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
