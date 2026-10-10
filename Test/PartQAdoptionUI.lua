local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-q-adoption-ui-result.json';local r={status='RUNNING',osInput=false}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/part-q-ui.db';assert(not D.Content:exist(db) and not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  require('Data.Config'):loadAsync();require('Training.Level')(nil,'ninilite')
  local function wait(f)local untilTime=D.App.runningTime+150;while not f()do assert(D.App.runningTime<untilTime,'UI wait timed out');D.sleep(.05)end end
  local function enter()
   wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
   D.Director.ui3D:getChildByTag('training-controls'):getChildByTag('training-menu'):getChildByTag('护甲靶练习'):emit('Tapped')
   wait(function()return D.Director.ui3D:getChildByTag('part-practice')end)
   return D.Director.ui3D:getChildByTag('part-practice')
  end
  local ui=enter();local p=ui.practice
  ui:getChildByTag('自主部位练习'):emit('Tapped');wait(function()return p.candidate~=nil and not p.partQTraining end)
  assert(p.candidate.q and #p.demonstrations==0)
  ui:getChildByTag('三场部位对照'):emit('Tapped');wait(function()return p.evaluation~=nil end)
  r.comparison=p.evaluation.groups
  ui:getChildByTag('采用部位规则'):emit('Tapped');wait(function()return p.adopted~=nil and not p.saving end)
  assert(p.adopted.q and p.savedTrace.qTraining.updates==36)
  local traceId=p.adopted.traceId
  ui:getChildByTag('返回普通对练'):emit('Tapped');ui=enter();p=ui.practice
  assert(p.adopted.traceId==traceId and p.savedTrace.qTraining.updates==36)
  assert(#D.DB:query('SELECT * FROM lsd.Game0Training')==0)
  r.sizes={}
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.5);local buffer=D.App.bufferSize
   r.sizes[#r.sizes+1]={width=buffer.width,height=buffer.height}
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/part-q-adoption-ui-'..buffer.width..'x'..buffer.height..'.tga');D.sleep(.1)
  end
  r.reopened=true;r.adopted=true;r.originalActionModelUntouched=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
