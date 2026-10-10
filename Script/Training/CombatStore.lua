-- Episode rows are committed in the mission-result transaction, never separately.
local D=require('Dora');local Store={maxBytes=2097152}
function Store.validate(e)
 if type(e)=='table'and type(e.versions)=='table'and e.versions.bigYingzhao~=nil then return require('Enemy.BigYingzhaoEvidence').validate(e)end
 if type(e)=='table'and type(e.versions)=='table'and e.versions.disarm~=nil then return require('Training.DisarmMissionEvidence').validate(e)end
 if type(e)~='table' or e.schemaVersion~=1 or e.closed~=true or type(e.episode)~='string' or e.episode=='' or type(e.versions)~='table' then return false,'INVALID_EPISODE' end
 if e.versions.resources~=nil or e.resources~=nil or e.versions.resourceSimulation~=nil then
  local E=require('Training.ResourceEvidence')
  if e.versions.resources~=1 or not E.validate(e.resources)then return false,'INVALID_RESOURCE_EVIDENCE'end
  if e.resources.mode=='virtual' then
   if e.versions.resourceSimulation~=1 then return false,'INVALID_RESOURCE_SIMULATION'end
  elseif e.versions.resourceSimulation~=nil then return false,'INVALID_RESOURCE_SIMULATION'end
  if e.resourceCosts~=nil or e.versions.resourceAttribution~=nil then
   if e.versions.resourceAttribution~=1 or e.resourceCosts==nil then return false,'INVALID_RESOURCE_ATTRIBUTION'end
   local costs=E.attribute(e.resources,e.steps)
   if not costs or not require('Training.FlowerIdentity').equal(costs,e.resourceCosts)then return false,'INVALID_RESOURCE_ATTRIBUTION'end
  end
  for _,step in ipairs(e.steps or {})do
   if type(step)~='table' or type(step.observation)~='table' or not E.observation(step.observation.resources) or (step.nextObservation and (type(step.nextObservation)~='table' or not E.observation(step.nextObservation.resources)))then return false,'INVALID_RESOURCE_OBSERVATION'end
   for _,obs in ipairs({step.observation,step.nextObservation})do
    local resource=obs.resources
    if e.versions.resourceFeatures~=nil then
     if e.versions.resourceFeatures~=1 or not require('Training.FlowerIdentity').equal(require('Training.ResourceFeatures').project(obs),obs.resourceFeatures)then return false,'INVALID_RESOURCE_FEATURES'end
    end
    if not step.action or resource.actor~=step.action.actor or resource.spent<e.resources.quote.deployment or resource.spent>e.resources.spent or resource.reserved~=e.resources.quote.total then return false,'RESOURCE_OBSERVATION_MISMATCH'end
    for _,line in ipairs(e.resources.quote.lines)do
     if line.actor==resource.actor then local n=resource.ammo[line.item];if n==nil or n>line.quantity or n<e.resources.stock[line.key].remaining then return false,'RESOURCE_OBSERVATION_MISMATCH'end end
    end
   end
  end
 end
 if e.versions.spatial~=nil then
  if e.versions.spatial~=1 and e.versions.spatial~=2 then return false,'INVALID_SPATIAL_VERSION'end
  if e.movement~=nil and type(e.movement)~='table'then return false,'INVALID_MOVEMENT_EVENT'end
  local previous=-math.huge
  for _,event in ipairs(e.movement or {})do
   if not require('Combat.Spatial').eventValid(event)or event.at<previous then return false,'INVALID_MOVEMENT_EVENT'end;previous=event.at
  end
 end
 local flower=(e.versions.observation==5 or e.versions.observation==6) and (e.versions.action==3 or (e.versions.action==4 and e.versions.observation==6)) and e.versions.partSet==2 and (e.versions.contactScope=='hostile' or e.versions.contactScope=='hostile-and-virus-friendly' or (e.versions.contactScope=='all-projectile' and e.versions.weaponRules==2))
 if (not flower and (e.versions.observation~=3 or e.versions.action~=2)) or e.versions.combat~=1 or (e.versions.credit~=nil and e.versions.credit~=1 and not (flower and e.versions.credit==2 and e.versions.contactScope=='all-projectile')) then return false,'INCOMPATIBLE_EPISODE' end
 if e.versions.vitals~=nil and (not flower or e.versions.vitals~=1 or not require('Training.CombatVitals').validate(e.vitals))then return false,'INVALID_VITALS'end
 if e.versions.aim~=nil and (not flower or e.versions.aim~=1)then return false,'INCOMPATIBLE_AIM_VERSION'end
 if e.versions.clock~=nil and e.versions.clock~='simulation' then return false,'INCOMPATIBLE_CLOCK'end
 if type(e.steps)~='table' or #e.steps>1500 then return false,'INVALID_STEPS' end
 local creditEvents={};local friendlyVitals={}
 if e.versions.vitals==1 then
  for target,state in pairs(e.vitals.actors)do for _,event in ipairs(state.events)do
   if event.kind=='virus-friendly-fire' then
    if not event.attackId then return false,'MISSING_FRIENDLY_ATTACK'end
    friendlyVitals[target]=friendlyVitals[target] or {};local byAttack=friendlyVitals[target]
    if byAttack[event.attackId] then return false,'DUPLICATE_FRIENDLY_VITAL'end
    byAttack[event.attackId]={source=event.source,damage=event.hpBefore-event.hpAfter}
   end
  end end
 end
 local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
 for i,s in ipairs(e.steps)do
  if type(s)~='table' or s.id~=i or type(s.observation)~='table' or type(s.action)~='table' or type(s.action.name)~='string' or not finite(s.started) or type(s.hits)~='table' or #s.hits>256 then return false,'INVALID_STEP' end
  if e.versions.spatial then
   local spatial=require('Combat.Spatial')
   if not spatial.validate(s.observation.spatial) or s.observation.spatial.version~=e.versions.spatial or s.nextObservation and (type(s.nextObservation)~='table' or not spatial.validate(s.nextObservation.spatial) or s.nextObservation.spatial.version~=e.versions.spatial)then return false,'INVALID_SPATIAL_OBSERVATION'end
  end
  if flower then
   if s.action.energySpent~=nil and (not finite(s.action.energySpent) or s.action.energySpent<0 or s.action.name~='shoot')then return false,'INVALID_ENERGY_SPENT'end
   if s.action.emitted~=nil and (not finite(s.action.emitted) or s.action.emitted<0 or s.action.emitted%1~=0)then return false,'INVALID_EMISSION_COUNT'end
   if s.action.aimSource=='part-policy-v1' then
    local action=s.action
    if action.aimCommit~=nil and (action.aimCommit~=1 or not finite(action.aimCommittedAt) or action.aimCommittedAt>s.started or type(action.aimPoint)~='table' or not finite(action.aimPoint.x) or not finite(action.aimPoint.y) or not finite(action.aimAngle) or math.abs(action.aimAngle)>45)then return false,'INVALID_AIM_COMMIT'end
    if action.origin~='model' or action.name~='shoot' or not ({['flower-head']=true,['flower-core']=true,['petal-left']=true,['petal-right']=true,roots=true})[action.intendedPart] or ((action.emitted or 0)>0 and (not finite(action.aimAngle) or math.abs(action.aimAngle)>45))then return false,'INVALID_TARGETED_ACTION'end
   elseif s.action.aimSource~=nil then
    local action=s.action
    if action.aimSource~='manual-sweep-v1' or action.name~='shoot' or not ({demo=true,player=true})[action.origin] or not finite(action.aimAngle) or math.abs(action.aimAngle)>45 then return false,'INVALID_MANUAL_AIM'end
    if (action.emitted or 0)>0 then
     if not finite(action.aimAt) or action.aimAt<s.started or not ({boss=true,flower=true,terrain=true,miss=true,redirected=true})[action.aimStatus]then return false,'INVALID_AIM_RAY'end
     local bossPart=({['flower-head']=true,['flower-core']=true,['petal-left']=true,['petal-right']=true,roots=true})[action.intendedPart]
     if (action.aimStatus=='boss' and not bossPart) or (action.aimStatus~='boss' and action.intendedPart~='unknown')then return false,'INVALID_AIM_INTENTION'end
    end
   end
   local F=require('Training.FlowerFeatures')
   if not F.validate(s.observation) or s.observation.featureSchemaVersion~=e.versions.observation or ((s.sealed or s.nextObservation) and (not F.validate(s.nextObservation) or s.nextObservation.featureSchemaVersion~=e.versions.observation)) then return false,'INVALID_FLOWER_OBSERVATION'end
   local movement=s.action.name=='fmove' or s.action.name=='bmove' or s.action.name=='idle'
   if not ({mentor=true,ninilite=true,wuyun=true})[s.action.actor] then return false,'INVALID_FLOWER_ACTION'end
   if movement then
    if e.versions.action~=4 or s.action.weapon~='none' or #s.hits~=0 or (s.action.emitted or 0)~=0 then return false,'INVALID_MOVEMENT_ACTION'end
   elseif not ({emp=true,kinetic=true,blade=true})[s.action.weapon] or (s.action.name~='shoot' and s.action.name~='melee')then return false,'INVALID_FLOWER_ACTION'end
   if e.versions.action==4 and not ({player=true,model=true,demo=true,baseline=true,scripted=true})[s.action.origin]then return false,'INVALID_ACTION_ORIGIN'end
  end
  if s.sealed~=true and s.truncated~=true then return false,'UNFINISHED_STEP' end
  if s.sealed and (not finite(s.finished) or s.finished<s.started or s.pending~=0) then return false,'INVALID_INTERVAL' end
  local hp,ap,breaks,friendlyHP,friendlyHits=0,0,0,0,0
  for _,h in ipairs(s.hits)do
   if type(h)~='table' or type(h.attackId)~='string' or type(h.part)~='string' or not finite(h.healthDamage) or h.healthDamage<0 or not finite(h.armorDamage) or h.armorDamage<0 then return false,'INVALID_HIT' end
   if not finite(h.hpBefore) or not finite(h.hpAfter) or not finite(h.apBefore) or not finite(h.apAfter) or h.hpAfter<0 or h.apAfter<0 or math.abs(h.hpBefore-h.hpAfter-h.healthDamage)>.00001 or math.abs(h.apBefore-h.apAfter-h.armorDamage)>.00001 then return false,'INCONSISTENT_HIT' end
   if flower and e.versions.contactScope=='all-projectile' and (h.source~=s.action.actor or h.weapon~=s.action.weapon or (h.relation~='friendly' and h.relation~='hostile') or (h.weapon=='emp' and h.healthDamage~=0))then return false,'INVALID_WEAPON_OUTCOME'end
   if e.versions.credit==2 and h.relation=='hostile' then
    if type(h.credit)~='table' or h.credit.schemaVersion~=2 or not finite(h.credit.at) or not finite(h.credit.sequence) or h.credit.sequence%1~=0 or h.credit.sequence<1 then return false,'INVALID_FLOWER_CREDIT'end
    creditEvents[#creditEvents+1]=h
   end
   if e.versions.credit==1 then
    local c=h.credit
    if type(c)~='table' or c.schemaVersion~=1 or type(c.actor)~='string' or c.actor=='' or not finite(c.at) or c.at<0 or not finite(c.health) or c.health<0 or c.health>h.healthDamage or not finite(c.armor) or c.armor<0 or c.armor>h.armorDamage or (c.breaks~=0 and c.breaks~=1) or (c.breaks==1 and not h.armorBroken)then return false,'INVALID_CREDIT'end
    if c.assist then
     local a=c.assist
     if type(a)~='table' or type(a.actor)~='string' or a.actor=='' or a.actor==c.actor or type(a.attackId)~='string' or a.attackId=='' or not finite(a.health) or a.health<=0 or a.health>c.health or h.apBefore~=0 then return false,'INVALID_ASSIST'end
    end
   end
   if h.relation=='friendly' then
    if not flower or (e.versions.contactScope~='hostile-and-virus-friendly' and e.versions.contactScope~='all-projectile') or h.cause~='virus' or h.source~=s.action.actor or h.target==h.source or not ({mentor=true,ninilite=true,wuyun=true})[h.target] or h.armorDamage~=0 or h.armorBroken or h.credit~=nil then return false,'INVALID_FRIENDLY_HIT'end
    if e.versions.vitals==1 and h.healthDamage>0 then
     local byAttack=friendlyVitals[h.target];local vital=byAttack and byAttack[h.attackId]
     if not vital or vital.source~=h.source or math.abs(vital.damage-h.healthDamage)>1e-5 then return false,'FRIENDLY_VITAL_MISMATCH'end
     byAttack[h.attackId]=nil
    end
    friendlyHP=friendlyHP+h.healthDamage;friendlyHits=friendlyHits+1
   elseif h.relation~=nil and h.relation~='hostile' then return false,'INVALID_RELATION'
   else hp=hp+h.healthDamage;ap=ap+h.armorDamage;if h.armorBroken then breaks=breaks+1 end end
  end
  if type(s.totals)~='table' or s.totals.healthDamage~=hp or s.totals.armorDamage~=ap or s.totals.armorBreaks~=breaks or (s.totals.friendlyHealthDamage or 0)~=friendlyHP or (s.totals.friendlyHits or 0)~=friendlyHits then return false,'INCONSISTENT_TOTALS' end
 end
 for _,byAttack in pairs(friendlyVitals)do if next(byAttack)then return false,'UNLINKED_FRIENDLY_VITAL'end end
 if e.versions.credit==2 then
  if type(e.creditTargets)~='table' then return false,'MISSING_CREDIT_TARGETS'end
  local replay=require('Training.FlowerCredit').new()
  table.sort(creditEvents,function(a,b)return a.credit.sequence<b.credit.sequence end)
  for index,hit in ipairs(creditEvents)do
   if hit.credit.sequence~=index then return false,'INVALID_CREDIT_ORDER'end
   if hit.targetStage~='boss' and hit.targetStage~='flower' and hit.targetStage~='bud' then return false,'INVALID_TARGET_STAGE'end
   local config=e.creditTargets[hit.target]
   if hit.targetStage~='bud' then
    if type(config)~='table' or config.target~=hit.target or not finite(config.maxHP) or config.maxHP<=0 or type(config.parts)~='table' or type(config.summoned)~='boolean' then return false,'INVALID_CREDIT_TARGET'end
    if hit.target=='factory-flower' then
     local armor={['flower-head']=0,['flower-core']=40,['petal-left']=70,['petal-right']=70,roots=90}
     if config.maxHP~=220 or config.summoned or hit.targetStage~='boss' then return false,'INVALID_BOSS_BUDGET'end
     for part,ap in pairs(armor)do if config.parts[part]~=ap then return false,'INVALID_BOSS_BUDGET'end end
     for part in pairs(config.parts)do if armor[part]==nil then return false,'INVALID_BOSS_BUDGET'end end
    else
     local root=hit.target=='factory-flower-root-1' or hit.target=='factory-flower-root-2'
     if config.maxHP>100 or config.summoned==root or (not root and not hit.target:match('^flower%-unit%-') and not hit.target:match('^factory%-summon%-%d+$')) or config.parts.body~=0 then return false,'INVALID_FLOWER_BUDGET'end
     for part in pairs(config.parts)do if part~='body' then return false,'INVALID_FLOWER_BUDGET'end end
    end
    for name,ap in pairs(config.parts)do if type(name)~='string' or not finite(ap) or ap<0 then return false,'INVALID_CREDIT_PART'end end
   end
   local ok,credit=pcall(replay.hit,replay,hit,config,hit.credit.at)
   if not ok then return false,'INVALID_CREDIT_REPLAY'end
   local function same(a,b,key)
    if type(a)~=type(b)then return false end
    -- JSON roundoff in budget subtraction must not reject a real archive.
    -- Only derived HP/AP amounts tolerate roundoff; order and identity stay exact.
    if type(a)=='number' and (key=='health' or key=='armor')then return finite(a) and finite(b) and math.abs(a-b)<=1e-8 end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k],k)then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
   end
   if not same(credit,hit.credit)then return false,'INCONSISTENT_FLOWER_CREDIT'end
  end
  replay:close()
 end
 return true
end
function Store.encode(e)
 local ok,why=Store.validate(e);if not ok then return nil,why end
 local s=D.json.encode(e,false,true);if not s or #s>Store.maxBytes then return nil,'EPISODE_TOO_LARGE' end
 return s
end
function Store.load(attempt)
 if type(attempt)~='number' or attempt%1~=0 then return nil,'INVALID_ATTEMPT' end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0CombatEpisodes WHERE attempt=?',{attempt})
 if not rows then return nil,'READ_FAILED' end
 if not rows[1] then return nil,'NOT_RECORDED' end
 local payload=rows[1][1];if type(payload)~='string' or #payload>Store.maxBytes then return nil,'INVALID_PAYLOAD' end
 local e=D.json.decode(payload,32);local ok,why=Store.validate(e);if not ok then return nil,why end
 return e
end
return Store
