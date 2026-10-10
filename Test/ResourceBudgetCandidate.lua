local _,capture=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-budget-candidate-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-hud-performance-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync())
  local support=require('Ground.LifeSupport').new(45,'defence');support.hp={100,100,100}
  local Economy=require('Economy.Store');assert(Economy.open())
  assert(D.DB:exec('UPDATE lsd.Game0SupplyWallet SET available=300 WHERE id=1')>=0)
  local _,loadout=require('Economy.Loadout').quote(assert(require('Economy.Loadout').load()),{mentor=true,learner='ninilite',wuyun=true})
  assert(Economy.beginAsync('combat-pressure',loadout,100))
  local c=require('Factory.Level').openAsync({finishAsync=function(_,_,status,report)local bill=assert(Economy.settleAsync('combat-pressure',status));report.economy=bill;return true end},{mission='c0-m05',models=saved.source.baseModels,supplyAttempt='combat-pressure'},support);local b=c.battle
  assert(b.supplies and b.arena.supplies==b.supplies and b.wuyun.supplies==b.supplies)
  local Q=require('Training.ResourceQ');local candidate=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-q-verified-candidate/candidate.json'),32)
  local trial
  trial=require('Training.ResourceTrial').attach(b,candidate.models,saved.source.baseModels)
local frames={};local hudSeconds,hudMax,hudCalls=0,0,0;local update=c.updateUI
  c.updateUI=function(...)local at=D.App.elapsedTime;local value=update(...);local dt=D.App.elapsedTime-at;hudSeconds=hudSeconds+dt;hudMax=math.max(hudMax,dt);hudCalls=hudCalls+1;return value end
  D.sleep(1);assert(b:start());c.start.visible=false;c.phase='playing'
  local start=D.App.totalTime;local shots,holds,previews=0,0,0;local releasedAt=0
  local monitor=D.Node();monitor:addTo(b.arena.world);monitor:schedule(function(dt)if b.phase=='playing' and D.App.totalTime-start>2 then frames[#frames+1]=dt end;return false end)
  -- Screenshots are opt-in; disk/GPU readback must not contaminate timing.
  local photographed=capture~='screenshot'
  while b.phase=='playing' and D.App.totalTime-start<65 do
   if b.mentorAim.held then
    assert(b.mentorAim.line.visible);previews=previews+1
    if D.App.totalTime>=releasedAt then if b.mentorAim:release()then shots=shots+1 end end
   elseif b.mentorAim:begin()then holds=holds+1;releasedAt=D.App.totalTime+(holds%3==0 and .3 or .06)end
   for _,state in pairs(b.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then b:command('song');break end end
   if not photographed and D.App.totalTime-start>8 then photographed=true;D.App:saveScreenshot(root..'/Test/combat-hud-performance.tga')end
   D.sleep(.02)
  end
  r.emissions=b.supplies.emissions;r.maxCommitMs=b.supplies.maxCommitSeconds*1000
  local ledger=assert(Economy.load('combat-pressure'));r.used=ledger.stock;assert(ledger.stock['mentor:kinetic'].used>0 and ledger.stock['ninilite:emp'].used>0 and ledger.stock['wuyun:blade'].used>0)
  r.naturalStatus=b.phase;r.seconds=D.App.totalTime-start;r.shots=shots;r.holds=holds;r.previewFrames=previews;r.mentorHits=b.mentorHits
  assert(shots>=3 and previews>0 and b.mentorHits>0,'Manual aim path did not exercise real fire/contact')
  if b.phase=='playing'then b:finish('aborted','HUD performance sampling complete')end
  table.sort(frames);local sum,slow=0,0;for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end
  local deadline=D.App.runningTime+5;while b.phase=='saving'do assert(D.App.runningTime<deadline);D.sleep(.01)end
  assert(b.phase~='save-error');r.finalStatus=b.phase;r.bill=assert(Economy.load('combat-pressure')).result;r.decisions={}
  if trial then for actor,entry in pairs(trial)do
   r.decisions[actor]=entry.decisions;assert(entry.decisions.explored==0)
   assert(require('Training.FlowerIdentity').equal(entry.executor:snapshot(),candidate.models[actor]),'Frozen candidate changed')
  end end
  r.performance={frames=#frames,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow,hud={seconds=hudSeconds,max=hudMax,calls=hudCalls}}

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
