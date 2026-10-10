-- Real retained SDF/non-SDF labels while a distinct font is repeatedly evicted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/font-atlas-live-labels-result.json'
assert(type(require('Save.Selection').read)=='function')
local r={status='RUNNING',diagnosticOnly=true,osInput=false,provenanceModuleOnly='Save.Selection',samples={},screenshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
local latest,serial=nil,0;local node=D.Node();node:addTo(D.Director.ui)
node:gslot('AppWS',function(event)
 if event.type=='Send'then local ok,data=pcall(D.json.decode,event.msg,32);if ok and data and data.name=='Profiler'then latest=data.info;serial=serial+1 end end
end)
local prior=D.Director.profilerSending;D.Director.profilerSending=true
local function settled()
 collectgarbage('collect');D.sleep(.3);collectgarbage('collect');local before=serial;local deadline=D.App.totalTime+4
 while serial==before do assert(D.App.totalTime<deadline,'Missing profiler telemetry');D.sleep(.05)end
 return{objects=D.Object.count,textures=latest.textures,textureMemory=latest.textureMemory,fonts=latest.fonts,fontMemory=latest.fontMemory,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount}
end
local function screenshot(name)
 local path=D.Path(D.Content.writablePath,name..'.tga');D.App:saveScreenshot(path);D.sleep(.4);r.screenshots[#r.screenshots+1]=path;save()
end
D.thread(function()
 local ok,why=xpcall(function()
  D.View.scale=1
  local sdf=assert(D.Label('SourceHanSansCN-Regular',30,true));sdf.text='保留字幕：仍有回应 · 星空与旅人';sdf.position=D.Vec2(480,420);sdf:addTo(node)
  local plain=assert(D.Label('SourceHanSansCN-Regular',28,false));plain.batched=false;plain.text='保留界面：生命 100 / 护甲 80';plain.position=D.Vec2(480,350);plain:addTo(node)
  local first=assert(plain:getCharacter(1));local originalTexture=first.texture;first=nil
  r.baseline=settled();screenshot('font-live-before')
  local chars={};for code=0x4e00,0x4e00+3599 do chars[#chars+1]=utf8.char(code)end;local churnText=table.concat(chars)
  for n=1,4 do
   local churn=assert(D.Label('SourceHanSansCN-Regular',37,false));churn.visible=false;churn:addTo(node);churn.text=churnText;local allocated=settled();churn:removeFromParent();churn=nil
   D.Cache:removeUnused('Font');local after=settled()
   assert(sdf.text=='保留字幕：仍有回应 · 星空与旅人' and plain.text=='保留界面：生命 100 / 护甲 80')
   local sp=assert(plain:getCharacter(1));local same=sp.texture==originalTexture;assert(same,'Live character texture changed or was released');sp=nil
   r.samples[#r.samples+1]={index=n,allocated=allocated,after=after,liveTexturePreserved=same};screenshot('font-live-after-'..n);save()
  end
  r.churnAllocatedExtraPages=false;for _,sample in ipairs(r.samples)do if sample.allocated.textures>r.baseline.textures then r.churnAllocatedExtraPages=true end end;assert(r.churnAllocatedExtraPages,'Probe did not allocate an additional atlas')
  r.liveLabelsPreserved=true;originalTexture=nil;sdf:removeFromParent();plain:removeFromParent();sdf=nil;plain=nil
  settled();D.Cache:removeUnused('Font');r.afterAllLabels=settled()
 end,debug.traceback)
 D.Director.profilerSending=prior;node:removeFromParent();r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
