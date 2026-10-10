-- Tutorial battle locomotion: nearest enemy within 800, half-speed backstep.
local D=require('Dora');local A=require('CombatAnimation');local K=require('Combat.Displacement')
local M={range=800}
local states=setmetatable({},{__mode="k"})
local function target(u,b)
 local nearest,distance
 local function consider(v,hp)
  if not v or v==u or not v.parent or v.visible==false or v.opacity<=.1 or (hp and hp<=0) or not D.Platformer.Data:isEnemy(u.group,v.group)then return end
  local dx,dy=v.x-u.x,v.y-u.y;local d=dx*dx+dy*dy
  if d<=M.range*M.range and (not distance or d<distance)then nearest=v;distance=d end
 end
 for _,e in ipairs(b.enemies or {})do if not e.untargetable then consider(e.enemy or e.unit,e.enemyHP or e.hp)end end
 if not b.enemies and b.arena then consider(b.arena.enemy,b.arena.enemyHP)end
 if b.npc then consider(b.npc,b.npcHP)end
 if b.enemies==nil and b.mentorTarget then consider(b.mentorTarget())end
 return nearest
end
-- Shared range/visibility selection for battle regroup locomotion.
M.target=target
local function update(u,m,moving)
 local b=m.battle[1];if not b or b.closed or b.phase~='playing' or K.blocked(u)then return end
 local enemy=target(u,b);local direction=m.direction or (u.faceRight and 1 or -1)
 local aiming=b.mentorAim and (b.mentorAim.held or b.mentorAim.shot)
 if not aiming then if enemy then u.faceRight=enemy.x>=u.x elseif moving then u.faceRight=direction>0 end end
 if moving then
  local backward=enemy and ((direction>0)~=u.faceRight)
  local clip=backward and 'bmove' or 'fmove'
  if u.playable.current~=clip then A.play(u,clip,true)end
  u.velocityX=direction*m.speed*(backward and .5 or 1)
 end
end
function M.register(name,speed)
 D.Platformer.UnitAction:add(name,{priority=1,reaction=0,recovery=.2,
 available=function(u)local m=states[u];local b=m and m.battle[1];return b and b.phase=='playing' and not b.closed and not K.blocked(u) and u.onSurface end,
 create=function(u)local m=states[u];update(u,m,true);return function(v)update(v,m,true);return not v.onSurface end end,
 stop=function(u)u.velocityX=0;A.rest(u)end})
end
function M.attach(u,b,name,speed)
 local m={battle=setmetatable({b},{__mode='v'}),name=name,speed=speed};states[u]=m
 local n=D.Node();n:addTo(u);n:schedule(function()
  if not u:isDoing(name) and (u.playable.current=='idle' or u.playable.current=='prepare') and not (b.mentorAim and (b.mentorAim.held or b.mentorAim.shot)) then update(u,m,false)end
  return false
 end)
end
function M.command(u,direction)
 local m=assert(states[u]);m.direction=direction=='right' and 1 or -1
 if u:isDoing(m.name)then return true end
 return u:start(m.name)
end
return M
