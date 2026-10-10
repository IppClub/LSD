-- Real unified controls and natural deadline; controlled placement/idle models.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/gather-deadline-feedback-result.json';local r={status='RUNNING',controlledFixture=true,osInput=false,naturalVictory=false,screenshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local original=D.json.encode(models)
  local c=require('Factory.PatrolLevel').openAsync(models,function()return true end,{battleFactory=function(m)
   local supply=assert(require('Economy.CombatSession').virtual('deadline-feedback',{{actor='ninilite',item='emp',quantity=4}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(m,supply,{virtual=true,physicalSupport=true});b.bossCombat.boss.guard.update=function()end;return b
  end,presentation={title='集合到期反馈专项',headerHeight=function()return 220 end}})
  local b=c.battle
  local function wait(fn,t)local limit=D.App.runningTime+(t or 8);while not fn()do assert(D.App.runningTime<limit,'Gather deadline feedback stalled');D.sleep(.01)end end
  wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.wuyun.student.onSurface end)
  b.wuyun.student.x=1600;c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  c.gather:emit('TapBegan');D.sleep(.7);c.gather:emit('TapEnded')
  c.hud.move:emit('Left',true)
  local record=b.bossTrace.gathers[#b.bossTrace.gathers];local deadline=record.deadline
  wait(function()return record.ended end,15);c.hud.move:emit('Left',false)
  r.record=record;r.text=c.gather.textLabel.text;save()
  assert(record.reason=='DEADLINE'and record.deadline==deadline)
  assert(b.gatherFeedback and b.gatherFeedback.text=='集合未到齐\n再按 G 重整','Natural deadline silently returned to default')
  wait(function()return c.gather.textLabel.text==b.gatherFeedback.text end)
  local previous=D.App.winSize
  for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
   D.App.winSize=D.Size(size[1],size[2]);D.sleep(.1)
   local path=root..'/Test/gather-deadline-feedback-'..size[3]..'.tga';D.App:saveScreenshot(path);D.sleep(.1)
   r.screenshots[#r.screenshots+1]={path=path,text=c.gather.textLabel.text,width=D.App.bufferSize.width,height=D.App.bufferSize.height}
  end
  D.App.winSize=previous
  local writes=c.gatherLabelWrites;D.sleep(.5);assert(c.gatherLabelWrites==writes,'Static feedback rebuilt every frame')
  wait(function()return c.gather.textLabel.text=='集合 G\n长按恢复'end,6);r.expiryRestored=true
  local F=require('Combat.Formation');local learners={{character={id='ninilite'},studentHP=100,student={x=1120}},{character={id='wuyun'},studentHP=100,student={x=1220}}}
  local plan={ninilite=1120,wuyun=1220}
  assert(F.deadlineFeedback(learners,plan,'recover',{100,80,100},nil,true)=='恢复已到期\n长按 G 继续')
  assert(F.deadlineFeedback(learners,plan,'normal',{100,80,100},nil,true)==nil)
  assert(F.deadlineFeedback(learners,plan,'recover',{100,100,100},nil,true)==nil)
  learners[1].student.x=1120+F.tolerance;assert(F.deadlineFeedback(learners,plan,'normal',{},nil,false)==nil)
  learners[1].student.x=1120+F.tolerance+.1;assert(F.deadlineFeedback(learners,plan,'normal',{},nil,false)=='集合未到齐\n再按 G 重整')
  learners[1].studentHP=0;assert(F.deadlineFeedback(learners,plan,'normal',{},nil,false)==nil)
  assert(F.deadlineFeedback(learners,plan,'recover',{100,80,100},nil,false)==nil)
  assert(F.deadlineFeedback(learners,nil,'recover',{100,80,100},nil,true)==nil)
  assert(b:command('gather')and b.gatherFeedback==nil,'New command retained old deadline warning')
  assert(original==D.json.encode(models));r.modelsUnchanged=true;r.staticWrites=0;r.semanticCases=8
  b:finish('aborted','Controlled deadline feedback complete')
  r.scope='Actual native moving recovery order, unextended natural deadline, unified HUD static feedback/two-size pixels/finite expiry/new-order clearing; controlled idle models/placement/disabled Boss attacks; not formal mission, OS or victory'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
