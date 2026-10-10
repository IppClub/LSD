-- Native authored-pose survey; no gameplay or save mutation.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/big-yingzhao-pose-result.json';local r={status='RUNNING',clips={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.App.winSize=D.Size(1440,800);D.Cache:loadAsync('spine:dayingzhao');D.sleep(.2)
  for _,spec in ipairs({{'punch',{.75,.9,1,1.1,1.2,1.35}},{'massive',{.35,.5,.9,1.1,1.5,1.7}},{'wave',{1.8,2,2.1,2.2,2.3,2.5}},{'hunt',{.4,.8,1.2,1.6,2,2.6}},{'hero',{.2,.5,.8,1.1,1.4,1.8}},{'hero2',{.05,.15,.25,.35,.5,.65}},{'hero3',{.15,.4,.65,.9,1.15,1.5}}})do
   D.Director.ui3D:removeAllChildren();local ui=D.Node();ui:addTo(D.Director.ui3D);local size=D.App.bufferSize;ui.position=D.Vec2(-size.width/2,-size.height/2)
   local cells={};local entry={name=spec[1],samples={}};r.clips[#r.clips+1]=entry
   for i,t in ipairs(spec[2])do
    local m=assert(D.Spine('dayingzhao'));m.look='default';m.scaleX=.70;m.scaleY=.70
    local col=(i-1)%3;local row=math.floor((i-1)/3);m.position=D.Vec2((col+.5)*size.width/3,size.height*(1-(row+1)/2)+65);m:addTo(ui)
    entry.duration=m:play(spec[1],false);assert(entry.duration>0)
    local label=D.Label('SourceHanSansCN-Regular',26);label.text=string.format('%s %.2fs',spec[1],t);label.position=D.Vec2(m.x,size.height*(1-row/2)-35);label:addTo(ui)
    cells[#cells+1]={model=m,time=t,started=D.App.runningTime}
   end
   local ending=D.App.runningTime+entry.duration+.2
   while D.App.runningTime<ending do
    D.sleep();for _,c in ipairs(cells)do if not c.done and D.App.runningTime-c.started>=c.time then c.model.speed=0;c.done=true;entry.samples[#entry.samples+1]={requested=c.time,actual=D.App.runningTime-c.started}end end
   end
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-'..spec[1]..'-poses.tga');D.sleep(.15);save()
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
