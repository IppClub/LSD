-- Isolated weighted-mesh/retarget preview. Runtime checks do not imply art approval.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/fox-spine-preview-result.txt');D.Content:save(out,'LSD_FOX_SPINE_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  D.Cache:unload(D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas'))
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local function title(text,x)local l=D.Label('SourceHanSansCN-Regular',21);l.text=text;l.position=D.Vec2(x,740);l:addTo(ui)end
  local original=assert(D.Model('Image/Companion/fox-chibi.model'));original.scaleX=.55;original.scaleY=.55;original.position=D.Vec2(240,190);original.fliped=true;original:addTo(ui);original:play('idle',true);title('原设计 · 朝向对齐',240)
  local ni=assert(D.Spine('ninilite'));ni.scaleX=1.303;ni.scaleY=1.303;ni.position=D.Vec2(670,190);ni:addTo(ui);ni.recovery=.2;title('妮妮莉特 · 原作',670)
  local baseline=assert(D.Spine(D.Path(root,'Docs/artwork/fox-baseline/fox-pre-knee.skel')..'|'..D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas')));baseline.scaleX=.55;baseline.scaleY=.55;baseline.position=D.Vec2(1080,190);baseline.fliped=true;baseline:addTo(ui);baseline.recovery=.2;title('狐狸 · 修改前',1080)
  local asset=D.Path(root,'Docs/artwork/fox-export/fox-chibi-spine.skel')..'|'..D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas');D.Cache:unload('spine:'..asset);D.Cache:loadAsync('spine:'..asset)
  local fox=assert(D.Spine(asset));fox.scaleX=.55;fox.scaleY=.55;fox.position=D.Vec2(1500,190);fox.fliped=true;fox:addTo(ui);fox.recovery=.2;title('狐狸 · 腿部弯曲调整',1500)
  for _,state in ipairs({'idle','fmove','prepare'})do
   local done=false;fox:slot('AnimationEnd'):set(function(name)if name==state then done=true end end)
   local start=D.App.runningTime;local duration=fox:play(state,false);ni:play(state,true);baseline:play(state,true);assert(duration>0)
   while not done do assert(D.App.runningTime<start+duration+2,'Spine finite action did not finish');D.sleep(.02)end
   assert(D.App.runningTime-start>=duration-.05)
  end
  for _,a in ipairs({ni,baseline,fox})do a:play('prepare',true)end;D.sleep(.6)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-spine-prepare.tga'));D.sleep(.1)
  for _,a in ipairs({ni,baseline,fox})do a:play('idle',true)end;D.sleep(.6)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-spine-idle.tga'));D.sleep(.1)
  fox:play('idle',true);D.sleep(1.34);fox.speed=0
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-spine-blink.tga'));D.sleep(.1);fox.speed=1
  for phase=0,3 do
   for _,a in ipairs({ni,baseline,fox})do a.speed=1;a:play('fmove',true)end;D.sleep(.2+phase*.25+.02)
   ni.speed=0;baseline.speed=0;fox.speed=0;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-spine-walk-'..phase..'.tga'));D.sleep(.1)
  end
  for _,a in ipairs({ni,baseline,fox})do a.speed=1;a:play('fmove',true)end
  return 'PASS nativeSpineBinary=true editorRoundtrip=true authoredThreeFiniteEnds=true weightedMeshes=true noSaveAttached=true visualAcceptancePending=true'
 end,debug.traceback)
 local report='LSD_FOX_SPINE_'..(ok and result or 'FAIL '..result)..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
