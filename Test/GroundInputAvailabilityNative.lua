-- Actual Ground/Energy worlds and controls; idle models, frozen battle update,
-- no mission service/bill/save. Simulated lifecycle is not actual OS play.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/ground-input-availability-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,formalCombat=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local meta,newindex
 local ok,why=xpcall(function()
  local configDB=D.Path(D.Content.writablePath,'ground-input-config.db')
  assert(not D.DB:existDB('lsd')and D.DB:exec("ATTACH DATABASE '"..configDB.."' AS lsd")>=0)
  local config=require('Data.Config');config:loadAsync();config.char='charM'
  local tracked=setmetatable({},{__mode='k'})
  local function frames(n)
   local left=n;local node=D.Node();node:addTo(D.Director.ui)
   node:schedule(function()left=left-1;return left<=0 end)
   while left>0 do D.sleep(.01)end;node:removeFromParent()
  end
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  for _,kind in ipairs({'Level','EnergyLevel'})do
   for _,variant in ipairs({'before','after'})do
    local module
    if variant=='before'then local path='/private/tmp/lsd-ground-input-before-20261009/'..kind..'.lua';module=assert(load(assert(D.Content:load(path)),'@'..path))()
    else module=require('Ground.'..kind)end
    local attempt={mission=kind=='Level'and'c0-m02'or'c0-m03',model=idle('ninilite'),models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}}
    local c=module.openAsync({},attempt);local b=c.battle
    b.update=function()return false end -- Hold state steady for input/layout probes.
    local hud=D.Director.ui3D:getChildByTag(kind=='Level'and'ground-battle-hud'or'energy-battle-hud')
    local gather=hud.skillArea:getChildByTag(kind=='Level'and'ground-battle-gather'or'energy-gather')
    local status=c.status
    -- Ground status is nested in its control node.
    if not status then D.Director.ui3D.children:each(function(n)local found=n:getChildByTag('ground-battle-status');if found then status=found end end)end
    assert(status and hud and gather)
    if not meta then meta=getmetatable(status);newindex=assert(meta.__newindex);meta.__newindex=function(o,k,v)local count=tracked[o];if count and k=='text'then count.writes=count.writes+1 end;return newindex(o,k,v)end end
    local count={writes=0};tracked[status]=count;frames(5);count.writes=0;frames(120)
    local row={battle=kind,variant=variant,steadyFrames=120,textWrites=count.writes,inactive={}};r.cases[#r.cases+1]=row;save()
    assert(count.writes==(variant=='before'and 120 or 0),'Unexpected steady label writes')
    b.message='状态变化应即时显示';count.writes=0;frames(5);row.changedWrites=count.writes
    assert(status.text:find(b.message,1,true)and count.writes==(variant=='before'and 5 or 1),'Status transition not reflected')
    local requests={};local command=b.command
    b.command=function(self,name)if name~='stop'then requests[#requests+1]=name end;return command(self,name)end
    local function inputs()
     gather:emit('TapBegan')
     if kind=='EnergyLevel'then hud.skillArea:getChildByTag('energy-fire'):emit('TapBegan');hud.skillArea:getChildByTag('energy-wind'):emit('TapBegan')end
    end
    local function probe(name,setup,restore)
     setup();local before=#requests;inputs();frames(5);local delta=#requests-before
     row.inactive[#row.inactive+1]={name=name,requests=delta};save()
     assert(variant=='before'and delta>0 or variant=='after'and delta==0,'Inactive skill mismatch: '..name)
     restore();before=#requests;frames(5);assert(#requests==before,'Restore replayed old input')
    end
    probe('focus-lost',function()D.emit('AppEvent','WindowFocusLost')end,function()D.emit('AppEvent','WindowFocusGained')end)
    probe('hidden-despite-focus',function()D.emit('AppEvent','WindowHidden');D.emit('AppEvent','WindowFocusGained')end,function()D.emit('AppEvent','WindowShown')end)
    probe('background-despite-focus',function()D.emit('AppEvent','WillEnterBackground');D.emit('AppEvent','WindowFocusGained')end,function()D.emit('AppEvent','DidEnterForeground')end)
    probe('controls-hidden',function()status.parent.visible=false end,function()status.parent.visible=true end)
    probe('story-hud-hidden',function()D.emit('Story.Display',true)end,function()D.emit('Story.Display',false)end)
    local before=#requests;inputs();assert(#requests>before,'Fresh skills unavailable');row.freshSkills=true
    tracked[status]=nil;D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();frames(3)
   end
  end
  r.scope='Actual native Ground and Energy controls, before/after Label setter counts; frozen combat updates and idle fixture models, simulated focus/visibility/background events; no formal costs, mission outcome or actual OS focus claim'
 end,debug.traceback)
 if meta and newindex then meta.__newindex=newindex end
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
