local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local result={status='RUNNING',runId=tostring(os.time()),assets={}};local out=D.Path(root,'Test/jade-animation-catalog-result.json')
local function save()D.Content:save(out,D.json.encode(result))end
save();D.thread(function()
 local ok,err=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  for index,asset in ipairs({'yu','vika','vivi'})do
   D.Cache:loadAsync('spine:'..asset);local m=assert(D.Spine(asset));m.position=D.Vec2(350+(index-1)*500,280);m.scaleX=.5;m.scaleY=.5;m:addTo(D.Director.entry)
   local r={asset=asset,looks=D.Spine:getLooks(asset),animations=D.Spine:getAnimations(asset),measured={}};result.assets[#result.assets+1]=r;save()
   for _,name in ipairs(r.animations)do
    local sample={name=name,events={}};r.measured[#r.measured+1]=sample;local started=D.App.runningTime;local ended=false
    m:slot('AnimationEnd'):set(function(n)if n==name then ended=true;sample.elapsed=D.App.runningTime-started end end)
    m:slot('attack'):set(function()sample.events[#sample.events+1]={name='attack',seconds=D.App.runningTime-started}end)
    m.recovery=0;m.speed=1;sample.duration=m:play(name,false);assert(sample.duration>0,'Empty '..asset..'/'..name)
    local deadline=started+sample.duration+2;while not ended do assert(D.App.runningTime<deadline,'Missing animation end '..name);D.sleep(.01)end
    assert(sample.elapsed>=sample.duration-.04,'Truncated '..name);save()
   end
   m.recovery=.2;m:play('idle',true)
  end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/jade-original-actors.tga'));D.sleep(.2);result.status='PASS'
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;save();print(D.json.encode(result))
end)
