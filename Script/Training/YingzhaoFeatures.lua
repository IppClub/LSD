-- Dedicated decision-time observations; never reuse the flower/legacy schema.
-- Schema 13 adds visible mentor direction and distance for team coordination.
-- All earlier models retain their field order and explicit unknown projection.
local D=require('Dora');local F={version=13,partSetVersion=1}
F.parts={'head','torso','flank','arms','forelegs','hindlegs'}
F.names={'health','target','targetArmor','targetDistance','bossDistance','bossAction','threat','summons','facing','kineticAmmo','empAmmo','bladeAmmo'}
local categories={health='fallen danger wounded healthy',target='none boss summon',targetArmor='unknown unarmored',targetDistance='unknown near mid far',bossDistance='unknown near mid far',bossAction='hidden idle punch massive hunt wave hero hit lose',threat='none wave rear melee',summons='none one multiple',facing='unknown toward away',kineticAmmo='unknown unequipped empty low ready',empAmmo='unknown unequipped empty low ready',bladeAmmo='unknown unequipped empty low ready'}
for _,id in ipairs(F.parts)do local name='part_'..id;F.names[#F.names+1]=name;categories[name]='unknown armored exposed'end
local legacy={};for i,name in ipairs(F.names)do legacy[i]=name end
F.names[#F.names+1]='targetBossSide';categories.targetBossSide='unknown same opposite overlap'
local v2={};for i,name in ipairs(F.names)do v2[i]=name end
F.names[#F.names+1]='waveReach';categories.waveReach='unknown clear approaching'
local v3={};for i,name in ipairs(F.names)do v3[i]=name end
F.names[#F.names+1]='arenaEdge';categories.arenaEdge='unknown left right none'
local v4={};for i,name in ipairs(F.names)do v4[i]=name end
F.aimParts={'head','torso','flank','arms','forelegs','hindlegs','summon'}
for _,id in ipairs(F.aimParts)do local name='aim_'..id;F.names[#F.names+1]=name;categories[name]='unknown reachable blocked'end
local v5={};for i,name in ipairs(F.names)do v5[i]=name end
local Skill=require('Training.YingzhaoSkillFeatures')
for _,name in ipairs(Skill.names)do F.names[#F.names+1]=name;categories[name]=Skill.categories[name]end
local v6={};for i,name in ipairs(F.names)do v6[i]=name end
local Timing=require('Training.YingzhaoTiming')
F.names[#F.names+1]='bossWindow';categories.bossWindow='unknown idle early imminent recovery'
local v7={};for i,name in ipairs(F.names)do v7[i]=name end
F.names[#F.names+1]='bossImpactLead';categories.bossImpactLead='unknown idle ahead near urgent recovery'
local v8={};for i,name in ipairs(F.names)do v8[i]=name end
F.names[#F.names+1]='shieldState';categories.shieldState='unknown absent stopped outside empty covered'
F.names[#F.names+1]='shieldCharge';categories.shieldCharge='unknown empty low ready'
local v9={};for i,name in ipairs(F.names)do v9[i]=name end
local Support=require('Training.YingzhaoSupportFeatures')
for _,name in ipairs(Support.names)do F.names[#F.names+1]=name;categories[name]=Support.categories[name]end
local v10={};for i,name in ipairs(F.names)do v10[i]=name end
local Melee=require('Training.YingzhaoMeleeFeatures')
for _,name in ipairs(Melee.names)do F.names[#F.names+1]=name;categories[name]=Melee.categories[name]end
local v11={};for i,name in ipairs(F.names)do v11[i]=name end
local Range=require('Training.YingzhaoRangeFeatures')
for _,name in ipairs(Range.names)do F.names[#F.names+1]=name;categories[name]=Range.categories[name]end
local v12={};for i,name in ipairs(F.names)do v12[i]=name end
local Coordination=require('Training.YingzhaoCoordinationFeatures')
for _,name in ipairs(Coordination.names)do F.names[#F.names+1]=name;categories[name]=Coordination.categories[name]end
function F.fields(version)if version==1 then return legacy elseif version==2 then return v2 elseif version==3 then return v3 elseif version==4 then return v4 elseif version==5 then return v5 elseif version==6 then return v6 elseif version==7 then return v7 elseif version==8 then return v8 elseif version==9 then return v9 elseif version==10 then return v10 elseif version==11 then return v11 elseif version==12 then return v12 elseif version==13 then return F.names end end
local function edge(x,minX,maxX)
 if minX==nil or maxX==nil then return 'unknown'end
 if x<=minX+80 then return 'left'elseif x>=maxX-80 then return 'right'end
 return 'none'
end
F.categories=categories
local function side(own,target,boss)
 if target==nil or boss==nil then return 'unknown'end
 local a,c=target-own,boss-own
 if a==0 or c==0 then return 'overlap'end
 return a*c>0 and 'same'or'opposite'
end
local timeline=require('Enemy.BigYingzhaoTimeline')
local function band(x)return x<=350 and'near'or x<=700 and'mid'or'far'end
function F.capture(b,owner,known,knownSummons)
 local boss=b.bossCombat.boss;local visible=b.bossCombat.armor:available();local target=b:target(owner)
 if target==boss and not visible then target=nil end
 local actor=owner==b.mentor and'mentor'or owner.data.supplyActorId;local hp=b.mentorHP
 if actor~='mentor'then for _,a in ipairs(b.learners)do if a.student==owner then hp=a.studentHP;break end end end
 -- Freeze knowledge before stamping the observation, then derive every
 -- armor label from that same snapshot rather than the live hit callbacks.
 local armorSnapshot=D.json.decode(D.json.encode(known),32)
 local s={at=D.App.runningTime,featureSchemaVersion=F.version,partSetVersion=F.partSetVersion,enemyAsset='dayingzhao',bossVisible=visible,ownX=owner.x,ownHP=hp,knownArmor=armorSnapshot,health=hp<=0 and'fallen'or hp<=30 and'danger'or hp<=70 and'wounded'or'healthy',target=not target and'none'or target==boss and'boss'or'summon',targetArmor='unknown',targetDistance='unknown',bossDistance='unknown',bossAction='hidden',threat='none',summons='none',facing='unknown',kineticAmmo='unknown',empAmmo='unknown',bladeAmmo='unknown'}
 if target then
  s.targetX=target.enemy.x;local dx=target.enemy.x-owner.x;s.targetDistance=band(math.abs(dx));s.facing=(dx>=0)==owner.faceRight and'toward'or'away'
  if target~=boss then local id=b.bossCombat.targetIds[target];if id and knownSummons[id]then s.targetArmor='unarmored'end end
 end
 local count=0
 for _,e in ipairs(b.enemies)do if e~=boss and e.enemyHP>0 and e.enemy.visible and e.enemy.opacity>.1 then count=count+1 end end
 s.summons=count==0 and'none'or count==1 and'one'or'multiple'
 local guard=boss.guard
 if visible then
  s.bossX=boss.enemy.x;s.distance=math.abs(s.bossX-owner.x);s.bossDistance=band(s.distance)
  local clip=boss.enemy.playable.current
  s.bossAction=({punch=true,massive=true,hunt=true,wave=true,hit=true,lose=true})[clip]and clip or (clip=='hero'or clip=='hero2'or clip=='hero3')and'hero'or'idle'
  -- The visible advancing combo threatens its whole forward travel corridor.
  -- Use the authored maximum travel, without predicting hidden target choices.
  local motion=timeline.massiveMotion
  local reach=s.bossAction=='massive'and timeline.meleeReach+motion.speed*(motion.finish-motion.start)or 500
  if (s.bossAction=='punch'or s.bossAction=='massive')and (owner.x-boss.enemy.x)*(guard.direction or 1)>=0 and s.distance<=reach then s.threat='melee'end
  if s.bossAction=='wave'and(owner.x-boss.enemy.x)*(guard.direction or 1)>=0 then s.threat='wave'end
 end
 -- Read the visible route cue, not the invisible Boss position.
 local hero=guard.hero
 if hero and not hero.closed and hero.warning.parent and hero.warning.visible then
  local start=hero.destination.x;local finish=start+hero.destination.direction*1000
  if owner.x>=math.min(start,finish)-80 and owner.x<=math.max(start,finish)+80 then s.threat='rear'end
 end
 for _,w in ipairs(guard.waves)do if w.active and w.visual.parent and w.visual.visible and (owner.x-w.x)*w.direction>=0 and math.abs(owner.x-w.x)<=700 then s.threat='wave'end end
 for _,id in ipairs(F.parts)do local p=s.knownArmor[id];s['part_'..id]=not p and'unknown'or p.ap<=0 and'exposed'or'armored'end
 if b.supplies then
  s.resources=b.supplies:observation(actor);local resource=assert(require('Training.ResourceFeatures').project(s))
  for _,key in ipairs({'kineticAmmo','empAmmo','bladeAmmo'})do s[key]=resource[key]end
 end
 s.arenaMinX=b.minX;s.arenaMaxX=b.maxX;s.arenaEdge=edge(owner.x,b.minX,b.maxX)
 s.waveReach=require('Enemy.GroundWave').escapeDirection(guard,owner,visible)and'approaching'or'clear'
 s.targetBossSide=side(s.ownX,s.targetX,s.bossX)
 local aim=require('Training.YingzhaoActions')
 if F.version>=5 then for _,id in ipairs(F.aimParts)do
  -- Geometry only: ammunition, cooldown and forced movement are separate facts.
  s['aim_'..id]=b.phase~='playing'and'unknown'or(aim.plan(b,{student=owner},id)and'reachable'or'blocked')
 end end
 s.bossTiming,s.bossWindow=Timing.capture(guard,visible,s.at)
 s.bossImpactLead=Timing.impactLead(s)
 local Shield=require('Ground.PhysicalShield')
 s.physicalProtection=Shield.observe(b.physicalShield,owner.x,owner.y-b.world.offset)
 local shield=assert(Shield.project(s.physicalProtection));s.shieldState=shield.shieldState;s.shieldCharge=shield.shieldCharge
 s.supportState=Support.observe(b.support)
 local support=assert(Support.project(s.supportState));for _,name in ipairs(Support.names)do s[name]=support[name]end
 local raw,skills=Skill.capture(b,owner,s.targetX,s.at);s.skillControl=raw
 for _,name in ipairs(Skill.names)do s[name]=skills and skills[name]or'unknown'end
 s.meleeProbe=Melee.capture(b,owner,target)
 s.meleeReach=assert(Melee.project(s.meleeProbe)).meleeReach
 s.ownY=owner.y
 if visible then s.bossY=boss.enemy.y;s.bossFaceRight=boss.enemy.faceRight end
 s.bossRange=Range.capture(owner,boss.enemy,visible)
 s.bossFrontRange=assert(Range.project(s.bossRange)).bossFrontRange
 local coordination,values=Coordination.capture(b,owner);s.coordination=coordination
 for _,name in ipairs(Coordination.names)do s[name]=values[name]end
 return s
end
function F.validate(s)
 if type(s)~='table'or not F.fields(s.featureSchemaVersion) or s.partSetVersion~=1 or s.enemyAsset~='dayingzhao'or type(s.bossVisible)~='boolean'then return false end
 local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
 if not finite(s.ownX)or not finite(s.ownHP)or s.ownHP<0 or not finite(s.at)or type(s.knownArmor)~='table'then return false end
 if s.bossVisible and (not finite(s.bossX)or not finite(s.distance)or math.abs(s.distance-math.abs(s.bossX-s.ownX))>1e-6 or s.bossDistance~=band(s.distance))then return false end
 for _,id in ipairs(F.parts)do local p=s.knownArmor[id];if p and (type(p)~='table'or not finite(p.ap)or p.ap<0 or not finite(p.observedAt)or p.observedAt>s.at)then return false end
  if s['part_'..id]~=(not p and'unknown'or p.ap<=0 and'exposed'or'armored')then return false end
 end
 for _,name in ipairs(F.fields(s.featureSchemaVersion))do local value=s[name];if type(value)~='string'or value:find('%s')or not (' '..categories[name]..' '):find(' '..value..' ',1,true)then return false end end
 if s.featureSchemaVersion>=2 then
  if s.target=='none'then if s.targetX~=nil then return false end
  elseif not finite(s.targetX)or s.targetDistance~=band(math.abs(s.targetX-s.ownX))then return false end
  if s.target=='boss'and s.targetX~=s.bossX then return false end
  if s.targetBossSide~=side(s.ownX,s.targetX,s.bossX)then return false end
 end
 if s.featureSchemaVersion>=4 then
  if s.arenaMinX~=nil or s.arenaMaxX~=nil then
   if not finite(s.arenaMinX)or not finite(s.arenaMaxX)or s.arenaMaxX<=s.arenaMinX then return false end
  end
  if s.arenaEdge~=edge(s.ownX,s.arenaMinX,s.arenaMaxX)then return false end
 end
 if s.featureSchemaVersion>=5 and not s.bossVisible then
  for _,id in ipairs(F.parts)do if s['aim_'..id]=='reachable'then return false end end
 end
 if s.featureSchemaVersion>=6 and not Skill.validate(s)then return false end
 if s.featureSchemaVersion>=7 and not Timing.validate(s)then return false end
 if s.featureSchemaVersion>=8 and Timing.impactLead(s)~=s.bossImpactLead then return false end
 if s.featureSchemaVersion>=9 then
  local shield=require('Ground.PhysicalShield').project(s.physicalProtection)
  if not shield or s.physicalProtection.present and s.physicalProtection.ownX~=s.ownX or shield.shieldState~=s.shieldState or shield.shieldCharge~=s.shieldCharge then return false end
 end
 if s.featureSchemaVersion>=10 then
  local support=Support.project(s.supportState);if not support then return false end
  for _,name in ipairs(Support.names)do if s[name]~=support[name]then return false end end
 end
 if s.featureSchemaVersion>=11 and not Melee.validate(s)then return false end
 if s.featureSchemaVersion>=12 and not Range.validate(s)then return false end
 if s.featureSchemaVersion>=13 and not Coordination.validate(s)then return false end
 local health=s.ownHP<=0 and'fallen'or s.ownHP<=30 and'danger'or s.ownHP<=70 and'wounded'or'healthy'
 if s.health~=health then return false end
 local resource=s.resources and require('Training.ResourceFeatures').project(s)
 if s.resources and not resource then return false end
 for _,key in ipairs({'kineticAmmo','empAmmo','bladeAmmo'})do if s[key]~=(resource and resource[key]or'unknown')then return false end end
 if not s.bossVisible and (s.bossX~=nil or s.distance~=nil or s.bossDistance~='unknown'or s.bossAction~='hidden')then return false end
 return true
end
function F.project(s,version)
 version=version or F.version
 local fields=F.fields(version);if not fields then return nil,'INVALID_FEATURE_VERSION'end
 if not F.validate(s)then return nil,'INVALID_YINGZHAO_OBSERVATION'end
 local state={};for _,name in ipairs(fields)do state[name]=(name=='targetBossSide'and s.featureSchemaVersion==1 or name=='waveReach'and s.featureSchemaVersion<3 or name=='arenaEdge'and s.featureSchemaVersion<4 or name:match('^aim_')and s.featureSchemaVersion<5 or Skill.categories[name]and s.featureSchemaVersion<6 or name=='bossWindow'and s.featureSchemaVersion<7 or name=='bossImpactLead'and s.featureSchemaVersion<8 or (name=='shieldState'or name=='shieldCharge')and s.featureSchemaVersion<9 or Support.categories[name]and s.featureSchemaVersion<10 or Melee.categories[name]and s.featureSchemaVersion<11 or Range.categories[name]and s.featureSchemaVersion<12 or Coordination.categories[name]and s.featureSchemaVersion<13)and'unknown'or s[name]end
 return state
end
function F.key(s,version)
 local state,why=F.project(s,version);if not state then return nil,why end
 local values={};for _,name in ipairs(F.fields(version or F.version))do values[#values+1]=state[name]end;return table.concat(values,'|')
end
return F
