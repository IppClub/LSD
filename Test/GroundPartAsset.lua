local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/ground-part-asset-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local model={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=6,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}
  local b=require('Ground.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m02',model=model})
  local function wait(f)local untilAt=D.App.runningTime+6;while not f()do assert(D.App.runningTime<untilAt,'Ground asset wait');D.sleep(.01)end end
  wait(function()return b.mentor.onSurface end)
  assert(b.arena.enemyPlayable=='dataotie-combat')
  local manifest=D.json.decode(D.Content:load(root..'/Data/Combat/dataotie-regions.json'))
  local regions=require('Combat.SpineRegions').sample(b.arena.enemy.playable,manifest,b.arena.world)
  assert(#regions==7 and #regions[1].vertices>3)
  local first=regions[1].vertices[1];assert(first.x~=0 and first.y~=0)
  local extent=0;for _,v in ipairs(regions[1].vertices)do extent=math.max(extent,math.abs(v.x-first.x)+math.abs(v.y-first.y))end;assert(extent>10,'Collapsed points')
  b.mentor.faceRight=false;assert(b.arena.enemy.x>b.mentor.x)
  assert(b.mentorAim:begin());D.sleep(.3);assert(b.mentorAim:release())
  assert(not b.mentor.faceRight,'Aim was overridden by auto-facing')
  wait(function()return #b.arena.projectiles>0 end)
  local bullet=b.arena.projectiles[#b.arena.projectiles];assert(bullet.velocityX<0)
  r.regions=#regions;r.keptPlayerFacing=true;r.vx=bullet.velocityX
  b:finish('aborted','Native asset integration fixture');wait(function()return b.phase=='aborted' end)
  local step=b.partCombat.journal.steps[1];assert(step and step.truncated and not step.sealed,'Aborted projectile treated as a completed miss');r.interruptedSample=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
