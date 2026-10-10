-- Reuse authored feathers and gust artwork; only damage resolution changes.
local D=require('Dora');local T=require('Ground.Tactics');local M={}
function M.attach(b)
 local p=b.bossCombat
 b.observeFireArrow=function(arrow,item,log,magic)
  p:projectile(arrow,'ninilite',nil,nil,log.step,{
   projectileKind='fire',
   weapon=function()return {id=item.enhanced and 'wind-fire'or'fire',armorDamage=0,healthDamage=item.enhanced and 18 or 12}end,
   onHit=function()item.spent=true;magic.fireHits=magic.fireHits+1;log.hits=(log.hits or 0)+1;if item.enhanced then magic.synergyHits=magic.synergyHits+1 end end})
  arrow:slot('Cleanup',function()item.spent=true end)
 end
 b.applyWind=function(gust,log,magic)
  p:sample();local candidates={};local origin={x=gust.x,y=gust.y}
  -- Body vertices and exact contour/cone intersections supply rays.
  -- Each body receives at most one wind hit. Each ray competes with cover and other bodies before any damage.
  local function add(x,y)if T.inWind(x,y,gust.x,gust.y,gust.direction)then candidates[#candidates+1]={x=x,y=y}end end
  local cone={{id='gust',vertices={{x=gust.x,y=gust.y-110},{x=gust.x+gust.direction*700,y=gust.y-250},{x=gust.x+gust.direction*700,y=gust.y+250},{x=gust.x,y=gust.y+110}}}}
  if p.armor:available()then for _,part in ipairs(p.armor.target.regions)do
   for i,v in ipairs(part.vertices)do local n=part.vertices[i%#part.vertices+1];add(v.x,v.y);add((v.x+n.x)/2,(v.y+n.y)/2);local crossing=require('Combat.HitGeometry').nearest(v,n,cone);if crossing then add(crossing.position.x,crossing.position.y)end end
  end end
  for _,e in ipairs(b.enemies)do if e~=p.boss and e.enemyHP>0 then add(e.enemy.x,e.enemy.y)end end
  table.sort(candidates,function(a,c)return (a.x-origin.x)^2+(a.y-origin.y)^2<(c.x-origin.x)^2+(c.y-origin.y)^2 end)
  local contacts,seen={},{}
  for _,point in ipairs(candidates)do
   local dx,dy=point.x-origin.x,point.y-origin.y;local length=math.sqrt(dx*dx+dy*dy)
   local to=length>0 and {x=point.x+dx/length*.1,y=point.y+dy/length*.1}or point
   local hit=p:contact(origin,to)
   if hit then local key=hit.enemy or p.boss;if not seen[key]then seen[key]=true;contacts[#contacts+1]=hit end end
  end
  for _,hit in ipairs(contacts)do
   p.serial=p.serial+1;local id='yingzhao-wind-'..p.serial
   local e=p:apply(hit,id,'wuyun',{id='wind',armorDamage=0,healthDamage=12},log.step)
   p.armor:expire(id)
   if e then magic.windHits=magic.windHits+1;log.hits=(log.hits or 0)+1 end
  end
 end
end
return M
