local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/flower-packed-probes-result.json'
local r={status='RUNNING',poses=0,coordinates=0,maxError=0,oldSeconds=0,packedSeconds=0,samples=0}
local function save()D.Content:save(out,D.json.encode(r))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local R=require('Combat.SpineRegions')
  local old=D.json.decode(D.Content:load(root..'/Docs/artwork/flower-probes-packed/baseline/regions.json'))
  local packed=D.json.decode(D.Content:load(root..'/Docs/artwork/flower-probes-packed/regions.json'))
  local source=D.json.decode(D.Content:load(root..'/Docs/artwork/flower-probes-packed/dahuayao-probes-packed.json'))
  local a=assert(D.Spine(root..'/Docs/artwork/flower-probes-packed/baseline/dahuayao-hitboxes.skel|'..root..'/Spine/dahuayao-hitboxes.atlas'))
  local b=assert(D.Spine(root..'/Docs/artwork/flower-probes-packed/export/dahuayao-probes-packed.skel|'..root..'/Spine/dahuayao.atlas'))
  local parent=D.Node();parent:addTo(D.Director.entry);parent.scaleX=.8;parent.scaleY=1.2;parent.angle=17
  for _,m in ipairs({a,b})do m.look='default';m.recovery=0;m.scaleX=.6;m.scaleY=.75;m:addTo(parent)end
  for name in pairs(source.animations)do
   for _,flip in ipairs({false,true})do
    a.fliped=flip;b.fliped=flip;a.speed=1;b.speed=1
    local duration=a:play(name,false);assert(math.abs(duration-b:play(name,false))<1e-6)
    for pose=1,12 do
     D.sleep(duration/12)
     local x=R.sample(a,old,D.Director.entry);local y=R.sample(b,packed,D.Director.entry)
     assert(#x==#y)
     for i,p in ipairs(x)do
      assert(p.id==y[i].id and p.geometryId==y[i].geometryId and #p.vertices==#y[i].vertices)
      for j,v in ipairs(p.vertices)do
       local w=y[i].vertices[j];local e=math.max(math.abs(v.x-w.x),math.abs(v.y-w.y))
       r.maxError=math.max(r.maxError,e);assert(e<.05,name..' hull mismatch '..e);r.coordinates=r.coordinates+2
      end
     end
     r.poses=r.poses+1
    end
   end
  end
  a.speed=0;b.speed=0
  for i=1,200 do
   local function sample(m,manifest,key)local t=D.App.runningTime;R.sample(m,manifest,D.Director.entry);r[key]=r[key]+D.App.runningTime-t end
   if i%2==0 then sample(a,old,'oldSeconds');sample(b,packed,'packedSeconds')else sample(b,packed,'packedSeconds');sample(a,old,'oldSeconds')end
   r.samples=i;D.sleep()
  end
  parent:removeFromParent()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
