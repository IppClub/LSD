-- Controlled native geometry/manual HUD release. Not a formal Boss victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/boss-manual-head-reachability-result.json'
local r={status='RUNNING',osInput=false,controlledPose=true,virtualSupplies=true,cases={},shots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local supply=assert(require('Economy.CombatSession').virtual('manual-head-geometry',{{actor='mentor',item='kinetic',quantity=8}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supply,{virtual=true})
  local c=require('Factory.PatrolLevel').openAsync(models,function()return true end,{battleFactory=function()return b end})
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 8);while not fn()do assert(D.App.runningTime<deadline,'Manual head probe timeout');D.sleep(.01)end end
  c.start:emit('Tapped');wait(function()return b.phase=='playing'and b.mentor.onSurface end)
  local boss=b.enemies[1];boss.guard.nextAttack=math.huge;D.sleep(.5);boss.enemy.playable.speed=0
  r.originalScale={x=boss.enemy.playable.scaleX,y=boss.enemy.playable.scaleY};r.bossX=boss.enemy.x
  local M=require('Combat.Muzzle');local travel=require('Combat.FirearmRules').travel
  for _,side in ipairs({-1,1})do
   boss.enemy.faceRight=side>0
   for _,distance in ipairs({400,600,920,1200})do
    b.mentor:stop();b.mentor.velocity=D.Vec2.zero;b.mentor.x=boss.enemy.x+side*distance;b.mentor.faceRight=side<0;D.sleep(.1)
    local row={side=side,distance=distance,mentorX=b.mentor.x,angles={}}
    for angle=-45,45 do
     local from=M.manualPreview(b.world,b.mentor,angle,b.mentor.faceRight);local rad=math.rad(angle)
     local to={x=from.x+(b.mentor.faceRight and 1 or -1)*math.cos(rad)*travel,y=from.y-math.sin(rad)*travel}
     local hit,terrain=b.bossCombat:contact(from,to)
     row.angles[#row.angles+1]={angle=angle,part=hit and hit.part or nil,terrain=terrain==true}
    end
    r.cases[#r.cases+1]=row;save()
    if distance==920 then
     local head={};for _,v in ipairs(row.angles)do if v.part=='head'and not v.terrain then head[#head+1]=v.angle end end
     assert(#head>2,'Head has no usable manual cone at original size')
     local targetAngle=head[math.ceil(#head/2)];wait(function()return not b.mentorAim.shot and b.mentorAim.canStart()end)
     local before=#b.bossTrace.hits;local steps=#b.bossTrace.steps;D.emit('Skill.Began');assert(b.mentorAim.held and b.mentorAim.line.visible)
     wait(function()return b.mentorAim.angle<=targetAngle end,1)
     local releasedAngle=b.mentorAim.angle
     D.emit('Skill.Ended');wait(function()return not b.mentor:isDoing('groundMentorShot')and not b.bossCombat:pendingActor('mentor')end)
     local hit=b.bossTrace.hits[before+1];local shot=b.bossTrace.steps[steps+1]
     r.shots[#r.shots+1]={side=side,desiredAngle=targetAngle,releasedAngle=releasedAngle,hit=hit,step=shot};save()
     assert(hit and hit.source=='mentor'and hit.part=='head'and hit.apBefore==35 and hit.apAfter==35 and hit.healthDamage>0,'Manual HUD release did not contact head')
     assert(shot.origin=='player'and shot.emitted==1 and not shot.aim,'Manual shot used assisted target selection')
    end
   end
  end
  r.emissions=supply.emissions;assert(r.emissions==2 and #r.shots==2)
  b:finish('aborted','Controlled manual head geometry');wait(function()return c.phase=='result'end)
  r.allBodyArmorPreserved=true;r.fullGameComplete=false
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
