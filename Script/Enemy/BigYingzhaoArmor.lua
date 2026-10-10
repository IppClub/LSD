-- Candidate regional armor rules. Hosts own projectile travel/terrain ordering,
-- resource charging and training records; only real contacts call apply.
local D=require('Dora');local Armor={};Armor.__index=Armor
Armor.partNames={head='头部',torso='躯干',flank='侧腹',arms='双臂',forelegs='前腿',hindlegs='后腿'}
function Armor.new(record,world,onHit)
 local self=setmetatable({record=record,world=world},Armor)
 local parts={}
 for id,ap in pairs({head=35,torso=105,flank=140,arms=70,forelegs=70,hindlegs=70})do
  parts[id]={maxAP=ap,armoredMultiplier=.15,exposedMultiplier=id=='head'and require('Enemy.BigYingzhaoRules').headMultiplier or 1,armoredResponse='stop'}
 end
 self.target=require('Combat.PartTarget').new(record.enemy.playable,D.json.decode(D.Content:load('Data/Combat/big-yingzhao-regions.json')),world,{id='big-yingzhao',maxHP=record.enemyHP,parts=parts},function(e)
  record.enemyHP=e.hpAfter
  if onHit then onHit(e)end
 end)
 record.enemy:slot('Cleanup',function()self:close()end)
 return self
end
function Armor:available()
 local u=self.record.enemy
 return not self.closed and self.record.enemyHP>0 and u.visible and u.opacity>.1 and u.playable.visible
end
function Armor:sample()
 if not self:available()then self.previous=nil;self.target.regions={};return end
 local flip=self.target.model.fliped
 self.previous=self.flip==flip and #self.target.regions>0 and self.target.regions or nil
 self.flip=flip
 self.target:sample()
end
function Armor:probe(from,to)
 if not self:available()then return end
 return self.target:probeMoving(from,to,self.previous or self.target.regions)
end
function Armor:apply(contact,shot)
 if not self:available()then return nil,'TARGET_UNAVAILABLE'end
 return self.target:apply(contact,shot)
end
function Armor:expire(id)self.target:expire(id)end
function Armor:close()
 if self.closed then return end
 self.closed=true;self.previous=nil;self.target:close()
end
return Armor
