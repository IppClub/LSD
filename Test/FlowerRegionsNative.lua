local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine'})do D.Content:insertSearchPath(1,p)end
local out=root..'/Test/flower-regions-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  D.App.winSize=D.Size(683,500)
  local node=D.Node();node:addTo(D.Director.entry)
  local model=assert(D.Spine(root..'/Docs/artwork/flower-hitboxes/export/dahuayao-hitboxes'));model:addTo(node);model.position=D.Vec2(0,-220);model.scaleX=.5;model.scaleY=.5
  local original=assert(D.Spine('dahuayao'));original.visible=false
  local before=assert(D.Spine(root..'/Test/Fixtures/FlowerRegionsBefore/dahuayao-hitboxes'));before.visible=false;before.position=model.position;before.scaleX=model.scaleX;before.scaleY=model.scaleY
  local oldManifest=D.json.decode(D.Content:load(root..'/Test/Fixtures/FlowerRegionsBefore/vertex-probes.json'))
  local maxError=0;local vertexChecks=0;local rayChecks=0
  local manifest=D.json.decode(D.Content:load(root..'/Docs/artwork/flower-hitboxes/vertex-probes.json'))
  local draw=D.DrawNode();draw:addTo(node,10)
  local count=0;local samples=0;local sampleSeconds=0;local sampleMax=0;local colors={['flower-head']=0xfff5d442,['flower-core']=0xff00ddff,['petal-left']=0xffff6699,['petal-right']=0xff55ff66,roots=0xffaa88ff}
  draw:schedule(function()
   draw:clear();local t=D.App.elapsedTime;local regions=require('Combat.SpineRegions').sample(model,manifest,node);local dt=D.App.elapsedTime-t;sampleSeconds=sampleSeconds+dt;sampleMax=math.max(sampleMax,dt);count=0
   for i,region in ipairs(regions)do
    for j,v in ipairs(region.vertices)do
     assert(v.x==v.x and v.y==v.y);local next=region.vertices[j%#region.vertices+1]
     draw:drawSegment(D.Vec2(v.x,v.y),D.Vec2(next.x,next.y),1,D.Color(colors[region.id]));count=count+1
    end
   end
   samples=samples+1;return false
  end)
  local animations={'attack','dizzy1','dizzy2','hit','idle','idle1','lose','move','seed1','seed2','seed3','transv1','transv2','transv3','twine'}
  for _,name in ipairs(animations)do
   assert(math.abs(model:play(name,false)-original:play(name,false))<.001,name);before:play(name,false);D.sleep(.1)
   local sample=require('Combat.SpineRegions').sample
   local actual=sample(model,manifest,node);local expected=assert(load(D.Content:load(root..'/Test/Fixtures/FlowerRegionsBefore/SpineRegions.lua')))().sample(before,oldManifest,node)
   for i,part in ipairs(actual)do for j,v in ipairs(part.vertices)do
    local old=expected[i].vertices[j];local delta=math.max(math.abs(v.x-old.x),math.abs(v.y-old.y));maxError=math.max(maxError,delta);vertexChecks=vertexChecks+1
    assert(delta<.02,'Basis geometry changed '..name..' '..delta)
   end end
   local G=require('Combat.HitGeometry')
   for y=-200,180,20 do
    local a={x=-400,y=y};local b={x=400,y=y};local x=G.nearest(a,b,actual);local old=G.nearest(a,b,expected)
    assert((x==nil)==(old==nil),'Basis ray hit changed')
    if x then assert(x.part==old.part and math.abs(x.t-old.t)<.0001,'Basis first part changed')end;rayChecks=rayChecks+1
   end
  end
  r.parity={vertices=vertexChecks,rays=rayChecks,maxError=maxError}

  model:play('idle',true);D.sleep(.2)
  local parts={};for _,m in ipairs(manifest)do parts[m.id]={maxAP=70,armoredMultiplier=.1,exposedMultiplier=1,armoredResponse='stop'}end
  local target=require('Combat.PartTarget').new(model,manifest,node,{id='flower-geometry-fixture',maxHP=100,parts=parts})
  local G=require('Combat.HitGeometry');local old={};local initial={lian=true,qugan=true,zuohuabanxia=true,['3']=true,tengmantui=true}
  for i,m in ipairs(manifest)do if initial[m.sourceSlot]then old[#old+1]=target.regions[i]end end
  local function extension(slot)
   for i,m in ipairs(manifest)do if m.sourceSlot==slot then
    for _,v in ipairs(target.regions[i].vertices)do
     local a={x=v.x-3,y=v.y};local b={x=v.x+3,y=v.y};local hit=target:probe(a,b)
     if hit and hit.part==m.id and not G.nearest(a,b,old)then return hit end
    end
   end end
   error('No independent extension contact: '..slot)
  end
  local left1,left2,right,rootHit=extension('z3'),extension('z4'),extension('y3'),extension('tm6')
  local function apply(contact,id,ap,hp)return assert(target:apply(contact,{id=id,contactId='impact',source='fixture',weapon={id='test',armorDamage=ap,healthDamage=hp}}))end
  local first=apply(left1,'one',35,0);local second=apply(left2,'two',35,0);local third=apply(left1,'three',0,20)
  assert(first.apAfter==35 and second.apBefore==35 and second.apAfter==0 and second.armorBroken,'Disconnected pieces did not share armor')
  assert(third.healthDamage==20 and target.damage.parts['petal-right'].ap==70 and target.damage.parts.roots.ap==70)
  r.compoundArmor=true;r.extensions={left1.part,left2.part,right.part,rootHit.part};target:close()
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-regions-idle.tga');D.sleep(.15)
  model:play('twine',false);D.sleep(1.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-regions-twine.tga');D.sleep(.15)
  assert(count==840);r.vertices=count;r.samples=samples;r.animations=#animations;r.sampling={mean=sampleSeconds/samples,max=sampleMax}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
