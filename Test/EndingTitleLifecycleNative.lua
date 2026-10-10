-- Isolated legal completed-save lifecycle observation, not a gameplay soak.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/ending-title-lifecycle-result.json'
local r={status='RUNNING',diagnosticOnly=true,osInput=false,cases={},injectsProgress=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
local function counts()return {objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount}end
local function settled()collectgarbage('collect');D.sleep(.7);collectgarbage('collect')end
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(prior.status=='PASS' and prior.sameJourney)
  local name='lsd-journey-'..os.time()..'-1.db';local path=D.Path(D.Content.writablePath,name)
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  r.database=path;r.source=prior.database
  assert(require('Economy.Store').open());assert(not require('Economy.Store').active())
  assert(require('Save.Selection').write(D.Content.writablePath,name))
  for _,module in ipairs({'Ending.Hub','Save.Title'})do
   local M=require(module);local case={module=module,instances={}};r.cases[#r.cases+1]=case
   local function make()if module=='Ending.Hub'then return assert(M.openAsync('title'))else return M.open({store=require('Save.Slots').new(D.Content.writablePath)})end end
   for n=1,3 do
    local c=make();local weak=setmetatable({node=c.node,label=c.label},{__mode='v'})
    assert(M.current==c and c.node.parent);D.sleep(.1)
    local detail={text=c.label.text,characters=c.label.characterCount,batched=c.label.batched,rootTag=c.node.tag}
    local before=counts();c.node:removeFromParent();c=nil;settled()
    detail.currentRetained=M.current~=nil;detail.rootRetained=weak.node~=nil;detail.labelRetained=weak.label~=nil;detail.before=before;detail.after=counts()
    case.instances[#case.instances+1]=detail;save()
   end
   local older=make();local newer=make()
   older.node:removeFromParent();older=nil;settled();case.replacementCurrentPreserved=M.current==newer
   newer.node:removeFromParent();newer=nil;settled();case.replacementCurrentReleased=M.current==nil;save()
  end
  assert(D.DB:exec('DETACH DATABASE lsd')>=0)
  r.lifecycleClean=true
  for _,case in ipairs(r.cases)do if not case.replacementCurrentPreserved or not case.replacementCurrentReleased then r.lifecycleClean=false end;for _,item in ipairs(case.instances)do if item.currentRetained or item.rootRetained or item.labelRetained then r.lifecycleClean=false end end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
