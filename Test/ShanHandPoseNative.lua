local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/shan-hand-pose-result.json',D.json.encode({status='RUNNING'}))
D.thread(function()
 D.App.winSize=D.Size(960,540);D.Cache:loadAsync('spine:xiaoshanxiao-release')
 D.sleep(.1);local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);local models={}
 for row,name in ipairs({'litter','throw'})do
  for i,t in ipairs({.6,.8,1.0,1.13333,1.2,1.3,1.4})do
   local m=D.Spine('xiaoshanxiao-release');m.look='default';m.scaleX=.75;m.scaleY=.75;m.position=D.Vec2(100+(i-1)*270, row==1 and 620 or 180);m:addTo(ui);m:play(name,false)
   local label=D.Label('SourceHanSansCN-Regular',20);label.text=name..' '..t;label.position=D.Vec2(m.x,row==1 and 1000 or 500);label:addTo(ui)
   models[#models+1]={model=m,time=t}
  end
 end
 local elapsed=0;local started=D.App.runningTime
 while elapsed<1.5 do D.sleep(.01);elapsed=D.App.runningTime-started;for _,item in ipairs(models)do if elapsed>=item.time then item.model.speed=0 end end end
 local manifest=D.json.decode(D.Content:load('Data/Combat/shan-release.json'))
 for _,item in ipairs(models)do for label,part in pairs(manifest)do
  local x,y=0,0;for _,ref in ipairs(part.refs)do local point=item.model:getKey(ref.key);x=x+point.x*ref.weight;y=y+point.y*ref.weight end
  local mark=D.DrawNode();mark:drawDot(D.Vec2(x,y),8,D.Color(label=='front' and 0xff00ff00 or 0xffff0000));mark:addTo(item.model)
 end end
 D.sleep(.1)
 D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/shan-hand-pose.tga');D.sleep(.2)
 D.Content:save(root..'/Test/shan-hand-pose-result.json',D.json.encode({status='PASS'}))
end)
