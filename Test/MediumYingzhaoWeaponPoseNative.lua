-- Authored pose survey before assigning damage windows; no save access.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/medium-yingzhao-weapon-pose-result.json';local result={status='RUNNING',clips={}}
local function save()D.Content:save(out,D.json.encode(result,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.App.winSize=D.Size(960,600);D.Cache:loadAsync('spine:zhongyingzhao-weapon.skel|zhongyingzhao.atlas');D.Cache:loadAsync('spine:kineticgun');D.sleep(.2)
  local ui=D.Node();ui:addTo(D.Director.ui3D);local size=D.App.bufferSize;ui.position=D.Vec2(-size.width/2,-size.height/2);local cells={}
  local names={'gunidle','shoot'}
  for row,name in ipairs(names)do
   for col,fraction in ipairs({.25,.5,.75,.95})do
    local m=assert(D.Spine('zhongyingzhao-weapon.skel|zhongyingzhao.atlas'));m.look='default';m.scaleX=.6;m.scaleY=.6
    m.position=D.Vec2((col-.5)*size.width/4,size.height*(1-row/2)+65);m:addTo(ui)
    local gun=D.Spine('kineticgun');gun.look='PT';gun.scaleX=.3;gun.scaleY=-.3;m:setSlot('pistol',gun)
    local duration=m:play(name,false);assert(duration>0)
    local label=D.Label('SourceHanSansCN-Regular',20);label.text=string.format('%s %.3fs',name,duration*fraction);label.position=D.Vec2(m.x,size.height*(1-(row-1)/2)-30);label:addTo(ui)
    cells[#cells+1]={model=m,time=duration*fraction};result.clips[name]=duration
   end
  end
  local start=D.App.runningTime
  while D.App.runningTime-start<2.1 do
   D.sleep(.01);local elapsed=D.App.runningTime-start
   for _,cell in ipairs(cells)do if elapsed>=cell.time then cell.model.speed=0 end end
  end
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/medium-yingzhao-weapon-poses.tga');D.sleep(.2)
 end,debug.traceback)
 result.status=ok and 'PASS' or 'FAIL';result.error=not ok and err or nil;save()
end)
