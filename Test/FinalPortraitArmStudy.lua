local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local file=D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.json')..'|'..D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.atlas')
 D.Cache:loadAsync('spine:'..file)
 local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
 for i,anim in ipairs({'armStudyA','armStudyB','armStudyC'})do
  local m=assert(D.Spine(file));m.scaleX=.22;m.scaleY=.22;m.position=D.Vec2(ui.width*(i-.5)/3-60,250);assert(m:play(anim,true)>0);m:addTo(ui)
  local l=D.Label('SourceHanSansCN-Regular',24);l.text=anim;l.position=D.Vec2(ui.width*(i-.5)/3,ui.height-70);l:addTo(ui)
 end
 D.sleep(1);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-portrait-arm-study.tga'));D.sleep(.2);print('FinalPortraitArmStudy captured')
end)
