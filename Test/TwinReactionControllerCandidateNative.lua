-- Explicit art/controller fixtures, not earned journey or mission acceptance.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local base='/private/tmp/lsd-twins-full-reaction-candidate-20261007-v8'
local out=root..'/Test/twin-reaction-controller-candidate-result.json'
local r={status='RUNNING',productionInstalled=false,osInput=false,scope='controller fixtures only',cases={},screenshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local Actor=require('Test.TwinReactionActorCandidate')
  local ui=D.Node();ui:addTo(D.Director.ui);local size=D.App.bufferSize
  ui.position=D.Vec2(-size.width/2,-size.height/2)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(size.width,0),D.Vec2(size.width,size.height),D.Vec2(0,size.height)},D.Color(0xff19222e));bg:addTo(ui)
  local defs={{'vika','queued-heavy',false},{'vivi','coalesced-hurt',true},{'vika','fatal-during-fall',true},{'vivi','fatal-during-hurt',false}}
  local actors={};local labels={};local starts={}
  for i,def in ipairs(defs)do
   local name,case,flip=table.unpack(def);local col=(i-1)%2;local row=1-math.floor((i-1)/2)
   local x,y=(col+.5)*size.width/2,110+row*size.height/2
   local spine=base..'/'..name..'/export/'..name..'-reactions.skel|'..root..'/Spine/'..name..'.atlas'
   local actor=Actor.new(name,ui,x,y,spine);actor.model.scaleX=1.6;actor.model.scaleY=1.6;actor.model.fliped=flip
   actors[i]=actor;starts[i]=x;r.cases[i]={name=name,case=case,flip=flip}
   local floor=D.DrawNode();floor:drawSegment(D.Vec2(col*size.width/2,y),D.Vec2((col+1)*size.width/2,y),2,D.Color(0xffe9ecf0));floor:addTo(ui)
   local label=D.Label('SourceHanSansCN-Regular',22);label.position=D.Vec2(x,y-50);label:addTo(ui);labels[i]=label
  end
  D.sleep(.2);local start=D.App.totalTime;local fired={};local screenshots={}
  local tick=D.Node();tick:addTo(ui)
  local function step(dt)
   local time=D.App.totalTime-start
   local function at(key,when,fn)if time>=when and not fired[key]then fired[key]=true;fn()end end
   at('initial',0,function()
    for _,a in ipairs(actors)do assert(a:damage(0)==0 and a.hp==100 and not a:isReacting() and a.state=='idle','Fully absorbed damage triggered a reaction')end
    actors[1]:damage(5);actors[2]:damage(5);actors[3]:damage(25);actors[4]:damage(5)
   end)
   at('fatal',.1,function()actors[3]:damage(75);actors[4]:damage(95)end)
   at('repeat',.15,function()actors[1]:damage(7);actors[2]:damage(1)end)
   at('repeat-again',.2,function()actors[2]:damage(1)end)
   at('heavy',.25,function()actors[1]:damage(18)end)
   for i,a in ipairs(actors)do
    -- A combat caller stops the physical body when a reaction blocks motion.
    local blocked=a:blocksMovement();local old=a.model.x
    a:update(not blocked and time>3.5 and 45 or 0,dt)
    if blocked then assert(math.abs(a.model.x-old)<.001,'Reaction slid the actor')end
    labels[i].text=defs[i][2]..' · '..a.state..' · HP '..a.hp
   end
  end
  tick:schedule(function(dt)
   local stepped,why=xpcall(function()step(dt)end,debug.traceback)
   if not stepped then r.tickError=why;return true end
   return false
  end)
  local runId=tostring(os.time())
  for _,time in ipairs({0,.2,.8,1.1,2,2.8,3.2,5})do
   while D.App.totalTime-start<time do D.sleep(.005)end
   local path=base..'/controller-preview-'..runId..'-'..math.floor(time*100)..'.tga'
   D.App:saveScreenshot(path);r.screenshots[#r.screenshots+1]=path;D.sleep(.02)
  end
  assert(not r.tickError,r.tickError)
  for i,a in ipairs(actors)do
   assert(not a:isReacting(),'Controller reaction never completed: '..defs[i][2])
   local completed={};local started={}
   for _,event in ipairs(a.events)do
    if event.kind=='complete'then
     assert(event.elapsed>=event.duration-.0001,'Incomplete native reaction')
     completed[event.clip]=(completed[event.clip]or 0)+1
    elseif event.kind=='start'then started[event.clip]=(started[event.clip]or 0)+1 end
   end
   r.cases[i].events=a.events;r.cases[i].state=a.state;r.cases[i].hp=a.hp;r.cases[i].completed=completed;r.cases[i].started=started
   if i==1 then assert(a.hp==70 and completed.hurt==1 and completed.fall==1 and completed.standUp==1 and a.state=='fmove','Heavy reaction queue mismatch')
   elseif i==2 then assert(a.hp==93 and completed.hurt==2 and not completed.fall and a.state=='fmove','Repeated hurt restarted or multiplied')
   else assert(a.hp==0 and a.state=='down' and completed.fall==1 and started.fall==1 and not started.standUp and math.abs(a.model.x-starts[i])<.001,'Fatal reaction restarted, moved, or resurrected')end
  end
  tick:unschedule();r.fullDurationAndDeferredTransitions=true;r.visualAcceptancePending=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and tostring(why)or nil;save();print('LSD_TWIN_REACTION_CONTROLLER_CANDIDATE_'..r.status)
end)
