-- Failure fixtures are explicit; attacks, blocking and defeat still use real native events.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","liyena-outcomes-result.txt"); D.Content:save(out,"LSD_LIYENA_OUTCOMES_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","liyena-coop-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-liyena%-coop%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-liyena-outcomes-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db)); assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local function wait(f,t,label) local deadline=D.App.runningTime+(t or 12); while not f() do assert(D.App.runningTime<deadline,"Outcomes timeout: "..(label or "")); D.sleep(0.02) end end
  local nav=require("Academy.Navigation"); local w=nav.returnToTrainingAsync()
  local function atTerminal() local p; wait(function() p=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==w end); return p and p.unit.onSurface end); p.unit.x=935; D.sleep(0.3) end
  atTerminal(); local c=assert(require("Trial.Level").openAsync(w,true))
  wait(function() return D.Platformer.Data.store.world.storyFlow and D.Platformer.Data.store.world.storyFlow.view.visible end)
  local f=D.Platformer.Data.store.world.storyFlow
  while f.phase=="dialogue" or f.phase=="saving" do if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
  wait(function() local t=D.Platformer.Data.store.world.trialBattle; return t and t.battle.duel and t.hud end)
  c=D.Platformer.Data.store.world.trialBattle; local b=c.battle; c.beginButton:emit("Tapped")
  -- Native timing gate: guard starts after her authored pistol animation begins, before attack.
  wait(function() return b:npcBusy() and b.activeCasts[b.npc] and D.App.runningTime-b.activeCasts[b.npc].startedAt<0.15 end,15,"NPC aim")
  local hp=b.heroHP; c.guard:emit("TapBegan"); wait(function() return b.blocks>0 end,3,"physical shot guard")
  assert(b.heroHP==hp and b.hero.playable.current=="parry")
  wait(function() return not b:heroBusy() end,3)
  local guard=b.activeCasts[b.hero]; assert(guard.skill=="parry" and guard.completedAt and not guard.releaseAt and guard.completedAt-guard.startedAt>=guard.duration-0.06)
  assert(b.hero.playable.current=="prepare" and math.abs(b.hero.playable.recovery-0.2)<0.001)
  -- Real joystick approach to melee range, no injected damage.
  local deadline=D.App.runningTime+10
  while math.abs(b.npc.x-b.hero.x)>180 do assert(D.App.runningTime<deadline,"Melee approach stalled"); c.hud.move.onMove(b.npc.x>b.hero.x and "keyRight" or "keyLeft",true); D.sleep(0.03) end
  c.hud.move.onMove("keyRight",false); c.hud.move.onMove("keyLeft",false); wait(function() return not b:heroBusy() and b.hero.onSurface end)
  hp=b.npcHP; c.melee:emit("TapBegan"); wait(function() return b.npcHP<hp end,3,"melee event")
  local melee=b.activeCasts[b.hero]; assert(melee.skill=="melee" and melee.releaseAt); wait(function() return melee.completedAt end,3,"melee completion")
  assert(melee.completedAt-melee.startedAt>=melee.duration-0.06)
  -- Explicit low-health failure fixture; actual opposing authored melee/pistol must defeat it.
  b.heroHP=1; wait(function() return c.result end,8,"hero defeat")
  assert(b.phase=="failed" and b.heroHP==0 and b.hero.playable.current=="lose")
  local service=assert(require("Mission.Service").open()); assert(not service:summary().unlocks["liyena-duel-complete"])
  c.result.baseButton:emit("Tapped"); wait(function() return D.Platformer.Data.store.world.tag=="TrainingRoom" end)
  w=D.Platformer.Data.store.world; atTerminal(); c=assert(require("Trial.Level").openAsync(w,false)); b=c.battle; c.beginButton:emit("Tapped")
  -- Isolate a real enemy attack on the cooperating NPC; no synthetic result commit.
  wait(function() return b.npc.onSurface end); b.npcHP=1; b.nextNpc=D.App.runningTime+20
  local e=b.enemies[1]; e.enemy.x=b.npc.x+180; e.enemy.velocityX=0; e.nextEnemy=D.App.runningTime
  wait(function() return c.result end,10,"partner defeat")
  assert(b.phase=="failed" and b.npcHP==0 and b.npc.playable.current=="lose")
  c.result.baseButton:emit("Tapped"); wait(function() return D.Platformer.Data.store.world.tag=="TrainingRoom" end)
  w=D.Platformer.Data.store.world; atTerminal(); c=assert(require("Trial.Level").openAsync(w,true)); c.withdraw:emit("Tapped"); wait(function() return c.result end)
  assert(c.battle.phase=="aborted" and not service:summary().unlocks["liyena-duel-complete"])
  assert(not require("Story.Service").open():summary().completed["liyena-recognition"])
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  c.result.baseButton:emit("Tapped"); wait(function() return D.Platformer.Data.store.world.tag=="TrainingRoom" end)
  return "PASS nativeGuardBlocksProjectile=true noGuardAttackEvent=true fullGuardRecovery=true joystickMelee=true authoredMeleeEvent=true fullMelee=true actualHeroDefeat=true actualPartnerDefeat=true publicWithdraw=true noDuelRewardOnFailure=true noRecognition=true noActiveAttempt=true explicitLowHealthFailureFixture=true"
 end,debug.traceback)
 local report="LSD_LIYENA_OUTCOMES_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
