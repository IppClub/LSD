-- Controlled lifecycle probe; game controllers/save/HP/wallet are untouched.
local entry=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/ui-loop-lifecycle-result.json'
local r={status='RUNNING',diagnosticOnly=true,osInput=false,cases={},changesGameState=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end
local function refs()collectgarbage('collect');return {objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount}end
local function state(root)
 local values={};local function visit(n)values[#values+1]=string.format('%.2f:%.2f:%.2f',n.x,n.y,n.opacity);if n.children then n.children:each(function(child)visit(child)end)end end;visit(root);return table.concat(values,'|')
end
save();D.thread(function()
 local ok,why=xpcall(function()
  for _,module in ipairs({'UI.View.Story','UI.MovingText','UI.TrainingButton','UI.GearButton','UI.TabButton','UI.LsdOS'})do
   r.stage=module;save();local make=require(module)
   local function create()local v=make({textBG='LOOP LOOP',text='QA',selected=true,equiped=true,locked=false});v._reviews={};v:addTo(D.Director.ui3D);return v end
   local warm=create();D.sleep(.2);local states={}
   for n=1,55 do states[#states+1]={at=n*.211,state=state(warm)};D.sleep(.211)end
   local distinct={};for _,s in ipairs(states)do distinct[s.state]=true end;local count=0;for _ in pairs(distinct)do count=count+1 end
   r.currentMotion={module=module,distinctStates=count,samples=states};save();assert(count>=4,'No sustained loop motion in '..module)
   warm:removeFromParent();warm=nil;D.sleep(.3)
   local case={module=module,motionSamples=#states,distinctStates=count,motion=states,groups={}};r.cases[#r.cases+1]=case
   for _,mode in ipairs({'entered-then-disposed','disposed-before-enter'})do
    local before=refs();local weak=setmetatable({},{__mode='v'})
    for n=1,12 do local v=create();weak[n]=v;if mode=='entered-then-disposed'then D.sleep(.05)end;v:removeFromParent();v=nil;D.sleep(.05)end
    D.sleep(.3);local after=refs();local retained=0;for _ in pairs(weak)do retained=retained+1 end
    case.groups[#case.groups+1]={mode=mode,instances=12,before=before,after=after,retainedViews=retained,growth={objects=after.objects-before.objects,luaRefs=after.luaRefs-before.luaRefs,callRefs=after.callRefs-before.callRefs}};save()
   end
  end
  r.lifecycleClean=true
  for _,case in ipairs(r.cases)do for _,group in ipairs(case.groups)do if group.growth.luaRefs~=0 or group.growth.callRefs~=0 or group.retainedViews~=0 then r.lifecycleClean=false end end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
