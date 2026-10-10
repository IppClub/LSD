-- Adapter joining animated geometry and authoritative damage. The projectile
-- host owns terrain, travel, reflections and lifetime; no nearest-enemy aim here.
local Regions=require('Combat.SpineRegions')
local Geometry=require('Combat.HitGeometry')
local Damage=require('Combat.Damage')
local Target={};Target.__index=Target
function Target.new(model,manifest,space,stats,onHit)
 local self=setmetatable({model=model,manifest=manifest,space=space,damage=Damage.new(stats),onHit=onHit,closed=false},Target)
 self:sample();return self
end
function Target:sample()
 if self.closed then return end
 self.regions=Regions.sample(self.model,self.manifest,self.space)
end
function Target:probe(from,to)
 if self.closed or self.damage.hp<=0 or not self.model.visible then return nil end
 return Geometry.nearest(from,to,self.regions)
end
function Target:probeMoving(from,to,previous)
 if self.closed or self.damage.hp<=0 or not self.model.visible then return nil end
 return require('Combat.MovingHit').nearest(from,to,previous,self.regions)
end
function Target:apply(contact,shot)
 if self.closed then return nil,'CLOSED' end
 if self.damage.attacks[shot.id]==nil then self.damage:beginAttack(shot.id)end
 local event,err=self.damage:hit({attackId=shot.id,hitId=shot.contactId,source=shot.source,
  part=contact.part,position=contact.position,normal=contact.normal},shot.weapon)
 if event and self.onHit then self.onHit(event)end
 return event,err
end
function Target:expire(shotId)self.damage:finishAttack(shotId)end
function Target:close()self.closed=true;self.regions={};self.damage:close()end
return Target
