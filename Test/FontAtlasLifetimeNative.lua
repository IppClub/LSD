-- Fixed text/font, isolate retained glyph atlas behavior. External diagnostic.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/font-atlas-lifetime-result.json'
local candidateProvenance=require('Save.Selection');assert(type(candidateProvenance.read)=='function')
local r={provenanceModuleOnly='Save.Selection',status='RUNNING',diagnosticOnly=true,osInput=false,cases={},changesGameState=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
local latest,serial=nil,0;local listener=D.Node();listener:addTo(D.Director.ui)
listener:gslot('AppWS',function(event)
 if event.type=='Send'then local ok,data=pcall(D.json.decode,event.msg,32);if ok and data and data.name=='Profiler'then local info=data.info;latest={textures=info.textures,textureMemory=info.textureMemory,fonts=info.fonts,fontMemory=info.fontMemory};serial=serial+1 end end
end)
local priorProfiler=D.Director.profilerSending;D.Director.profilerSending=true
local function settled()
 collectgarbage('collect');D.sleep(.3);collectgarbage('collect')
 local before=serial;local deadline=D.App.totalTime+4
 while serial==before do assert(D.App.totalTime<deadline,'Missing profiler telemetry');D.sleep(.05)end
 return {objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount,textures=latest.textures,textureMemory=latest.textureMemory,fonts=latest.fonts,fontMemory=latest.fontMemory}
end
D.thread(function()
 local ok,why=xpcall(function()
  local chars={};for code=0x4e00,0x4e00+1199 do chars[#chars+1]=utf8.char(code)end;local text=table.concat(chars)
  r.font='SourceHanSansCN-Regular';r.fixedCodepoints=1200
  for _,mode in ipairs({'preserve-font-cache','remove-unused-font-cache'})do
   local case={mode=mode,samples={}};r.cases[#r.cases+1]=case
   for n=1,4 do
    local before=settled();local label=assert(D.Label(r.font,30,true));label.text=text;label:cleanup();label=nil
    local afterDispose=settled();if mode=='remove-unused-font-cache'then D.Cache:removeUnused('Font')end
    local after=settled();case.samples[#case.samples+1]={index=n,before=before,afterDispose=afterDispose,after=after};save()
   end
  end
 end,debug.traceback)
 D.Director.profilerSending=priorProfiler;listener:removeFromParent();r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
