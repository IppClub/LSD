-- Authored pose survey before assigning damage windows; no save access.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/small-yingzhao-impact-pose-result.json';local result={status='RUNNING',clips={}}
local function save()D.Content:save(out,D.json.encode(result,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.App.winSize=D.Size(960,480);D.Cache:loadAsync('spine:xiaoyingzhao');D.sleep(.2)
  local ui=D.Node();ui:addTo(D.Director.ui3D);local size=D.App.bufferSize;ui.position=D.Vec2(-size.width/2,-size.height/2);local cells={}
  local names={'jump2','kick'}
  for row,name in ipairs(names)do
   for col,fraction in ipairs(name=='kick' and {.45,.55,.65,.75,.85,.95} or {.05,.1,.15,.2,.25,.3})do
    local m=assert(D.Spine('xiaoyingzhao'));m.look='default';m.scaleX=.5;m.scaleY=.5
    m.position=D.Vec2((col-.5)*size.width/6,size.height*(1-row/2)+65);m:addTo(ui)
    local duration=m:play(name,false);assert(duration>0)
    local label=D.Label('SourceHanSansCN-Regular',20);label.text=string.format('%s %.3fs',name,fraction);label.position=D.Vec2(m.x,size.height*(1-(row-1)/2)-30);label:addTo(ui)
    cells[#cells+1]={model=m,time=fraction};result.clips[name]=duration
   end
  end
  local start=D.App.runningTime
  while D.App.runningTime-start<1.9 do
   D.sleep(.01);local elapsed=D.App.runningTime-start
   for _,cell in ipairs(cells)do if elapsed>=cell.time then cell.model.speed=0 end end
  end
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/small-yingzhao-impact-poses.tga');D.sleep(.2)
 end,debug.traceback)
 result.status=ok and 'PASS' or 'FAIL';result.error=not ok and err or nil;save()
end)
