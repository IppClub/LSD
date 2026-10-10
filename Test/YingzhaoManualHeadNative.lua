-- Controlled static pose diagnostic; actual manual sweep/release, no locked aim.
local animated=os.getenv('LSD_QA_HEAD_ANIMATED')=='1'
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-manual-head-result.json';local r={status='RUNNING',controlledFixture=true,animatedPose=animated,angularSafetyMargin=animated and 1.2 or .2,osInput=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=os.getenv('LSD_QA_PARENT_RESULT')
  if parent then
   local prior=D.json.decode(assert(D.Content:load(parent)),32)
   assert(prior.status=='FAIL'and prior.checks.naturalFormalReportAndLedger and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'),'Require actual terminal formal encounter')
   local db=D.Path(D.Content.writablePath,'manual-female-geometry-'..os.time()..'.db')
   assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(prior.database,db))
   assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
   D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
   require('Data.Config'):loadAsync();assert(require('Data.Config').char=='charF','Actual formal mentor is not female')
   r.sourceDatabase=prior.database;r.database=db;r.character=require('Data.Config').char;r.parentEvidence=parent;save()
  else r.character=require('Data.Config').char or 'charM' end
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local supplies=assert(require('Economy.CombatSession').virtual('manual-head-fixture',{{actor='mentor',item='kinetic',quantity=96},{actor='ninilite',item='emp',quantity=4}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')},supplies,{virtual=true});assert(b:start());b.arena.mode='demo';b.wuyun.mode='review';local boss=b.enemies[1];boss.guard.nextAttack=math.huge;D.sleep(.5);if not animated then boss.enemy.playable.speed=0 else
   -- Controlled idle/hit geometry: ordinary damage recovery resets nextAttack,
   -- so suppress autonomous attacks each tick without freezing Spine playback.
   local update=boss.guard.update
   boss.guard.update=function(self,now)self.nextAttack=math.huge;return update(self,now)end
   r.guardNextAttackPinnedPerTick=true;r.bossFacesShooter=true
  end
  local function wait(fn)local stop=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<stop,'Manual head fixture stalled');D.sleep(.015)end end
  assert(require('Training.YingzhaoActions').request(b,b.arena,'shoot@head','test'));wait(function()return not b.arena:isAttacking()and not b.bossCombat:pendingActor('ninilite')end);assert(b.observeYingzhao(b.mentor).part_head=='exposed')
  local failures=0
  for _,direction in ipairs({1,-1})do for _,distance in ipairs({800,1300})do
   wait(function()return b.mentorAim.canStart()and not b.mentorAim.shot end)
   boss.enemy.x=direction==1 and 1920 or 1200;if animated then boss.enemy.faceRight=direction<0 end;b.mentor.x=boss.enemy.x-direction*distance;b.mentor.faceRight=direction==1;b.mentor.velocityX=0;D.sleep(.1)
   if animated then wait(function()return not boss.guard.reacting and boss.enemy.playable.current=='idle'end)end
   local plan,why=require('Training.YingzhaoActions').plan(b,{student=b.mentor},'head',true)
   local row={direction=direction,distance=distance,planned=plan,unreachable=why,poseAtPlan=boss.enemy.playable.current};r.cases[#r.cases+1]=row;save()
   if os.getenv('LSD_QA_HEAD_WINDOW_SCAN')=='1' then
    r.diagnosticCollectionOnly=true;row.windowScan={};row.actualSweep={};row.bossFliped=boss.enemy.playable.fliped
    local function contact(angle)
     local origin=require('Combat.Muzzle').manualPreview(b.world,b.mentor,angle,b.mentor.faceRight)
     local theta=-math.rad(angle);local side=b.mentor.faceRight and 1 or -1
     local hit,terrain=b.bossCombat:contact(origin,{x=origin.x+side*2400*math.cos(theta),y=origin.y+2400*math.sin(theta)})
     return terrain and 'terrain'or not hit and 'miss'or hit.enemy and 'summon'or hit.part
    end
    for tenth=-450,450 do local angle=tenth/10;row.windowScan[#row.windowScan+1]={angle=angle,part=contact(angle)}end
    assert(b.mentorAim:begin());local untilAt=D.App.runningTime+1.2
    while D.App.runningTime<untilAt do
     D.sleep(.015);local angle=b.mentorAim.angle
     row.actualSweep[#row.actualSweep+1]={angle=angle,part=contact(angle),at=D.App.runningTime-b.mentorAim.started,fliped=boss.enemy.playable.fliped}
    end
    b.mentorAim:cancel();save()
   end
   if plan and os.getenv('LSD_QA_HEAD_WINDOW_SCAN')~='1'then
    local first=#b.bossTrace.steps;local hitCount=#b.bossTrace.hits;local used=supplies.emissions
    assert(b.mentorAim:begin());row.aimRetries=0
    wait(function()
     if D.App.runningTime-b.mentorAim.started<=.15 then return false end
     -- Release when the displayed ray is safely inside the visible head, not
     -- merely within 1.5 degrees of a continuous plan beside another body part.
     local margin=animated and 1.2 or .2
     for _,delta in ipairs({-margin,0,margin})do
      local angle=b.mentorAim.angle+delta
      local origin=require('Combat.Muzzle').manualPreview(b.world,b.mentor,angle,b.mentor.faceRight)
      local theta=-math.rad(angle);local direction=b.mentor.faceRight and 1 or -1
      local hit,terrain=b.bossCombat:contact(origin,{x=origin.x+direction*2400*math.cos(theta),y=origin.y+2400*math.sin(theta)})
      if terrain or not hit or hit.enemy or hit.part~='head'then return false end
     end
     return true
    end)
    row.releasedAngle=b.mentorAim.angle;row.precision=b.mentorAim.precision;row.heldSeconds=D.App.runningTime-b.mentorAim.started
    row.poseAtRelease=boss.enemy.playable.current;row.bossFacingAtRelease=boss.enemy.faceRight;row.bossXAtRelease=boss.enemy.x;local origin=b.world:convertToNodeSpace(b.mentor:convertToWorldSpace(D.Vec2.zero));row.mentorWorldAtRelease={x=origin.x,y=origin.y}
    local shown=b.world:convertToNodeSpace(b.mentorAim.line:convertToWorldSpace(D.Vec2.zero));row.shownPreviewOrigin={x=shown.x,y=shown.y}
    assert(b.mentorAim:release());wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
    row.poseAfterShot=boss.enemy.playable.current;row.bossXAfterShot=boss.enemy.x
    row.step=b.bossTrace.steps[first+1];row.hits={};for i=hitCount+1,#b.bossTrace.hits do row.hits[#row.hits+1]=b.bossTrace.hits[i]end
    assert(not row.step.aim and not row.step.aimEmission and row.step.emitted==1 and supplies.emissions==used+1,'Manual shot acquired a locked target')
    local actual=-math.deg(math.atan(row.step.velocity.y,math.abs(row.step.velocity.x)));assert(math.abs(actual-row.releasedAngle)<.02,'Manual shot changed the selected angle')
    row.previewOriginError=math.sqrt((row.step.muzzle.x-row.shownPreviewOrigin.x)^2+(row.step.muzzle.y-row.shownPreviewOrigin.y)^2);assert(row.previewOriginError<6,'Shown preview origin differs from firing pose')
    row.headHit=#row.hits==1 and row.hits[1].part=='head';if not row.headHit then failures=failures+1 end;save()
   end
  end end
  if os.getenv('LSD_QA_MUZZLE_CALIBRATION')=='1' then
   r.diagnosticCollectionOnly=true;r.calibration={}
   local angles={-40,-20,0,20,40}
   if os.getenv('LSD_QA_MUZZLE_CALIBRATION_ANGLES')then
    angles={};for value in os.getenv('LSD_QA_MUZZLE_CALIBRATION_ANGLES'):gmatch('[^,]+')do local angle=assert(tonumber(value));assert(math.abs(angle)<=45);angles[#angles+1]=angle end
    assert(#angles>0 and #angles<=40)
   end
   for _,direction in ipairs({1,-1})do for _,angle in ipairs(angles)do
    wait(function()return b.mentorAim.canStart()and not b.mentorAim.shot end)
    boss.enemy.x=1920;b.mentor.x=1920-direction*1300;b.mentor.faceRight=direction==1;b.mentor.velocityX=0;D.sleep(.1)
    local first=#b.bossTrace.steps;local origin=b.world:convertToNodeSpace(b.mentor:convertToWorldSpace(D.Vec2.zero))
    assert(b.mentorAim:begin());wait(function()return D.App.runningTime-b.mentorAim.started>.15 and math.abs(b.mentorAim.angle-angle)<1.5 end)
    local selected=b.mentorAim.angle;assert(b.mentorAim:release())
    wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
    local step=assert(b.bossTrace.steps[first+1]);assert(step.emitted==1 and not step.aim and not step.aimEmission)
    r.calibration[#r.calibration+1]={direction=direction,selectedAngle=selected,ownerWorld={x=origin.x,y=origin.y},step=step};save()
   end end
  end
  b:finish('aborted','Manual head diagnostic');wait(function()return b.settled end);r.headFailures=failures;if not r.diagnosticCollectionOnly then assert(#r.cases==4,'Geometry matrix incomplete');for _,row in ipairs(r.cases)do assert(row.step and row.hits and #row.hits>0,'A geometry case did not fire or resolve a contact')end;assert(failures==0,animated and 'Manual preview-planned angle missed an animated exposed head'or'Manual preview-planned angle missed a static exposed head')end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
