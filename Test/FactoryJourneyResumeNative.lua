-- A new native process resumes a copy of the same completed factory journey.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/factory-journey-resume-result.json';local r={status='RUNNING',osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(root..'/Test/factory-journey-result.json'),32)
  assert(previous.status=='PASS'and previous.sameSave and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/factory%-journey%-%d+%.db$'))
  local db=D.Content.writablePath..'/factory-journey-resume-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=previous.database
  local E=require('Economy.Store');assert(E.open());assert(E.wallet().available==previous.balanceAfter and not E.active())
  local snapshot=D.json.encode(D.DB:query("SELECT id,mission,status,report FROM lsd.Game0MissionAttempts WHERE mission IN ('c0-patrol','c0-researcher','c0-patrol-second','c0-roof') ORDER BY id"),false,true)
  local P=require('Training.Progress');assert(P.load());local wu=P.forCharacter('wuyun');assert(wu.load());local models=D.json.encode({ninilite=P.adopted,wuyun=wu.adopted},false,true)
  local function wait(fn)local deadline=D.App.runningTime+45;while not fn()do assert(D.App.runningTime<deadline,'Factory cold resume stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='OperationRoom'and w.reconnection and w.reconnection.phase=='ready'end)
  local w=D.Platformer.Data.store.world;assert(not w.storyFlow and not w.infiltration and not w.roof)
  local facts=assert(require('Story.Service').open()):summary();assert(facts.completed['roof-aftermath']and not facts.completed['return-online'])
  assert(not require('Story.Availability').canDeploy('wuyun'));assert(not require('Mission.Service').open():formation().wuyun)
  assert(not D.Group({'name','unit'}):find(function(e)return e.name=='wuyun'and e.unit.world==w end))
  assert(require('Story.InfiltrationStore').open():load().active==false)
  assert(E.wallet().available==previous.balanceAfter and not E.active())
  assert(snapshot==D.json.encode(D.DB:query("SELECT id,mission,status,report FROM lsd.Game0MissionAttempts WHERE mission IN ('c0-patrol','c0-researcher','c0-patrol-second','c0-roof') ORDER BY id"),false,true))
  assert(P.load()and wu.load()and models==D.json.encode({ninilite=P.adopted,wuyun=wu.adopted},false,true))
  r.scene=w.tag;r.balance=E.wallet().available;r.noReplay=true;r.wuyunAbsent=true;r.modelsPreserved=true;r.noRepeatedCharges=true;r.chapterThreeEntry=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FACTORY_JOURNEY_RESUME_'..r.status)
end)
