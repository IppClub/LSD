local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 D.Cache:loadAsync('spine:niniliteFigure')
 local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
 for i,t in ipairs({0.05,1.3,2.9,3.6})do
  local n=require('UI.StoryFigure')({char='ninilite'});n.scaleX=.28;n.scaleY=.28;n.position=D.Vec2(ui.width*(i-.5)/4,100);n:addTo(ui)
  local m=n.children.first;m.speed=1;m:play('idle',true);D.sleep(t);m.speed=0
  local l=D.Label('SourceHanSansCN-Regular',24);l.text='idle '..t..' s';l.position=D.Vec2(ui.width*(i-.5)/4,ui.height-60);l:addTo(ui)
 end
 D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/ninilite-portrait-native-study.tga'));D.sleep(.2);print('FinalPortraitStudy complete')
end)
