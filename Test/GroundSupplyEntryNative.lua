local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ground-supply-entry-result.json';local r={status='RUNNING',cases={}}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-supply-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-supply%-%d+%.db$'))
  local dest=D.Content.writablePath..'/ground-supply-entry-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  for _,energy in ipairs({false,true})do
   local support=require('Ground.LifeSupport').new(65,'defence');support.hp={100,100,100}
   -- Start near the real terminal; this is entry QA, not a walked story journey.
   require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=energy and 5760 or 2450,energySquad=energy,support=support})
   local world=D.Platformer.Data.store.world;local deadline=D.App.totalTime+15
   local menu=assert(world:getChildByTag(energy and 'energy-terminal' or 'ground-contact'))
   while not menu.visible do assert(D.App.totalTime<deadline);D.sleep(.05)end
   menu:emit('Tapped',energy and 1 or 2)
   local controller=energy and world.energySite or world.groundExpedition
   while not controller.supplyPanel do assert(D.App.totalTime<deadline);D.sleep(.05)end
   local actual=world.groundExpedition.support;local gold=actual.gold
   assert(world.data.storyBusy);D.sleep(.5);assert(actual.gold==gold,'Budget screen drained life support')
   controller.supplyPanel.closeButton:emit('Tapped');D.sleep(.1)
   assert(not world.data.storyBusy and not controller.supplyPanel and not E.active() and E.wallet().available==balance)
   r.cases[#r.cases+1]={mission=energy and 'c0-m03' or 'c0-m02',pauseAndCancel=true}
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
