-- Fixture setup followed exclusively by real OS input; observers never emit UI events.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ground-disarm-mouse-result.json';local r={status='RUNNING',stage='setup',keys={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/ground-disarm-mouse-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local support=require('Ground.LifeSupport').new(65,'defence');support.hp={100,100,100}
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4250,energySquad=true,support=support})
  local world=D.Platformer.Data.store.world;local gate=assert(world.disarmGate)
  local observer=D.Node();observer.keyboardEnabled=true;observer:addTo(D.Director.postNode)
  observer:slot('KeyDown',function(key)r.keys[key]=(r.keys[key]or 0)+1 end)
  observer:gslot('AppEvent',function(event)r.lastAppEvent=event end)
  local lastSnapshot=0
  local function wait(fn,seconds)local endAt=D.App.runningTime+(seconds or 240);while not fn()do assert(D.App.runningTime<endAt,'OS route timeout: '..r.stage);if D.App.runningTime-lastSnapshot>=1 then lastSnapshot=D.App.runningTime;local w=D.Platformer.Data.store.world;local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end);r.observation=p and {x=p.unit.x,busy=p.busy==true,left=p.keyLeft==true,right=p.keyRight==true,scene=w.tag,storyBusy=w.data.storyBusy==true,journalOpen=w.data.journalOpen==true}or nil;save()end;D.sleep(.03)end end
  r.stage='walk-to-terminal';save()
  wait(function()return gate.menu.visible end);r.walkedToTerminal=true;r.stage='open-budget';save()
  wait(function()return gate.supplyPanel end);r.stage='confirm-budget';save()
  wait(function()local w=D.Platformer.Data.store.world;return w and w~=world and w.patrolLevel end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle;r.stage='start-battle';save()
  wait(function()return b.phase=='playing'end);r.stage='fight';save()
  wait(function()return c.phase=='result'or c.phase=='save-error'end,120);assert(c.phase=='result',c.error);assert(b.phase=='won',b.reason)
  r.bill=b.report.economy;r.finalHP={b.mentorHP,b.arena.studentHP,b.wuyun.studentHP};r.stage='continue-investigation';save()
  wait(function()local w=D.Platformer.Data.store.world;return w and w~=b.world and w.tag=='AbandonedCity'and w.groundExpedition end)
  local returned=D.Platformer.Data.store.world;assert(returned.groundExpedition.support==support)
  for i,hp in ipairs(r.finalHP)do assert(math.abs(support.hp[i]-hp)<2,'Return lost party HP')end
  assert(E.wallet().available==balance+r.bill.net and not E.active())
  assert(r.keys.D and r.keys.J,'No observed walking/shooting keyboard input')
  r.supportPreserved=true;r.balance=E.wallet().available;r.stage='complete'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
