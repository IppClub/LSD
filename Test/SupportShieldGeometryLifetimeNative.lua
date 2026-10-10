-- Real native SupportView/DrawNode and shield rules; controlled UI-only inputs.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/support-shield-geometry-lifetime-result.json'
local r={status='RUNNING',osInput=false,controlledUiFixture=true,formalCombat=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local meta,originalIndex
 local ok,why=xpcall(function()
  local base='/private/tmp/lsd-support-shield-geometry-20261009/'
  local beforeRaw=assert(D.Content:load(base..'SupportView-before.lua'))
  local candidateRaw=assert(D.Content:load(base..'SupportView-candidate.lua'))
  local variants={{'before',assert(load(beforeRaw,'@'..base..'SupportView-before.lua'))()},{'candidate',assert(load(candidateRaw,'@'..base..'SupportView-candidate.lua'))()},{'production',require('Ground.SupportView')}}
  local tracked=setmetatable({},{__mode='k'})
  local geometry
  for _,variant in ipairs(variants)do
   local world=D.Node();world.offset=0;world:addTo(D.Director.ui)
   local support=require('Ground.LifeSupport').new(90,'defence')
   support.hp={100,100,100}
   support:update(0,{300,400,500})
   local rules=require('Ground.PhysicalShield');local physical=rules.new(support,0)
   local view=variant[2].create(world,'defence',-2,-3)
   local shield=assert(view.field:getChildByTag('ground-physical-shield'))
   if not meta then
    meta=getmetatable(shield);originalIndex=assert(meta.__index)
    local function read(object,key)
     if type(originalIndex)=='function'then return originalIndex(object,key)end
     return originalIndex[key]
    end
    meta.__index=function(object,key)
     local value=read(object,key);local count=tracked[object]
     if count and key=='clear'then return function(self,...)
      count.clears=count.clears+1;count.lastGeometry={};return value(self,...)
     end end
     if count and key=='drawSegment'then return function(self,a,b,width,color,...)
      count.segments=count.segments+1
      count.lastGeometry[#count.lastGeometry+1]={a.x,a.y,b.x,b.y,width,color:toARGB()}
      return value(self,a,b,width,color,...)
     end end
     return value
    end
   end
   local count={clears=0,segments=0,lastGeometry={}};tracked[shield]=count
   local expectedBuilds,lastFraction=0,nil
   local alphaReference=D.Node()
   local function update(expectedVisible)
    if expectedVisible and lastFraction~=support.physicalShield.charge/physical.capacity then
     expectedBuilds=expectedBuilds+1;lastFraction=support.physicalShield.charge/physical.capacity
    end
    view:update(support,300,500)
    assert(shield.visible==expectedVisible)
    if expectedVisible then
     alphaReference.opacity=.25+.75*support.physicalShield.charge/physical.capacity
     assert(shield.opacity==alphaReference.opacity,'Native charge opacity changed')
    end
   end
   update(true);assert(count.segments==30 and count.clears==1)
   local current=D.json.encode(count.lastGeometry)
   if geometry then assert(current==geometry,'Native geometry/style changed')else geometry=current end
   -- Resolve an actual eligible enemy impact, then the real delayed recharge.
   local remaining,event=physical:resolve(40,support.x,0,0,{kind='enemy-melee',skill='controlled',actor='machine'})
   assert(remaining==0 and event.absorbed==40);update(true)
   local updates=2
   for i=1,12 do physical:update(4+i*.5);update(true);updates=updates+1 end
   support.gold=0;support.active=false;update(false);support.gold=90;support.active=true;update(true);updates=updates+1
   local depleted=physical:resolve(physical.charge,support.x,0,14,{kind='enemy-melee',skill='controlled-depletion',actor='machine'})
   assert(depleted==0 and physical.charge==0);update(false)
   physical:update(20);assert(physical.charge>0);update(true);updates=updates+1
   assert(D.json.encode(count.lastGeometry)==geometry)
   if variant[1]=='before'then assert(count.segments==expectedBuilds*30 and count.clears==expectedBuilds)
   else assert(count.segments==30 and count.clears==1)end
   assert(rules.validate(physical:finish(20)))
   r.cases[#r.cases+1]={variant=variant[1],visibleUpdates=updates,drawSegments=count.segments,clears=count.clears,geometryExactlyPreserved=true,chargeOpacityPreserved=true,stoppedAndReactivated=true,zeroAndRecharge=true,physicalRulesValidated=true}
   tracked[shield]=nil;world:removeFromParent();save()
  end
  meta.__index=originalIndex;meta=nil
  assert(D.Content:load(base..'SupportView-before.lua')==beforeRaw and D.Content:load(base..'SupportView-candidate.lua')==candidateRaw)
  r.scope='Native geometry-call counts, exact vertices/style, charge opacity, real recharge and visibility only; not whole-combat FPS or natural Boss victory'
 end,debug.traceback)
 if meta and originalIndex then meta.__index=originalIndex end
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
