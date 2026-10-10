-- Real saved medicine and production Pursuit HUD; controlled health/frozen
-- update, fake completion service, simulated lifecycle; not formal gameplay.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/pursuit-input-availability-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load('/private/tmp/lsd-report-snapshot-full-journey-20261009/fresh-recovery-current/result.json')),32)
  assert(prior.status=='PASS'and prior.sameJourney)
  local function wait(fn)local deadline=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<deadline,'Pursuit input fixture timeout');D.sleep(.02)end end
  for _,variant in ipairs({'before','after'})do
   local db=D.Path(D.Content.writablePath,'pursuit-input-'..variant..'.db');assert(D.Content:copyAsync(prior.database,db))
   assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
   local S=require('Story.Supplies');assert(S.count('mentor','first-aid-water')==1)
   local module
   if variant=='before'then local path='/private/tmp/lsd-pursuit-input-before-20261009/PursuitLevel.lua';module=assert(load(assert(D.Content:load(path)),'@'..path))()
   else module=require('Ruins.PursuitLevel')end
   local c=module.openAsync({finishAsync=function()return true end},{mission='c0-m06'});local b=c.battle;b.update=function()return false end
   local ui=c.controls or c.statusLabel.parent;local hud=c.hud or D.Director.ui3D:getChildByTag('pursuit-hud')
   local row={variant=variant,database=db,parentDatabase=prior.database,inactive={}};r.cases[#r.cases+1]=row
   local requests={};local command=b.command
   b.command=function(self,name)if name~='idle'then requests[#requests+1]=name end;return command(self,name)end
   local function inputs()
    for _,key in ipairs({'E','L','H'})do ui:emit('KeyDown',key);ui:emit('KeyUp',key)end
    for _,name in ipairs({'smoke','flare','medicine'})do c.toolButtons[name]:emit('TapBegan')end
   end
   local function probe(name,setup,restore)
    b.mentorHP=75;local stock=S.count('mentor','first-aid-water');setup();local before=#requests;inputs();wait(function()return not b.medicineBusy end);D.sleep(.12)
    local item={name=name,requests=#requests-before,stockBefore=stock,stockAfter=S.count('mentor','first-aid-water'),health=b.mentorHP};row.inactive[#row.inactive+1]=item;save()
    assert(item.requests==(variant=='before'and 6 or 0),'Inactive keyboard/touch skills mismatch')
    if variant=='after'then assert(item.stockAfter==stock and item.health==75,'Inactive input consumed medicine or healed')end
    restore();before=#requests;D.sleep(.1);assert(#requests==before,'Restore replayed old input')
   end
   probe('focus-lost',function()D.emit('AppEvent','WindowFocusLost')end,function()D.emit('AppEvent','WindowFocusGained')end)
   if variant=='before'then assert(row.inactive[1].stockAfter==0 and row.inactive[1].health==100,'Old medicine bypass not reproduced')end
   probe('hidden-despite-focus',function()D.emit('AppEvent','WindowHidden');D.emit('AppEvent','WindowFocusGained')end,function()D.emit('AppEvent','WindowShown')end)
   probe('background-despite-focus',function()D.emit('AppEvent','WillEnterBackground');D.emit('AppEvent','WindowFocusGained')end,function()D.emit('AppEvent','DidEnterForeground')end)
   probe('controls-hidden',function()ui.visible=false end,function()ui.visible=true end)
   probe('story-hud-hidden',function()D.emit('Story.Display',true)end,function()D.emit('Story.Display',false)end)
   if variant=='after'then
    b.mentorHP=75;ui:emit('KeyDown','H');ui:emit('KeyUp','H');wait(function()return not b.medicineBusy end)
    assert(b.mentorHP==100 and S.count('mentor','first-aid-water')==0);row.freshMedicine=true
   end
   b:finish('aborted','Controlled pursuit input fixture');wait(function()return c.phase=='result'end)
   D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();D.sleep(.3)
   assert(D.DB:exec('DETACH DATABASE lsd')>=0)
  end
  r.scope='Original saved one-unit medicine; native production controls and actual async stock consumption, controlled health/frozen combat update/fake result service, simulated focus/background/hidden events; not actual OS, mission billing or normal victory'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
