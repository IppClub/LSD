local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/big-shan-ambush-pose-result.json',D.json.encode({status='RUNNING'}))
D.thread(function()
 D.App.winSize=D.Size(960,540);D.Cache:loadAsync('spine:dashanxiao')
 D.sleep(.1);local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);local models={}
 for row,name in ipairs({'ambush1','ambush2'})do
  for i,t in ipairs({0,.2,.4,.6,.8,1.0,1.2})do
   local m=D.Spine('dashanxiao');m.look='default';m.scaleX=.28;m.scaleY=.28;m.position=D.Vec2(100+(i-1)*270, row==1 and 620 or 180);m:addTo(ui);m:play(name,false)
   local label=D.Label('SourceHanSansCN-Regular',20);label.text=name..' '..t;label.position=D.Vec2(m.x,row==1 and 1000 or 500);label:addTo(ui)
   models[#models+1]={model=m,time=t}
  end
 end
 local elapsed=0;local started=D.App.runningTime
 while elapsed<3 do D.sleep(.01);elapsed=D.App.runningTime-started;for _,item in ipairs(models)do if elapsed>=item.time then item.model.speed=0 end end end
 D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-shan-ambush-pose.tga');D.sleep(.2)
 D.Content:save(root..'/Test/big-shan-ambush-pose-result.json',D.json.encode({status='PASS'}))
end)
