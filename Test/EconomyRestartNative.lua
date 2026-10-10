-- Executed in two distinct native processes, with the first killed by the harness.
local entry,phase,savePath,resultPath=...
local D=require('Dora');local r={status='RUNNING',phase=phase}
local function save()assert(D.Content:save(resultPath,D.json.encode(r,false,true)))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  assert(savePath:match('^/private/tmp/lsd%-economy%-restart%-[^/]+/save/restart%.db$'))
  assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..savePath.."' AS lsd")>=0)
  local Service=require('Mission.Service');local service=assert(Service.open());local Store=require('Economy.Store')
  if phase=='prepare' then
   local model={schemaVersion=1,featureSchemaVersion=1,actionSetVersion=1,characterId='ninilite',actions={'laser'},sampleCount=7,trainingAccuracy=1,rules={{conditions={},action='laser'}}}
   local attempt=assert(service:beginAsync('c0-m01',model,{mentor=true,learner='ninilite'},{loadout={{actor='mentor',item='kinetic',quantity=50}},reward=100}))
   assert(Store.consumeAsync(attempt.supplyAttempt,{{id='actual-1',owner='mentor',item='kinetic',count=7,performer='enemy'}}))
   assert(Store.wallet().available==198 and Store.active().spent==16)
   r.status='READY';r.attempt=attempt.id;r.available=198;r.spent=16;save()
   -- The harness terminates this process without engine shutdown/cleanup.
   while true do D.sleep(.1)end
  else
   assert(phase=='recover')
   assert(Store.wallet().available==198 and Store.active().spent==16)
   assert(service:summary().last.status=='active')
   assert(service:recoverAsync());assert(Store.wallet().available==284)
   local last=service:summary().last;assert(last.status=='aborted')
   local report=D.json.decode(last.report,32)
   assert(report.economy.cost==16 and report.economy.income==0 and report.economy.refund==86)
   assert(service:recoverAsync());assert(Store.wallet().available==284)
   assert(#D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')==0)
   r.available=284;r.cost=16;r.refund=86;r.missionStatus=last.status
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save();D.App:shutdown()
end)
