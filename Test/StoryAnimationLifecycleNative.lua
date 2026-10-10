-- External QA: original Story view, real deferred Enter/cleanup, no save or gameplay injection.
local entry=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/story-animation-lifecycle-result.json'
local r={status='RUNNING',osInput=false,changesGameState=false,groups={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end
local function snapshot()
 collectgarbage('collect');local p={objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount,storyCallbacks={}}
 for id,fn in pairs(debug.getregistry()[5])do if type(fn)=='function'then local i=debug.getinfo(fn,'S');if i.source:match('UI/View/Story$')or i.source:match('UI/View/Story.lua$')then p.storyCallbacks[#p.storyCallbacks+1]={ref=id,line=i.linedefined}end end end
 return p
end
save();D.thread(function()
 local ok,why=xpcall(function()
  local make=require('UI.View.Story');local weak=setmetatable({},{__mode='v'})
  -- Warm asset/type caches; this view lives through Enter then receives ordinary cleanup.
  local warm=make({});warm._reviews={};warm:addTo(D.Director.ui3D);D.sleep(.2)
  r.motion={};for n=1,48 do r.motion[#r.motion+1]={at=n*.1,y=warm.continueIcon.y};D.sleep(.1)end
  local low,high=math.huge,-math.huge;for _,v in ipairs(r.motion)do low=math.min(low,v.y);high=math.max(high,v.y)end
  assert(high-low>10 and low>=93 and high<=115,'Original two-second continue-icon loop is not moving within its expected bounds')
  warm:removeFromParent();warm=nil;D.sleep(.3)
  r.baseline=snapshot();save()
  for _,mode in ipairs({'entered-then-disposed','disposed-before-enter'})do
   local before=snapshot()
   for n=1,12 do
    local view=make({});view._reviews={};weak[mode..n]=view;view:addTo(D.Director.ui3D)
    if mode=='entered-then-disposed'then D.sleep(.05)end
    view:removeFromParent();view=nil;D.sleep(.05)
   end
   D.sleep(.3);local after=snapshot();local retained=0;for _ in pairs(weak)do retained=retained+1 end
   r.groups[#r.groups+1]={mode=mode,instances=12,before=before,after=after,retainedViews=retained};save()
  end
  r.referenceGrowth={callRefs=r.groups[2].after.callRefs-r.groups[2].before.callRefs,luaRefs=r.groups[2].after.luaRefs-r.groups[2].before.luaRefs}
  r.status='PASS';r.diagnosticOnly=true;r.leakFree=r.referenceGrowth.callRefs==0 and r.referenceGrowth.luaRefs==0
 end,debug.traceback)
 if not ok then r.status='FAIL';r.error=why end;save()
end)
