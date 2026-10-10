local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-aim-occlusion-result.json';local r={status='RUNNING',checks=0,blocked=0,times={old=0,new=0}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-aim-occlusion-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  local support=require('Ground.LifeSupport').new(90,'defence');support.hp={100,100,100}
  local b=require('Factory.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}},support,{training=true})
  local c=b.partCombat;local G=require('Combat.HitGeometry');local Aim=require('Combat.PartAim')
  local function check(from,to)
   c:sample() -- Keep pose preparation outside both visibility timings.
   local start=D.App.elapsedTime;local old=c:contact(from,to);r.times.old=r.times.old+D.App.elapsedTime-start
   local expected=not not(old and (old.terrain or old.enemy))
   start=D.App.elapsedTime;local got=c:aimBlocked(from,to);r.times.new=r.times.new+D.App.elapsedTime-start
   assert(expected==got,'Visibility changed '..D.json.encode({from=from,to=to,expected=expected,got=got,old=old and {t=old.t,part=old.part,terrain=old.terrain,enemy=old.enemy~=nil}}))
   r.checks=r.checks+1;if got then r.blocked=r.blocked+1 end
   return got
  end
  for pose=1,10 do
   b.roots[3].enemy.faceRight=pose%2==0;D.sleep(.1);c:sample()
   for _,right in ipairs({false,true})do
    local direction=right and 1 or -1
    for _,distance in ipairs({150,450,900})do
     for _,height in ipairs({-50,100,300})do
      local from={x=c.boss.enemy.x-direction*distance,y=c.boss.enemy.y+height}
      for _,part in ipairs({'flower-head','flower-core','petal-left','petal-right','roots'})do
       Aim.solve(from,right,part,c.target.regions,check)
      end
     end
    end
   end
  end
  -- Deliberately place a physics wall or another living enemy before, at,
  -- and beyond a proven Boss contact in both directions.
  r.obstacles={}
  for _,e in ipairs(b.enemies)do if e~=c.boss then e.enemyHP=0 end end
  c.boss.enemy.playable.speed=0;D.sleep(.2)
  for _,right in ipairs({false,true})do
   c:sample();local bounds={minX=math.huge,maxX=-math.huge,minY=math.huge,maxY=-math.huge}
   for _,part in ipairs(c.target.regions)do for _,v in ipairs(part.vertices)do
    bounds.minX=math.min(bounds.minX,v.x);bounds.maxX=math.max(bounds.maxX,v.x);bounds.minY=math.min(bounds.minY,v.y);bounds.maxY=math.max(bounds.maxY,v.y)
   end end
   local from,hit;local dir=right and 1 or -1
   for y=bounds.maxY-20,bounds.minY+20,-10 do
    from={x=right and bounds.minX-400 or bounds.maxX+400,y=y}
    hit=G.nearest(from,{x=right and bounds.maxX+100 or bounds.minX-100,y=y},c.target.regions)
    if hit and not hit.startedInside and not c:aimBlocked(from,hit.position)then break end
    hit=nil
   end
   assert(hit and not hit.startedInside)
   for _,kind in ipairs({'terrain','enemy','dead-enemy'})do
    for _,offset in ipairs({-100,0,100})do
     local def=D.BodyDef();def.type='Static';def:attachPolygon(10,50,1,0,0)
     local body=D.Body(def,b.arena.world,D.Vec2(hit.position.x+dir*(offset+5),hit.position.y));body.group=kind=='terrain' and D.Platformer.Data.groupTerrain or 2;body:addTo(b.arena.world)
     local record={enemy=body,enemyHP=kind=='dead-enemy' and 0 or 100};if kind~='terrain'then b.enemies[#b.enemies+1]=record end
     D.sleep(.03)
     local got=check(from,hit.position);
     if offset<0 and kind~='dead-enemy'then assert(got,'Foreground obstacle was ignored')
     elseif offset>0 or kind=='dead-enemy'then assert(not got,'Background/dead obstacle occluded aim')end
     r.obstacles[#r.obstacles+1]={right=right,kind=kind,offset=offset,blocked=got}
     if kind~='terrain'then b.enemies[#b.enemies]=nil end;body:removeFromParent();D.sleep(.03)
    end
   end
  end
  assert(r.checks>100 and r.blocked>0)
  b.arena.closed=true;b.wuyun.closed=true;b.arena.world:removeFromParent()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
