-- Non-training mission archive. Replay regional HP/AP and compare resource ledger
-- in Mission.Service's atomic settlement; no legacy learner adoption allowed.
local M={}
local function validate(e,mode)
 if type(e)~='table'or e.schemaVersion~=1 or e.closed~=true or e.trainable~=false or type(e.versions)~='table'or e.versions.bigYingzhao~=1 or e.versions.resources~=1 then return false,'INVALID_BOSS_EPISODE'end
 local t=e.boss
 if type(t)~='table'or t.schemaVersion~=1 or t.closed~=true or t.trainable~=false or t.truncated or not ({won=true,failed=true,aborted=true})[t.status]then return false,'INVALID_BOSS_TRACE'end
 if not require('Training.ResourceEvidence').validate(e.resources)or e.resources.mode~=mode or e.episode~=e.resources.attempt or not require('Training.FlowerIdentity').equal(e.resources,t.resources)then return false,'INVALID_BOSS_RESOURCES'end
 if type(t.steps)~='table'or #t.steps>1500 or type(t.hits)~='table'or #t.hits>1500 or type(t.encounter)~='table'or t.encounter.maxHP~=1000 then return false,'INVALID_BOSS_ENCOUNTER'end
 local parts={};for id,ap in pairs({head=35,torso=105,flank=140,arms=70,forelegs=70,hindlegs=70})do parts[id]={maxAP=ap,armoredMultiplier=.15,exposedMultiplier=id=='head'and 1.5 or 1,armoredResponse='stop'}end
 local damage=require('Combat.Damage').new({id='big-yingzhao',maxHP=1000,parts=parts})
 local profiles={kinetic={id='kinetic',armorDamage=0,healthDamage=15},emp={id='emp',armorDamage=35,healthDamage=0},blade={id='blade',armorDamage=35,healthDamage=20},fire={id='fire',armorDamage=0,healthDamage=12},['wind-fire']={id='wind-fire',armorDamage=0,healthDamage=18},wind={id='wind',armorDamage=0,healthDamage=12}}
 if t.skillTimeVersion~=nil and t.skillTimeVersion~=1 then return false,'INVALID_SKILL_TIME_VERSION'end
 for index,step in ipairs(t.steps)do
  if type(step)~='table'or type(step.actor)~='string'or type(step.before)~='table'then return false,'INVALID_BOSS_STEP'end
  if step.action=='wind'or step.action=='fire'then
   if t.skillTimeVersion~=1 or not require('Enemy.YingzhaoSkillEvidence').step(step,index)then return false,'INVALID_SKILL_STEP'end
  elseif step.skill~=nil then return false,'INVALID_SKILL_STEP'end
  local aimOK,aimWhy=require('Training.YingzhaoActions').validateStep(step);if not aimOK then return false,aimWhy end
  if t.physicalShieldVersion==1 and (step.before.featureSchemaVersion<9 or not step.before.physicalProtection or not step.before.physicalProtection.present)then return false,'MISSING_SHIELD_OBSERVATION'end
  if t.observationVersion~=nil then
   if t.observationVersion~=1 or not require('Training.YingzhaoFeatures').validate(step.before)or (step.after and not require('Training.YingzhaoFeatures').validate(step.after))then return false,'INVALID_BOSS_OBSERVATION'end
  end
 end
 if t.vitals~=nil and not require('Training.YingzhaoVitals').validate(t.vitals)then return false,'INVALID_BOSS_VITALS'end
 if t.physicalShieldVersion~=nil or t.physicalShield~=nil then
  if t.physicalShieldVersion~=1 or not require('Ground.PhysicalShield').validate(t.physicalShield,t.vitals)then return false,'INVALID_PHYSICAL_SHIELD'end
 end
 if t.supportAccountingVersion~=nil or t.supportAccounting~=nil then
  if t.supportAccountingVersion~=1 or t.supportAccountingError then return false,'INVALID_SUPPORT_ACCOUNT'end
  local ok,why=require('Training.YingzhaoSupportAccounting').validate(t.supportAccounting,t.physicalShield)
  if not ok then return false,why end
 end
 local paid={}
 for _,event in pairs(e.resources.events)do
  local step=event.step and t.steps[event.step]
  if not step or step.actor~=event.performer or step.actor~=event.owner or not ({shoot=true,melee=true})[step.action]then return false,'BOSS_COST_SOURCE_MISMATCH'end
  local expected=step.action=='melee'and'blade'or step.actor=='mentor'and'kinetic'or'emp'
  if event.item~=expected then return false,'BOSS_COST_WEAPON_MISMATCH'end
  paid[event.step]=(paid[event.step]or 0)+event.count
 end
 if t.hitTimeVersion~=nil and t.hitTimeVersion~=1 then return false,'INVALID_HIT_TIME_VERSION'end
 local lastHit=-math.huge
 local used={}
 local seen={};local summonHP={};local skillHits={}
 for _,h in ipairs(t.hits)do
  if type(h)~='table'or type(h.attackId)~='string'or seen[h.attackId]or not profiles[h.weapon]then return false,'INVALID_BOSS_HIT'end
  if t.hitTimeVersion==1 then
   if type(h.at)~='number'or h.at~=h.at or math.abs(h.at)==math.huge or h.at<lastHit or (t.vitals and (h.at<t.vitals.started or h.at>t.vitals.finished))then return false,'INVALID_HIT_TIME'end
   lastHit=h.at
  end
  if t.skillTimeVersion==1 and (h.weapon=='wind'or h.weapon=='fire'or h.weapon=='wind-fire')and not require('Enemy.YingzhaoSkillEvidence').hit(h,t.steps,skillHits)then return false,'SKILL_HIT_SOURCE_MISMATCH'end
  seen[h.attackId]=true
  if h.weapon=='kinetic'or h.weapon=='emp'or h.weapon=='blade'then
   local step=h.step and t.steps[h.step]
   if not step or step.actor~=h.source or not paid[h.step]then return false,'UNPAID_BOSS_HIT'end
   used[h.step]=(used[h.step]or 0)+1;if used[h.step]>paid[h.step]then return false,'DUPLICATE_PAID_HIT'end
   local expected=step.action=='melee'and'blade'or step.actor=='mentor'and'kinetic'or'emp'
   if h.weapon~=expected then return false,'BOSS_HIT_WEAPON_MISMATCH'end
  end
  if h.target=='big-yingzhao'then
   damage:beginAttack(h.attackId)
   local v=damage:hit({attackId=h.attackId,hitId=h.hitId,part=h.part,position=h.position,normal=h.normal,source=h.source},profiles[h.weapon])
   if not v then return false,'INVALID_BOSS_CONTACT'end
   for _,key in ipairs({'hpBefore','hpAfter','apBefore','apAfter','healthDamage','armorDamage'})do if type(h[key])~='number'or h[key]~=h[key]or math.abs(v[key]-h[key])>1e-6 then return false,'BOSS_DAMAGE_MISMATCH'end end
   if v.killed~=h.killed or v.armorBroken~=h.armorBroken then return false,'BOSS_DAMAGE_MISMATCH'end
  elseif h.summoned~=true then return false,'UNKNOWN_BOSS_TARGET'
  else
   if type(h.target)~='string'or h.part~='body'then return false,'INVALID_SUMMON_HIT'end
   local hp=summonHP[h.target]or 70;local after=math.max(0,hp-profiles[h.weapon].healthDamage)
   if h.hpBefore~=hp or h.hpAfter~=after or h.healthDamage~=hp-after or h.armorDamage~=0 or h.apBefore~=0 or h.apAfter~=0 or h.armorBroken~=false or h.killed~=(after==0)then return false,'SUMMON_DAMAGE_MISMATCH'end
   summonHP[h.target]=after
  end
 end
 if not require('Enemy.BigYingzhaoFlightEvidence').validate(t)then return false,'INVALID_BOSS_FLIGHT'end
 if type(t.encounter.hp)~='number'or t.encounter.hp~=t.encounter.hp or math.abs(damage.hp-t.encounter.hp)>1e-6 or (t.status=='won'and (damage.hp~=0 or t.encounter.defeated~=true))then return false,'UNFINISHED_BOSS'end
 return true
end
function M.validate(e)return validate(e,'mission')end
function M.validateVirtual(e)
 if type(e)~='table'or e.kind~='big-yingzhao-demonstration'or (e.demonstrator~='ninilite'and e.demonstrator~='wuyun')then return false,'INVALID_BOSS_DEMONSTRATION'end
 local ok,why=validate(e,'virtual');if not ok then return false,why end
 for _,step in ipairs(e.boss.steps)do if step.origin=='demo'and step.actor~=e.demonstrator then return false,'BOSS_DEMONSTRATOR_MISMATCH'end end
 return true
end
function M.validateEvaluation(e)
 if type(e)~='table'or e.kind~='big-yingzhao-evaluation'then return false,'INVALID_EVALUATION'end
 return validate(e,'virtual')
end
return M
