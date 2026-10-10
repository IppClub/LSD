-- Native full-rate combat profile. Uses an isolated QA database only.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local _,duration,persist=...;duration=tonumber(duration) or 20
local out=root..'/Test/battle-frame-cost-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db'
  local dest=D.Content.writablePath..'/battle-frame-cost-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(source,dest))
  assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local timings={};local recent={};local slowFrames={};local clockError=false
  local function wrap(m,key,name)
   local f=m[key];local t={calls=0,seconds=0,max=0};timings[name]=t
   m[key]=function(...)local start=D.App.elapsedTime;local a,b=f(...);local dt=D.App.elapsedTime-start;t.calls=t.calls+1;t.seconds=t.seconds+dt;t.max=math.max(t.max,dt)
    if dt>.001 or name=='seed' or name=='settlement' then
     recent[#recent+1]={name=name,at=D.App.runningTime,simulation=D.App.totalTime,seconds=dt}
     if #recent>32 then table.remove(recent,1)end
    end
    return a,b end
  end
  local v=require('Ground.SupportView');local create=v.create
  v.create=function(...)local view=create(...);wrap(view,'update','support');return view end
  wrap(require('Combat.SpineRegions'),'sample','geometry')
  wrap(require('Factory.Battle'),'update','battle')
  wrap(require('Factory.Battle'),'finish','settlement')
  wrap(require('Factory.FlowerCombat'),'seed','seed')
  wrap(require('Factory.FlowerCombat'),'impact','enemy-impact')
  wrap(require('Combat.StatusView'),'hit','hit-feedback')
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  D.App.winSize=D.Size(960,540)
  local service={finishAsync=function()return true end}
  local attempt={mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}}
  if persist then
   require('Data.Config'):loadAsync()
   service=assert(require('Mission.Service').open())
   local progress=require('Training.Progress');local wu=progress.forCharacter('wuyun')
   assert(progress.load() and wu.load(),'Missing adopted QA models')
   attempt=assert(service:beginAsync('c0-m05',{ninilite=progress.adopted,wuyun=wu.adopted},assert(service:formation())))
   local finish=service.finishAsync
   service.finishAsync=function(self,...)
    local began=D.App.runningTime;local ok,why=finish(self,...)
    r.save=r.save or {seconds=D.App.runningTime-began,ok=ok,reason=why,attempt=attempt.id};return ok,why
   end
  end
  local c=require('Factory.Level').openAsync(service,attempt)
  wrap(c,'updateUI','battle-ui')
  local b=c.battle;D.sleep(1);c.start:emit('Tapped')
  local frames,wallFrames,slices={},{},{};local probe=D.Node();probe:addTo(b.arena.world)
  local start=D.App.totalTime;local lastWall=D.App.runningTime
  probe:schedule(function(dt)
   local wall=D.App.runningTime;local actual=wall-lastWall;lastWall=wall
   if actual<0 then clockError=true end
   if b.phase=='playing' then
    frames[#frames+1]=dt;wallFrames[#wallFrames+1]=actual
    if actual>1/30 then
     local events={};for _,e in ipairs(recent)do if wall-e.at<.1 then events[#events+1]=e end end
     slowFrames[#slowFrames+1]={at=D.App.totalTime-start,wall=actual,dt=dt,events=events,enemies=#b.enemies,summons=b.summonsCreated or 0,phase=b.roots[3].enemyCombat.bossPhase,luaKB=collectgarbage('count')}
    end
    local index=math.floor((D.App.totalTime-start)/10)+1
    local s=slices[index]
    if not s then s={start=(index-1)*10,frames=0,max=0,wallMax=0,over33ms=0,wallOver33ms=0,peakEnemies=0,peakLuaKB=0};slices[index]=s end
    s.frames=s.frames+1;s.max=math.max(s.max,dt);s.wallMax=math.max(s.wallMax,actual)
    if dt>1/30 then s.over33ms=s.over33ms+1 end;if actual>1/30 then s.wallOver33ms=s.wallOver33ms+1 end
    s.peakEnemies=math.max(s.peakEnemies,#b.enemies);s.bossPhase=b.roots[3].enemyCombat.bossPhase
   end
   return false
  end)
  local nextMemory=start
  while b.phase=='playing' and D.App.totalTime-start<duration do
   b:command('shoot');if b.effects.confusions>0 then b:command('song')end
   if D.App.totalTime>=nextMemory then
    nextMemory=D.App.totalTime+1;local s=slices[#slices];if s then s.peakLuaKB=math.max(s.peakLuaKB,collectgarbage('count'))end
   end
   D.sleep(.1)
  end
  assert(not clockError,'Wall clock moved backward; discard this profile')
  r.slowFrames=slowFrames;r.recentEvents=recent
  r.slices=slices;r.summons=b.summonsCreated or 0;r.bossPhase=b.roots[3].enemyCombat.bossPhase
  r.naturalEnd=b.phase~='playing';r.requestedSeconds=duration
  if r.naturalEnd then
   local deadline=D.App.totalTime+10;local began=D.App.runningTime
   while b.phase=='saving' or not c.result do assert(D.App.totalTime<deadline and b.phase~='save-error','Settlement stalled or failed');D.sleep(.01)end
   r.resultWait=D.App.runningTime-began
  end
  if persist then
   assert(r.save and r.save.ok,'Real mission save failed')
   local stored=assert(require('Training.CombatStore').load(attempt.id))
   local savedReport=D.DB:query('SELECT status,report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt.id})[1]
   assert(savedReport[1]==b.phase and #stored.steps==#b.combatEpisode.steps)
   assert(require('Training.FlowerIdentity').equal(stored,D.json.decode(D.json.encode(b.combatEpisode),32)),'Stored episode differs')
   assert(require('Training.FlowerIdentity').equal(D.json.decode(savedReport[2],32),D.json.decode(D.json.encode(b.report),32)),'Stored report differs')
   local again,why=service:finishAsync(attempt,b.phase,b.report,b.combatEpisode)
   assert(again and why=='ALREADY_COMMITTED')
   assert(#D.DB:query('SELECT attempt FROM lsd.Game0CombatEpisodes WHERE attempt=?',{attempt.id})==1)
   r.persistence={steps=#stored.steps,readback=true,idempotent=true,status=b.phase}
  end
  table.sort(wallFrames);local wallSum,wallSlow=0,0;for _,dt in ipairs(wallFrames)do wallSum=wallSum+dt;if dt>1/30 then wallSlow=wallSlow+1 end end
  assert(wallSum>=(D.App.totalTime-start)*.8,'Invalid wall frame clock')
  r.wall={clock='App.runningTime',mean=wallSum/#wallFrames,p99=wallFrames[math.ceil(#wallFrames*.99)],max=wallFrames[#wallFrames],over33ms=wallSlow}
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/battle-frame-optimized.tga');D.sleep(.1)
  r.seconds=D.App.totalTime-start;r.hits=#b.partCombat.events;r.phase=b.phase
  table.sort(frames);local sum,slow=0,0;for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end
  r.frames=#frames;r.mean=sum/#frames;r.p99=frames[math.ceil(#frames*.99)];r.max=frames[#frames];r.over33ms=slow;r.timings=timings
  assert(r.hits>0 and r.frames>200,'No sustained combat')
  if duration>=130 then assert(r.naturalEnd and (b.phase=='won' or b.phase=='failed'),'Full battle did not finish naturally')end
  if b.phase=='playing'then b:finish('aborted','性能采样结束')end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
