-- Production worlds/HUDs with controlled idle models/frozen battle updates.
-- Trial uses an earned isolated checkpoint and the original public terminal.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/remaining-battle-input-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local meta,newindex
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load('/private/tmp/lsd-report-snapshot-full-journey-20261009/fresh-ayan-current/result.json')),32)
  assert(prior.status=='PASS'and prior.sameJourney)
  local db=D.Path(D.Content.writablePath,'remaining-battle-input.db');assert(D.Content:copyAsync(prior.database,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.source=prior.database;r.database=db
  local tracked=setmetatable({},{__mode='k'})
  local function frames(n)local left=n;local node=D.Node();node:addTo(D.Director.ui);node:schedule(function()left=left-1;return left<=0 end);while left>0 do D.sleep(.01)end;node:removeFromParent()end
  local function wait(fn)local deadline=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<deadline,'Input fixture timeout');D.sleep(.02)end end
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  for _,kind in ipairs({'Mission','Factory','Trial'})do
   for _,variant in ipairs({'before','after'})do
    local module
    if variant=='before'then local path='/private/tmp/lsd-remaining-input-before-20261009/'..kind..'.lua';module=assert(load(assert(D.Content:load(path)),'@'..path))()
    else module=require(kind..'.Level')end
    local c
    if kind=='Trial'then
     local world=require('Academy.Navigation').returnToTrainingAsync()
     local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)
     local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end)
     hud.move:emit('Left',true);wait(function()return math.abs(p.unit.x-935)<120 end);hud.move:emit('Left',false);frames(10)
     c=assert(module.openAsync(world,false))
    else c=module.openAsync({}, {mission=kind=='Mission'and'c0-m01'or'c0-m05',model=idle('ninilite'),models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}},kind=='Mission'and'charM'or nil)end
    local b=c.battle;b.update=function()return false end
    if kind=='Trial'then c.beginButton:emit('Tapped')elseif kind=='Factory'then c.start:emit('Tapped')end
    local hud=c.hud or D.Director.ui3D:getChildByTag('mission-hud')
    local status=c.status
    if not status then status=D.Director.ui3D:getChildByTag('mission-controls'):getChildByTag('mission-status')end
    local tags=kind=='Mission'and{'mission-repair'}or kind=='Factory'and{'factory-gather','factory-song'}or{'trial-melee','trial-guard'}
    if not meta then meta=getmetatable(status);newindex=assert(meta.__newindex);meta.__newindex=function(o,k,v)local count=tracked[o];if count and k=='text'then count.writes=count.writes+1 end;return newindex(o,k,v)end end
    local count={writes=0};tracked[status]=count;frames(5);count.writes=0;frames(120)
    local expected=variant=='before'and kind~='Factory'and 120 or 0
    local row={battle=kind,variant=variant,textWrites=count.writes,steadyFrames=120,inactive={}};r.cases[#r.cases+1]=row;save();assert(count.writes==expected,'Unexpected text writes')
    count.writes=0;if kind=='Trial'then b.heroHP=95 else b.mentorHP=95 end;frames(5);row.changedWrites=count.writes
    assert(count.writes==(expected>0 and 5 or 1),'Status did not update once')
    local requests={};local command=b.command
    b.command=function(self,name)if name~='stop'then requests[#requests+1]=name;return true end;return command(self,name)end
    local function inputs()for _,tag in ipairs(tags)do assert(hud.skillArea:getChildByTag(tag)):emit('TapBegan')end end
    local function probe(name,setup,restore)
     setup();local before=#requests;inputs();frames(5);local delta=#requests-before;row.inactive[#row.inactive+1]={name=name,requests=delta};save()
     assert(delta==(variant=='before'and #tags or 0),'Inactive command submitted: '..name)
     restore();before=#requests;frames(5);assert(#requests==before,'Restore replayed input')
    end
    probe('focus-lost',function()D.emit('AppEvent','WindowFocusLost')end,function()D.emit('AppEvent','WindowFocusGained')end)
    probe('hidden-despite-focus',function()D.emit('AppEvent','WindowHidden');D.emit('AppEvent','WindowFocusGained')end,function()D.emit('AppEvent','WindowShown')end)
    probe('background-despite-focus',function()D.emit('AppEvent','WillEnterBackground');D.emit('AppEvent','WindowFocusGained')end,function()D.emit('AppEvent','DidEnterForeground')end)
    probe('controls-hidden',function()status.parent.visible=false end,function()status.parent.visible=true end)
    probe('story-hud-hidden',function()D.emit('Story.Display',true)end,function()D.emit('Story.Display',false)end)
    local before=#requests;inputs();assert(#requests==before+#tags,'Fresh input missing');row.freshInput=true;b.command=command
    if kind=='Trial'then b:finish('aborted','Controlled input fixture');wait(function()return c.phase=='result'end);row.abortedSaved=true end
    tracked[status]=nil;D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();frames(5)
   end
  end
  r.scope='Actual three production controls, simulated lifecycle events; frozen update/idle models, command routing probes suppress skill effects. Trial enters earned public terminal and saves abort. Not gameplay, OS focus, costs or full journey.'
 end,debug.traceback)
 if meta and newindex then meta.__newindex=newindex end
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
