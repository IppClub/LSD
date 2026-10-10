-- Normal continue from a real earned save; records OS inputs without generating them.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/native-held-input-observation-result.json'
local directory=assert(os.getenv('LSD_QA_OS_OBSERVATION_DIRECTORY'))
assert(directory:match('^/private/tmp/lsd%-os%-held%-input%-'))
local r={status='RUNNING',osInput=true,titleInput='engine button event',movementInput='awaiting actual macOS keyboard events',samples={},events={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/lsd%-fresh%-opening%-academy%-qa%-%d+/lsd%-journey%-%d+%-%d+%.db$'))
  local dest=D.Content.writablePath..'/native-input-journey-'..os.time();assert(D.Content:mkdir(dest))
  local name=D.Path:getFilename(prior.database);r.database=dest..'/'..name;r.source=prior.database
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,r.database))
  local title=require('Save.Title').open({store=require('Save.Slots').new(dest)});assert(title.continue);title.continue:emit('Tapped')
  local deadline=D.App.runningTime+120
  local function player()
   local w=D.Platformer.Data.store.world
   if not w or w.tag~='PreparationRoom'or not w.data.navigationAttached then return nil end
   return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
  end
  while not player()or player().busy do assert(D.App.runningTime<deadline,'Normal continue did not reach ready academy');D.sleep(.03)end
  local p=player();r.initialX=p.unit.x;r.scene=p.unit.world.tag
  local node=D.Node();node.keyboardEnabled=true;node:addTo(D.Director.ui3D)
  for _,event in ipairs({'KeyDown','KeyUp'})do node:slot(event,function(key)
   if p.unit and (key=='A'or key=='D')then r.events[#r.events+1]={event=event,key=key,at=D.App.runningTime,x=p.unit.x}end
  end)end
  node:gslot('AppEvent',function(event)if p.unit then r.events[#r.events+1]={event='AppEvent',value=event,at=D.App.runningTime,x=p.unit.x}end end)
  r.stage='READY_FOR_OS_INPUT';save();assert(D.Content:save(directory..'/ready.json',D.json.encode({status='READY',initialX=p.unit.x,scene=r.scene},false,true)))
  deadline=D.App.runningTime+60
  while not D.Content:exist(directory..'/done.json')do
   assert(D.App.runningTime<deadline,'OS input driver did not complete')
   r.samples[#r.samples+1]={at=D.App.runningTime,x=p.unit.x,left=p.keyLeft,right=p.keyRight,keyA=D.Keyboard:isKeyPressed('A'),keyD=D.Keyboard:isKeyPressed('D'),velocityX=p.unit.velocityX,clip=p.unit.playable.current,busy=p.busy}
   D.sleep(.02)
  end
  D.sleep(.5);r.finalX=p.unit.x
  r.samples[#r.samples+1]={at=D.App.runningTime,x=p.unit.x,left=p.keyLeft,right=p.keyRight,keyA=D.Keyboard:isKeyPressed('A'),keyD=D.Keyboard:isKeyPressed('D'),velocityX=p.unit.velocityX,clip=p.unit.playable.current,busy=p.busy}
  local events={};for _,e in ipairs(r.events)do if e.key then events[#events+1]=e end end
  local function interval(key)
   local down,up
   for _,e in ipairs(events)do if e.key==key then if e.event=='KeyDown'and not down then down=e elseif e.event=='KeyUp'and down then up=e;break end end end
   assert(down and up and up.at-down.at>=1.5,'No sustained OS interval: '..key)
   return down,up
  end
  local downD,upD=interval('D');local downA,upA=interval('A')
  assert(upD.x-downD.x>200 and downA.x-upA.x>200,'Real OS holds did not move both directions')
  assert(math.abs(r.finalX-upA.x)<10 and not p.keyLeft and not p.keyRight,'Release did not stop movement')
  r.rightDistance=upD.x-downD.x;r.leftDistance=downA.x-upA.x;r.releaseStops=true;r.sustainedOSMovementVerified=true
  r.balance=require('Economy.Store').wallet().available;assert(r.balance==prior.balance)
  D.App:saveScreenshot(directory..'/after-input.tga');D.sleep(.25)
  node:removeFromParent()
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
