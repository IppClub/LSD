local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/big-shan-hand-pose-result.json',D.json.encode({status='RUNNING'}))
D.thread(function()
 D.App.winSize=D.Size(960,540);D.Cache:loadAsync('spine:dashanxiao-release')
 D.sleep(.1);local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);local models={}
 for row,name in ipairs({'throw','throw'})do
  for i,t in ipairs({1.2,1.23333,1.26667,1.3,1.33333,1.36667,1.4})do
   local m=D.Spine('dashanxiao-release');m.look='default';m.fliped=row==2;m.scaleX=.28;m.scaleY=.28;m.position=D.Vec2(100+(i-1)*270, row==1 and 620 or 180);m:addTo(ui);m:play(name,false)
   local label=D.Label('SourceHanSansCN-Regular',20);label.text=name..' '..t;label.position=D.Vec2(m.x,row==1 and 1000 or 500);label:addTo(ui)
   local box=D.Sprite('Image/box1.png');box.scaleX=.28;box.scaleY=.28;box:addTo(ui);models[#models+1]={model=m,time=t,box=box}
  end
 end
 local manifest=D.json.decode(D.Content:load(root..'/Data/Combat/big-shan-release.json'));local elapsed=0;local started=D.App.runningTime
 while elapsed<3 do D.sleep(.01);elapsed=D.App.runningTime-started;for _,item in ipairs(models)do local x,y=0,0;for _,ref in ipairs(manifest.front.refs)do local p=item.model:getKey(ref.key);x=x+p.x*ref.weight;y=y+p.y*ref.weight end;item.box.position=ui:convertToNodeSpace(item.model:convertToWorldSpace(D.Vec2(x,y)));if elapsed>=item.time then item.model.speed=0 end end end
 D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-shan-hand-pose.tga');D.sleep(.2)
 D.Content:save(root..'/Test/big-shan-hand-pose-result.json',D.json.encode({status='PASS'}))
end)
