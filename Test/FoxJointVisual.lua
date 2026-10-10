-- Anatomical atlas-landmark verification plus native pose sheets. Isolated, no save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local function label(text,x,y)local l=D.Label('SourceHanSansCN-Regular',22);l.text=text;l.position=D.Vec2(x,y);l:addTo(ui)end
  local ref=assert(D.Model('Image/Companion/fox-chibi.model'));ref.scaleX=.65;ref.scaleY=.65;ref.position=D.Vec2(240,110);ref:addTo(ui);ref:play('idle',true)
  label('原 Q 版设计',240,620)
  local manifest=assert(D.json.decode(D.Content:load('Image/Companion/fox-chibi-motion-v5-manifest.json')))
  local models={}
  for i,name in ipairs({'nearFoot','farFoot'})do
   local s=assert(D.Sprite('Image/Companion/fox-chibi-motion-v5.clip|'..name));s.position=D.Vec2(300+(i-1)*450,850);s.scaleX=2.5;s.scaleY=2.5;s:addTo(ui);label(name..' 原图足部朝向',s.x,1000)
  end
  D.Cache:unload('Image/Companion/fox-chibi-motion-v5.model');D.Cache:unload('Image/Companion/fox-chibi-motion-v5.clip')
  for i=1,3 do local m=require('Story.FoxCompanionRig').create('Image/Companion/fox-chibi-motion-v5.model',454.35);m.position=D.Vec2(640+(i-1)*410,110);m:addTo(ui);m.recovery=0;models[i]=m end
  models[1]:play('idle',true);models[2]:play('move',true);models[3]:play('move',true);models[3].fliped=true
  label('关节修复候选 · 待机',640,620);label('默认朝左 · 行走',1050,620);label('镜像朝右 · 行走',1460,620)
  D.sleep(.35)
  local max=0
  local function point(m,name,pixel)
   local chain={};local node=m:getNodeByName(name..'-bone');while node do chain[#chain+1]=node;node=node.parent end
   for i=#chain,1,-1 do chain[i]:convertToWorldSpace(D.Vec2.zero)end
   local a=manifest.landmarks[name];local r=a[1];local n=m:getNodeByName(name)
   return n:convertToWorldSpace(D.Vec2(pixel[1]-r[1],r[4]-(pixel[2]-r[2])))
  end
  local forwardErrors=0
  -- Proximal/distal points are explicit pixels from source art, never inferred from first pose.
  for f=1,120 do
   for _,m in ipairs(models)do for _,pair in ipairs({{'nearUpperArm','nearForearm'},{'farUpperArm','farForearm'},{'nearThigh','nearShin'},{'farThigh','farShin'},{'nearShin','nearFoot'},{'farShin','farFoot'}})do
    local a,b=pair[1],pair[2];local p=point(m,a,manifest.landmarks[a][3]);local q=point(m,b,manifest.landmarks[b][2]);max=math.max(max,(p-q).length)
   end
    for _,name in ipairs({'nearFoot','farFoot'})do
     local pivot=point(m,name,manifest.landmarks[name][2]);local toe=point(m,name,manifest.footForwardLandmarks[name]);local expected=m.fliped and 1 or -1
     if (toe.x-pivot.x)*expected<=0 then forwardErrors=forwardErrors+1 end
    end
   end
   D.sleep(1/60)
  end
  assert(max<.6,'Actual artwork landmark separation '..max);assert(forwardErrors==0,'Toe direction contradicts face direction')
  for i=0,3 do models[2]:play('move',true);models[3]:play('move',true);D.sleep(i*.25+.03);models[2].speed=0;models[3].speed=0;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-v5-joints-pose-'..i..'.tga'));D.sleep(.08);models[2].speed=1;models[3].speed=1 end
  models[2]:play('move',true);models[3]:play('move',true)
  return 'PASS sourcePixelLandmarks=true maximumSeparation='..max..' bothFeetFaceTravel=true screenshotsRequireVisualReview=true isolatedArtComparison=true'
 end,debug.traceback)
 local report='LSD_FOX_JOINT_VISUAL_'..(ok and result or 'FAIL '..result);print(report);D.Content:save(D.Path(root,'Test/fox-joint-visual-result.txt'),report..'\n')
end)
