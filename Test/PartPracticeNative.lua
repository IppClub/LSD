local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-practice-native-result.json';local r={status='RUNNING',osInput=false}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/part-practice.db';assert(not D.Content:exist(db) and not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  require('Data.Config'):loadAsync();require('Training.Level')(nil,'ninilite')
  local function wait(f)local limit=D.App.runningTime+20;while not f()do assert(D.App.runningTime<limit,'Practice wait');D.sleep(.02)end end
  wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local controls=D.Director.ui3D:getChildByTag('training-controls');controls:getChildByTag('training-menu'):getChildByTag('护甲靶练习'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('part-practice')end)
  local ui=D.Director.ui3D:getChildByTag('part-practice');local p=ui.practice;local a=p.arena
  wait(function()return a.student.onSurface and a.enemy.onSurface end)
  p.partCombat.target:sample()
  r.geometry={student={x=a.student.x,y=a.student.y,facing=a.student.faceRight},enemy={x=a.enemy.x,y=a.enemy.y},muzzle=p.partCombat:muzzle(a.student),parts={}}
  for _,part in ipairs(p.partCombat.target.regions)do
   local aim=require('Combat.PartAim').solve(r.geometry.muzzle,a.student.faceRight,part.id,p.partCombat.target.regions,function()return false end)
   r.geometry.parts[#r.geometry.parts+1]={id=part.id,first=part.vertices[1],withoutTerrain=aim~=nil}
  end
  save()
  ui:getChildByTag('下个可达部位'):emit('Tapped');assert(p.index>0,p.message)
  D.sleep(.05)
  local line=a.student:getChildByTag('aim');assert(line and line.visible and line.parent==a.student and line.scaleX==1)
  local solution=p.partCombat:aim(a.student,p.partCombat.selectedPart,true);assert(math.abs(line.angle-solution.angle)<1)
  r.tutorialPreview=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/tutorial-preview-reuse.tga');D.sleep(.1)
  local intended=p.partCombat.selectedPart
  D.emit('Skill.Began');wait(function()return #p.partCombat.events>0 end)
  assert(#p.demonstrations==1 and p.demonstrations[1].intendedPart==intended and p.demonstrations[1].state.armorState=='unknown')
  assert(p.partCombat.events[1].part==intended and p.partCombat.view.part==intended)
  r.hit={intended=intended,actual=p.partCombat.events[1].part,armor=p.partCombat.events[1].armorDamage}
  D.sleep(.1);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/target-adoption-ui-aimed.tga');D.sleep(.1)
  wait(function()return not a:isAttacking()end)
  for i=2,6 do
   wait(function()return a:available('laser')end)
   assert(a.selectPart(i%2==0 and 'front-leg' or 'head'));D.emit('Skill.Began')
   wait(function()local demo=p.demonstrations[i];return demo and demo.step.sealed and not a:isAttacking()end)
  end
  ui:getChildByTag('学习部位选择'):emit('Tapped');wait(function()return p.candidate~=nil end)
  assert(p.candidate.weapon=='emp' and p.candidate.tree.sampleCount==6)
  local candidate=p.candidate
  wait(function()return a:available('laser')end)
  ui:getChildByTag('候选试射'):emit('Tapped');D.sleep(.1)
  wait(function()return not a:isAttacking() and #p.partCombat.shots==0 end)
  assert(#p.demonstrations==6 and p.candidate==candidate)
  for _,demo in ipairs(p.demonstrations)do assert(demo.step.action.controller=='demo')end
  assert(p.partCombat.journal.steps[#p.partCombat.journal.steps].action.controller=='target-model')
  r.learnButton=true;r.trialButton=true;r.targetSamples=6
  ui:getChildByTag('三场部位对照'):emit('Tapped')
  local deadline=D.App.runningTime+120;while not p.evaluation do assert(D.App.runningTime<deadline,p.message or 'Comparison timeout');D.sleep(.05)end
  assert(p.evaluation.model==candidate and #p.demonstrations==6);r.compareButton=true
  local old=p.partCombat
  ui:getChildByTag('重置护甲靶'):emit('Tapped');assert(old.closed and old.journal.closed and p.partCombat~=old)
  assert(#p.rounds>=1 and #p.demonstrations==6 and p.index==0)
  for _,part in pairs(p.partCombat.target.damage.parts)do assert(part.ap==part.maxAP)end
  local hud=D.Director.ui3D:getChildByTag('part-practice-hud')
  wait(function()return a.student.onSurface end)
  local x=a.student.x;hud.move:emit('Left',true);D.sleep(.3);hud.move:emit('Left',false);D.sleep(.1)
  assert(a.student.x<x and a.student.velocityX==0)
  r.sizes={}
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.5);local buffer=D.App.bufferSize
   for _,tag in ipairs({'下个可达部位','重置护甲靶','返回普通对练','返回训练室','学习部位选择','候选试射','三场部位对照','采用部位规则','回滚部位规则','自主部位练习','停止自主练习'})do
    local b=ui:getChildByTag(tag);local pos=b:convertToWorldSpace(D.Vec2.zero)+D.Vec2(buffer.width/2,buffer.height/2)
    assert(pos.x>=0 and pos.y>=0 and pos.x+b.width*b.scaleX*ui.scaleX<=buffer.width and pos.y+b.height*b.scaleY*ui.scaleY<=buffer.height,'Practice button out of bounds')
   end
   r.sizes[#r.sizes+1]={width=buffer.width,height=buffer.height}
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/target-adoption-ui-'..buffer.width..'x'..buffer.height..'.tga');D.sleep(.1)
  end
  ui:getChildByTag('采用部位规则'):emit('Tapped');wait(function()return p.adopted~=nil and not p.saving end)
  assert(p.adopted==candidate and p.candidate==nil);r.adoptButton=true
  ui:getChildByTag('返回普通对练'):emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  assert(p.phase=='closed' and #D.DB:query('SELECT * FROM lsd.Game0Training')==0)
  local entry=D.Director.ui3D:getChildByTag('training-controls');entry:getChildByTag('training-menu'):getChildByTag('护甲靶练习'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('part-practice')end)
  local reopened=D.Director.ui3D:getChildByTag('part-practice').practice
  assert(reopened.savedTrace and #reopened.savedTrace.demonstrations==6 and reopened.adopted.traceId==candidate.traceId)
  D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/target-trace-ui-reopened.tga');D.sleep(.1)
  r.traceReopened=true
  local reopenedUI=D.Director.ui3D:getChildByTag('part-practice')
  local traceId=reopened.adopted.traceId
  reopenedUI:getChildByTag('自主部位练习'):emit('Tapped');wait(function()return reopened.partQTraining end)
  D.emit('Skill.Began');D.sleep(.2);assert(#reopened.demonstrations==0)
  reopenedUI:getChildByTag('停止自主练习'):emit('Tapped');wait(function()return not reopened.partQTraining end)
  assert(reopened.adopted.traceId==traceId and reopened.qPracticeReport.status=='CANCELLED')
  r.partQButtons=true;r.partQCancelPreservesAdopted=true
  r.resetRestoresArmor=true;r.joystick=true;r.originalActionModelUntouched=true;r.returned=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
