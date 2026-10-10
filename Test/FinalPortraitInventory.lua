local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local report={status='RUNNING',actors={}}
 local ok,why=xpcall(function()
  for i,asset in ipairs({'sunbornFigure','charFFigure','charMFigure','niniliteFigure'})do
   D.Cache:loadAsync('spine:'..asset)
   local model=assert(D.Spine(asset));local animations={}
   for _,name in ipairs(D.Spine:getAnimations(asset))do animations[name]=model:play(name,false)end
   report.actors[asset]={animations=animations,looks=D.Spine:getLooks(asset)}
  end
  report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(D.Path(root,'Test/final-portrait-inventory.json'),D.json.encode(report));print(D.json.encode(report))
end)
