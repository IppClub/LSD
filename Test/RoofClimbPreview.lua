local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local result={status='RUNNING',scope='candidate climb preview; not traversal acceptance'};local out=D.Path(root,'Test/roof-climb-preview-result.json');D.Content:save(out,D.json.encode(result))
 local ok,why=xpcall(function()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff243a43));bg:addTo(ui,-100)
  local actors={};local scale=math.min(ui.width/1800,ui.height/1136)*2
  for i,name in ipairs({'charM','charF','ninilite'})do
   local x=ui.width*(i-.5)/3;local wall=require('Factory.RoofArt').sprite('climbWall',ui,x,80,240*scale,450*scale,-20)
   local m=assert(D.Spine('Spine/Roof/'..name..'.json|Spine/'..name..'.atlas'));m.position=D.Vec2(x,170);m.scaleX=scale;m.scaleY=scale;m.recovery=0;m:addTo(ui);assert(m:play('climb',true)>2.39);actors[#actors+1]=m
   local l=D.Label('SourceHanSansCN-Regular',24);l.text=name..' · 攀爬候选';l.position=D.Vec2(x,ui.height-40);l:addTo(ui,50)
  end
  local elapsed=0;local dots=D.DrawNode();dots:addTo(ui,40)
  ui:schedule(function(dt)
   elapsed=elapsed+dt;dots:clear()
   for _,m in ipairs(actors)do
    m.y=170+elapsed%4.8*25*scale
    for _,key in ipairs({'climbHandL','climbHandR','climbFootL','climbFootR'})do
     local p=m:getKey(key..'/'..key);dots:drawDot(D.Vec2(m.x+p.x*scale,m.y+p.y*scale),4,D.Color(0xfffae281))
    end
   end
   return false
  end)
  for i=1,4 do D.sleep(i==1 and .02 or .6);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-climb-pose-'..i..'.tga'))end
  ui:unschedule();for _,m in ipairs(actors)do m.speed=0 end
  result.status='PASS';result.loadedActors=3;result.visualAcceptance=false;result.contactAcceptance=false
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
