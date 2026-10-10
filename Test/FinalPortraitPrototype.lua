local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local file=D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.json')..'|'..D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.atlas')
 D.Cache:loadAsync('spine:niniliteFigure');D.Cache:loadAsync('spine:'..file)
 local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
 for i,asset in ipairs({'niniliteFigure',file})do
  local m=assert(D.Spine(asset));m.scaleX=.3;m.scaleY=.3;m.position=D.Vec2(ui.width*(i-.5)/2,80);m:play(i==1 and'idle'or'listenPrototype',true);m:addTo(ui)
  local l=D.Label('SourceHanSansCN-Regular',24);l.text=i==1 and'原立绘'or'闭口附件制作预览';l.position=D.Vec2(ui.width*(i-.5)/2,ui.height-60);l:addTo(ui)
 end
 D.sleep(1);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-portrait-mouth-prototype.tga'));D.sleep(.2);print('FinalPortraitPrototype captured')
end)
