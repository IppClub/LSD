-- Explicit outcome fixtures: prepared abort and actual low-life defeat, no fake win.
local script,fixture=...
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(script))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","factory-outcomes-result.txt"); D.Content:save(out,"LSD_FACTORY_OUTCOMES_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=fixture or assert(D.Content:load(D.Path(root,"Test","factory-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-factory%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-factory-outcomes-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local service=assert(require("Mission.Service").open()); local progress=require("Training.Progress"); local wp=progress.forCharacter("wuyun")
  local models={ninilite=progress.load() and progress.adopted,wuyun=wp.load() and wp.adopted}; local formation=assert(service:formation())
  local function wait(f,t) local deadline=D.App.runningTime+(t or 10); while not f() do assert(D.App.runningTime<deadline,"Factory outcomes wait"); D.sleep(0.05) end end
  local prior=#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='factory-site-secured'")
  local function open() local attempt=assert(service:beginAsync("c0-m05",models,formation)); return require("Factory.Level").openAsync(service,attempt) end
  local function friendlyRecord(b,expected,actor,amount)
   actor=actor or 'mentor';amount=amount or 15
   local episode=assert(require('Training.CombatStore').load(b.attempt.id))
   assert(episode.versions.contactScope=='all-projectile' and episode.versions.weaponRules==2)
   assert(episode.versions.vitals==1 and require('Training.CombatVitals').validate(episode.vitals))
   local count,total=0,0
   for _,step in ipairs(episode.steps)do
    local hp=0
    for _,hit in ipairs(step.hits)do
     if hit.relation=='friendly' then
      assert(hit.source==step.action.actor and hit.source==actor and hit.target=='wuyun')
      assert(hit.cause=='virus' and hit.healthDamage==amount and not hit.credit)
      count=count+1;total=total+hit.healthDamage
     else hp=hp+hit.healthDamage end
    end
    assert(step.totals.healthDamage==hp,'Friendly damage earned hostile credit')
   end
   assert(count==expected and total==amount*expected,'Wrong saved friendly outcomes')
  end
  local c=open(); local b=c.battle; local hp=require("Factory.Health").load()
  D.sleep(2); assert(b.phase=="ready" and not b.started and b.mentorHP==hp[1] and b.arena.studentHP==hp[2] and b.wuyun.studentHP==hp[3])
  local camera=b.arena.world.camera; local half=D.View.size.width/(2*camera.zoom)
  for _,unit in ipairs({b.mentor,b.arena.student,b.wuyun.student,b.roots[1].enemy,b.roots[2].enemy,b.roots[3].enemy}) do assert(math.abs(unit.x-camera.position.x)+130<half,"Factory ready camera clipped actor") end
  c.withdraw:emit("Tapped"); wait(function() return b.phase=="aborted" and c.result end)
  assert(b.report.seconds==0 and b.report.mentorHits==0 and b.report.learners.ninilite.hits==0 and b.report.learners.wuyun.hits==0)
  assert(D.DB:query("SELECT status FROM lsd.Game0MissionAttempts WHERE id=?",{b.attempt.id})[1][1]=="aborted")
  c=open(); b=c.battle; b.arena.studentHP=1; c.start:emit("Tapped"); wait(function() return b.phase=="failed" and c.result end)
  local fallen=require('Training.FlowerFeatures').capture(b,b.arena.student,b.partCombat.known);assert(fallen.featureSchemaVersion==6 and fallen.health=='fallen')
  assert(b.arena.studentHP==0 and b.injury and b.report.confusions>0,"Low-life fixture was not defeated by real vines")
  assert(b.arena.student.playable.current=="lose" or b.arena.student.data.combatCompletedName=="lose","Defeated learner did not play authored defeat")
  assert(D.DB:query("SELECT status FROM lsd.Game0MissionAttempts WHERE id=?",{b.attempt.id})[1][1]=="failed")
  -- Isolate the mentor's optional equipment adapter with an explicit virus fixture.
  c=open(); b=c.battle; c.start:emit("Tapped")
  local target
  for _,record in ipairs(b.targets()) do if record.unit==b.mentor then target=record end end
  assert(b.effects:apply(target,"virus",4,{kind="QA-virus-adapter"}))
  local before=b.wuyun.studentHP
  assert(b:command("shoot"))
  wait(function() return (b.friendlyHits or 0)>0 end,3)
  assert(b.wuyun.studentHP==before-15,"Mentor virus did not redirect real projectile damage")
  c.withdraw:emit("Tapped"); wait(function() return b.phase=="aborted" and c.result end)
  friendlyRecord(b,1)
  -- Close-range muzzle regression, mirrored, with real terrain interception.
  for _,case in ipairs({{side=1,wall=false},{side=-1,wall=false},{side=1,wall=true},{side=-1,wall=true}})do
   c=open();b=c.battle;c.start:emit("Tapped")
   for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
   for _,e in ipairs(b.roots)do e.enemyCombat:close()end
   b.wuyun.student.x=b.mentor.x+case.side*(case.wall and 200 or 110)
   b.arena.student.x=b.mentor.x-case.side*300
   local wall
   if case.wall then
    local def=D.BodyDef();def.type="Static";def:attachPolygon(10,200,1,0,0)
    wall=D.Body(def,b.arena.world,D.Vec2(b.mentor.x+case.side*75,b.mentor.y+60))
    wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.arena.world)
   end
   D.sleep(.1)
   for _,record in ipairs(b.targets())do if record.unit==b.mentor then target=record end end
   assert(b.effects:apply(target,"virus",4,{kind="QA-close-virus"}))
   local hp=b.wuyun.studentHP
   assert(b:command("shoot"))
   if case.wall then D.sleep(1.5);assert((b.friendlyHits or 0)==0 and b.wuyun.studentHP==hp,"Virus shot crossed terrain "..D.json.encode({hits=b.friendlyHits,hp=b.wuyun.studentHP,before=hp,mentor=b.mentor.x,ally=b.wuyun.student.x,wall=wall.x}))
   else wait(function()return (b.friendlyHits or 0)>0 end,3);assert(b.wuyun.studentHP==hp-15,"Close mirrored virus shot missed")end
   if wall then wall:removeFromParent()end
   c.withdraw:emit("Tapped");wait(function()return b.phase=="aborted" and c.result end)
   friendlyRecord(b,case.wall and 0 or 1)
  end
  -- Learner virus uses its actual laser action and native collision, too.
  c=open();b=c.battle;c.start:emit('Tapped')
  for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  for _,e in ipairs(b.roots)do e.enemyCombat:close();e.enemy.group=D.Platformer.Data.groupHide end
  b.mentor.x=b.arena.student.x-700;b.wuyun.student.x=b.arena.student.x+200
  D.sleep(.2)
  for _,record in ipairs(b.targets())do if record.unit==b.arena.student then target=record end end
  assert(b.effects:apply(target,'virus',4,{kind='QA-learner-virus'}))
  local hp=b.wuyun.studentHP
  wait(function()return b.arena.student.onSurface and not b.arena:isAttacking()end)
  assert(b.arena.student:start(b.arena.physical.laser))
  wait(function()return (b.arena.metrics.friendlyHits or 0)>0 end,3)
  assert(b.wuyun.studentHP==hp,'EMP invented friendly HP damage')
  c.withdraw:emit('Tapped');wait(function()return b.phase=='aborted' and c.result end)
  friendlyRecord(b,1,'ninilite',0)
  -- Withdraw while a redirected projectile is actually in flight. Such shots
  -- deliberately bypass the boss geometry observer and still need cleanup.
  c=open();b=c.battle;c.start:emit('Tapped')
  for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for _,e in ipairs(b.roots)do e.enemy.group=D.Platformer.Data.groupHide;e.enemy.y=e.enemy.y+3000 end -- isolate the live friendly projectile from intervening enemies
  b.arena.student.x=b.mentor.x-600;b.wuyun.student.x=b.mentor.x+500;D.sleep(.1)
  for _,record in ipairs(b.targets())do if record.unit==b.mentor then target=record end end
  assert(b.effects:apply(target,'virus',4,{kind='QA-virus-withdraw'}))
  local hp=b.wuyun.studentHP;local count=#b.arena.projectiles
  assert(b:command('shoot'));wait(function()return #b.arena.projectiles>count end,3)
  local bullet=b.arena.projectiles[#b.arena.projectiles];assert(bullet.parent,'No in-flight virus projectile')
  c.withdraw:emit('Tapped');wait(function()return b.phase=='aborted' and c.result end)
  assert(not bullet.parent and next(b.partCombat.shots)==nil)
  D.sleep(.3);assert(b.wuyun.studentHP==hp and (b.friendlyHits or 0)==0,'Late virus damage after withdrawal')
  friendlyRecord(b,0)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='factory-site-secured'")==prior and #D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  return "PASS earnedWinCopy=true injuryHPPreserved=true sixActorsReadyFramed=true readyNoAI=true publicAbortZeroSeconds=true lowLifeFixture=true realVineDefeat=true authoredDefeatPose=true mentorVirusStatusFixture=true mentorRealFriendlyProjectile=true closeMuzzleBothDirections=true terrainBlocksBothDirections=true inFlightVirusCleanup=true savedFriendlyAttribution=true failureAndAbortCommitted=true noNewRewards=true noActiveResidue=true"
 end,debug.traceback)
 local report="LSD_FACTORY_OUTCOMES_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
