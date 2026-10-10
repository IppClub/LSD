-- Flower observations are separate from Taotie's feature/part-set versions.
-- Armor knowledge comes from observed hits or an explicitly revealed virtual scenario.
local F={version=6,partSetVersion=2,parts={head='flower-head',core='flower-core',left='petal-left',right='petal-right',roots='roots'}}
function F.capture(battle,owner,known)
 local boss=battle.roots[3];local target=battle:target(owner);local dx=boss.enemy.x-owner.x
 local hp,energy,cost
 if owner==battle.mentor then hp=battle.mentorHP
 else for _,a in ipairs(battle.learners)do if a.student==owner then hp=a.studentHP;energy=a.studentEnergy;cost=a.shotEnergyCost;break end end end
 assert(type(hp)=='number','Unknown flower observer')
 local function health(n)return n<=0 and 'fallen' or n<=30 and 'danger' or n<=70 and 'wounded' or 'healthy'end
 local allyHP=100
 if owner~=battle.mentor then allyHP=math.min(allyHP,battle.mentorHP)end
 for _,a in ipairs(battle.learners)do if a.student~=owner then allyHP=math.min(allyHP,a.studentHP)end end
 local support=battle.support;local field='unknown'
 if support then
  if support.gold<=0 or support.machineHP<=0 then field='inactive'
  elseif support.x and support.radius then field=math.abs(owner.x-support.x)<=support.radius and 'inside' or 'outside'end
 end
 local now=require('Dora').App.runningTime;local status=battle.effects.states[owner] or {}
 local s={health=health(hp),allyHealth=health(allyHP),energyReady=energy==nil and 'unlimited' or energy>=(cost or 12) and 'ready' or 'empty',support=field,supplies=not support and 'unknown' or support.gold<=0 and 'empty' or support.gold<=10 and 'low' or 'available',confused=now<(status.confusedUntil or 0),poisoned=now<(status.poisonUntil or 0),virus=now<(status.virusUntil or 0),featureSchemaVersion=F.version,partSetVersion=F.partSetVersion,enemyAsset='dahuayao',
  phase=boss.enemyCombat.bossPhase==2 and 'reproduction' or 'entrenched',phasePending=boss.enemyCombat.phasePending==true,
  distance=math.abs(dx)<=300 and 'near' or math.abs(dx)<=650 and 'mid' or 'far',
  facing=(dx>=0)==owner.faceRight and 'toward' or 'away',
  target=not target and 'none' or target==boss and 'boss' or target.enemyCombat.budding and 'bud' or 'flower'}
 for label,id in pairs(F.parts)do
  local p=known[id];s['part_'..label]=not p and 'unknown' or p.maxAP==0 and 'unarmored' or p.ap<=0 and 'exposed' or 'armored'
 end
 s.spatial=require('Combat.Spatial').capture(battle,owner)
 if battle.supplies then s.resources=battle.supplies:observation(assert(owner.data.supplyActorId));s.resourceFeatures=assert(require('Training.ResourceFeatures').project(s))end
 return s
end
function F.validate(s)
 if type(s)~='table' or (s.featureSchemaVersion~=5 and s.featureSchemaVersion~=6) or s.partSetVersion~=2 or s.enemyAsset~='dahuayao' then return false end
 if s.spatial~=nil and not require('Combat.Spatial').validate(s.spatial)then return false end
 if s.featureSchemaVersion==6 then
  local health={fallen=true,danger=true,wounded=true,healthy=true}
  if not health[s.health] or not health[s.allyHealth] or not ({unlimited=true,ready=true,empty=true})[s.energyReady] or not ({unknown=true,inactive=true,inside=true,outside=true})[s.support] or not ({unknown=true,empty=true,low=true,available=true})[s.supplies] then return false end
 end
 if type(s.confused)~='boolean' or type(s.poisoned)~='boolean' or type(s.virus)~='boolean' then return false end
 if s.phase~='entrenched' and s.phase~='reproduction' then return false end
 if type(s.phasePending)~='boolean' or not ({near=true,mid=true,far=true})[s.distance] or not ({toward=true,away=true})[s.facing] or not ({none=true,boss=true,bud=true,flower=true})[s.target] then return false end
 for label in pairs(F.parts)do if not ({unknown=true,unarmored=true,exposed=true,armored=true})[s['part_'..label]]then return false end end
 return true
end
return F
