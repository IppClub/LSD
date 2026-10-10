-- Shared authoritative HP/AP resolution. Geometry must supply the actual part;
-- this module never selects a target or assumes the intended aim was a hit.
local Damage={};Damage.__index=Damage
local function number(n)return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function id(s)return type(s)=='string' and #s>0 end
local function point(p)return type(p)=='table' and type(p.x)=='number' and type(p.y)=='number' and p.x==p.x and p.y==p.y and math.abs(p.x)<math.huge and math.abs(p.y)<math.huge end
function Damage.new(config)
 assert(id(config.id) and number(config.maxHP) and config.maxHP>0,'Invalid target')
 local parts={}
 for name,p in pairs(config.parts)do
  assert(id(name) and number(p.maxAP) and number(p.armoredMultiplier) and number(p.exposedMultiplier),'Invalid part')
  assert(p.armoredResponse=='stop' or p.armoredResponse=='reflect','Invalid armor response')
  parts[name]={ap=p.maxAP,maxAP=p.maxAP,armoredMultiplier=p.armoredMultiplier,exposedMultiplier=p.exposedMultiplier,armoredResponse=p.armoredResponse}
 end
 assert(next(parts),'Missing parts')
 return setmetatable({id=config.id,hp=config.maxHP,maxHP=config.maxHP,parts=parts,attacks={},closed=false},Damage)
end
-- One attack token per projectile or authored strike. Finish only after every
-- associated projectile expires; a later callback cannot reopen that token.
function Damage:beginAttack(token)
 if self.closed or not id(token) or self.attacks[token]~=nil then return false end
 self.attacks[token]={};return true
end
function Damage:finishAttack(token)
 if not self.attacks[token] then return false end
 self.attacks[token]=false;return true
end
function Damage:hit(c,w)
 if self.closed then return nil,'CLOSED' end
 local hits=self.attacks[c.attackId]
 if type(hits)~='table' then return nil,'INACTIVE_ATTACK' end
 if not id(c.hitId) or hits[c.hitId] then return nil,'INVALID_OR_DUPLICATE_HIT' end
 local p=self.parts[c.part]
 if not p or not point(c.position) or not point(c.normal) or not id(c.source) then return nil,'INVALID_CONTACT' end
 if not id(w.id) or not number(w.armorDamage) or not number(w.healthDamage) then return nil,'INVALID_WEAPON' end
 if self.hp<=0 then return nil,'DEAD' end
 local beforeHP,beforeAP=self.hp,p.ap
 -- A hit that breaks armor still resolves HP against the pre-hit armor.
 -- The next contact can exploit the exposed part; no global stun is implied.
 local armored=beforeAP>0
 p.ap=math.max(0,p.ap-w.armorDamage)
 self.hp=math.max(0,self.hp-w.healthDamage*(armored and p.armoredMultiplier or p.exposedMultiplier))
 hits[c.hitId]=true
 return {schemaVersion=1,attackId=c.attackId,hitId=c.hitId,source=c.source,target=self.id,part=c.part,weapon=w.id,
  position={x=c.position.x,y=c.position.y},normal={x=c.normal.x,y=c.normal.y},
  hpBefore=beforeHP,hpAfter=self.hp,apBefore=beforeAP,apAfter=p.ap,
  healthDamage=beforeHP-self.hp,armorDamage=beforeAP-p.ap,
  armorBroken=beforeAP>0 and p.ap==0,killed=beforeHP>0 and self.hp==0,
  response=armored and p.armoredResponse or 'stop'}
end
function Damage:close()
 self.closed=true;self.attacks={}
end
return Damage
