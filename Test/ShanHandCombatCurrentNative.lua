local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',cases={},scope='Controlled native original Pursuit skill effects; high-HP observer and manually arranged targets; not formal mission victory',osInput=false,formalMissionAccepted=false};local out=root..'/Test/shan-hand-combat-current-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  D.Cache:loadAsync('spine:xiaoshanxiao');D.Cache:loadAsync('spine:xiaoshanxiao-release')
  local old,new=D.Spine('xiaoshanxiao'),D.Spine('xiaoshanxiao-release')
  for _,name in ipairs(D.Spine:getAnimations('xiaoshanxiao'))do assert(math.abs(old:play(name,false)-new:play(name,false))<1e-6)end;r.durationsUnchanged=true
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline);D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  b.mentorHP=10000;wait(function()return b.mentor.onSurface end)
  local e=b.enemies[2]
  for _,direction in ipairs({1,-1})do for _,index in ipairs({1,4})do
   e.nextAttack=math.huge;e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(7800+direction*400,b.world.offset+155);D.sleep(.2)
   local spec=B.attackSpecs.xiaoshanxiao[index];local hp=b.mentorHP
   assert(b:enemyStrike(e,spec));local strike=e.strikes[#e.strikes]
   wait(function()return not e.busy end);e.nextAttack=math.huge;D.sleep(.7)
   assert(#strike.releases==#spec.at and strike.hits==#spec.at,spec.name..' actual hand shot miss')
   assert(hp-b.mentorHP==spec.damage*#spec.at)
   for i,release in ipairs(strike.releases)do assert(release.hand==(spec.name=='litter' and i==1 and 'rear' or 'front'))end
   r.cases[#r.cases+1]={name=spec.name,direction=direction,hits=strike.hits,releases=strike.releases};save()
  end end
  b:finish('aborted','QA')
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
