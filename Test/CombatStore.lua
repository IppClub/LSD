-- Pure validation boundaries; transactional persistence is tested natively.
package.preload.Dora=function()return {}end
local base='/Users/Jin/Workspace/Dora/LSD/Script/'
local Store=dofile(base..'Training/CombatStore.lua');local Journal=dofile(base..'Training/CombatJournal.lua')
local j=Journal.new('test',{observation=3,action=2,combat=1})
local id=assert(j:begin({distance=10},{name='emp'},0,true));assert(j:finish(id,{},1,false));j:close('aborted')
local e=j:snapshot();assert(Store.validate(e))
e.versions.observation=99;assert(not Store.validate(e));e.versions.observation=3
e.steps[1].sealed=false;e.steps[1].truncated=nil;assert(not Store.validate(e));e.steps[1].truncated=true;assert(Store.validate(e))
e.steps[1].totals.healthDamage=10;assert(not Store.validate(e));e.steps[1].totals.healthDamage=0
e.steps[1].started=0/0;assert(not Store.validate(e))
print('PASS compatible envelope, unknown version, unfinished interval, interrupted interval, inconsistent totals, invalid clock')
e.steps[1].started=0;e.steps[1].sealed=true;e.steps[1].truncated=nil
e.versions.credit=1
local hit={healthDamage=10,armorDamage=0,hpBefore=100,hpAfter=90,apBefore=0,apAfter=0,attackId='a',part='head'}
e.steps[1].hits={hit};e.steps[1].totals.healthDamage=10
assert(not Store.validate(e))
hit.credit={schemaVersion=1,actor='mentor',at=.5,health=10,armor=0,breaks=0,assist={actor='ninilite',health=10,attackId='emp'}}
assert(Store.validate(e))
hit.credit.assist.actor='mentor';assert(not Store.validate(e));hit.credit.assist.actor='ninilite'
hit.credit.health=11;assert(not Store.validate(e));hit.credit.health=10
e.versions.credit=99;assert(not Store.validate(e))
print('PASS missing credit, self-assist, excess credit and unknown credit version rejected')

package.path=base..'?.lua;'..package.path
local state={featureSchemaVersion=5,partSetVersion=2,enemyAsset='dahuayao',phase='entrenched',phasePending=false,distance='mid',facing='toward',target='boss',confused=false,poisoned=false,virus=false,part_head='unknown',part_core='unknown',part_left='unknown',part_right='unknown',part_roots='unknown'}
local flower=Journal.new('flower',{observation=5,action=3,combat=1,partSet=2,contactScope='hostile'})
local id=assert(flower:begin(state,{name='shoot',actor='ninilite',weapon='emp'},0,true));assert(flower:finish(id,state,1,false));flower:close('aborted')
local e=flower:snapshot();assert(Store.validate(e))
e.steps[1].nextObservation=nil;assert(not Store.validate(e));e.steps[1].nextObservation=state
e.versions.partSet=1;assert(not Store.validate(e));e.versions.partSet=2
e.steps[1].observation.phase='future';assert(not Store.validate(e))
print('PASS flower version boundary, unknown phase and missing successor rejected')

state.phase='entrenched'
local j=Journal.new('friendly',{observation=5,action=3,combat=1,partSet=2,contactScope='hostile-and-virus-friendly'})
local id=assert(j:begin(state,{name='shoot',actor='mentor',weapon='kinetic'},0,true));assert(j:attach(id,'virus'))
assert(j:hit({attackId='virus',hitId='impact',source='mentor',target='wuyun',part='body',relation='friendly',cause='virus',healthDamage=15,armorDamage=0,hpBefore=100,hpAfter=85,apBefore=0,apAfter=0,armorBroken=false}))
assert(j:finish(id,state,1,false));assert(j:expire('virus'));j:close()
local e=j:snapshot();assert(Store.validate(e));assert(e.steps[1].totals.healthDamage==0 and e.steps[1].totals.friendlyHealthDamage==15)
e.versions.contactScope='hostile';assert(not Store.validate(e));e.versions.contactScope='hostile-and-virus-friendly'
e.steps[1].hits[1].source='ninilite';assert(not Store.validate(e));e.steps[1].hits[1].source='mentor'
e.steps[1].totals.healthDamage=15;assert(not Store.validate(e))
print('PASS actual friendly damage segregated, legacy scope and source forgery rejected')
local j=Journal.new('unified',{observation=5,action=3,combat=1,partSet=2,contactScope='all-projectile',weaponRules=2})
local id=assert(j:begin(state,{name='shoot',actor='ninilite',weapon='emp'},0,true));assert(j:attach(id,'emp'))
assert(j:hit({attackId='emp',hitId='impact',source='ninilite',target='wuyun',part='body',relation='friendly',cause='virus',weapon='emp',healthDamage=0,armorDamage=0,hpBefore=100,hpAfter=100,apBefore=0,apAfter=0,armorBroken=false}))
assert(j:finish(id,state,1,false));assert(j:expire('emp'));j:close()
local e=j:snapshot();assert(Store.validate(e));assert(e.steps[1].totals.friendlyHits==1)
e.versions.weaponRules=99;assert(not Store.validate(e));e.versions.weaponRules=2
local hit=e.steps[1].hits[1];hit.healthDamage=20;hit.hpAfter=80;e.steps[1].totals.friendlyHealthDamage=20
assert(not Store.validate(e),'EMP legacy HP damage accepted in unified rules')
print('PASS unified weapon rule version, zero-HP friendly contact and legacy EMP damage rejection')
local FlowerCredit=require('Training.FlowerCredit')
local credits=FlowerCredit.new()
local j=Journal.new('credit-replay',{observation=5,action=3,combat=1,partSet=2,contactScope='all-projectile',weaponRules=2,credit=2})
local id=assert(j:begin(state,{name='shoot',actor='mentor',weapon='kinetic'},0,true));assert(j:attach(id,'shot'))
local h={attackId='shot',hitId='impact',source='mentor',target='factory-flower-root-1',targetStage='flower',part='body',relation='hostile',weapon='kinetic',healthDamage=15,armorDamage=0,hpBefore=100,hpAfter=85,apBefore=0,apAfter=0,armorBroken=false}
h.credit=credits:hit(h,{target=h.target,maxHP=100,parts={body=0},summoned=false},.5)
assert(j:hit(h));assert(j:expire('shot'));assert(j:finish(id,state,1,false));j:close()
local e=j:snapshot();e.creditTargets=credits.targets;assert(Store.validate(e))
e.steps[1].hits[1].credit.health=16;assert(not Store.validate(e));e.steps[1].hits[1].credit.health=15
e.creditTargets[h.target].maxHP=1000;assert(not Store.validate(e));e.creditTargets[h.target].maxHP=100
e.steps[1].hits[1].credit.sequence=2;assert(not Store.validate(e));e.steps[1].hits[1].credit.sequence=1
assert(Store.validate(e))
print('PASS flower credit replay, forged amount, inflated target budget and missing sequence rejected')
local Vitals=require('Training.CombatVitals');local v=Vitals.new()
v:record('wuyun',100,85,{kind='virus-friendly-fire',source='mentor',attackId='friendly'},.5)
local j=Journal.new('vitals-link',{observation=5,action=3,combat=1,partSet=2,contactScope='all-projectile',weaponRules=2,vitals=1})
local id=assert(j:begin(state,{name='shoot',actor='mentor',weapon='kinetic'},0,true));assert(j:attach(id,'friendly'))
assert(j:hit({attackId='friendly',hitId='impact',source='mentor',target='wuyun',part='body',relation='friendly',cause='virus',weapon='kinetic',healthDamage=15,armorDamage=0,hpBefore=100,hpAfter=85,apBefore=0,apAfter=0,armorBroken=false}))
assert(j:expire('friendly'));assert(j:finish(id,state,1,false));j:close()
local e=j:snapshot();e.vitals=v:snapshot();assert(Store.validate(e))
e.vitals.actors.wuyun.events[1].source='ninilite';assert(not Store.validate(e));e.vitals.actors.wuyun.events[1].source='mentor'
e.vitals.actors={};assert(not Store.validate(e))
print('PASS friendly hit/victim ledger linked, incorrect source and missing intake rejected')
-- Envelope version and every before/after observation must agree.
local j=Journal.new('feature-six',{observation=6,action=3,combat=1,partSet=2,contactScope='all-projectile',weaponRules=2})
local nextState={};for k,value in pairs(state)do nextState[k]=value end
nextState.featureSchemaVersion=6;nextState.health='healthy';nextState.allyHealth='healthy';nextState.energyReady='unlimited';nextState.support='inside';nextState.supplies='available'
local id=assert(j:begin(nextState,{actor='mentor',name='shoot',weapon='kinetic'},0,true));assert(j:finish(id,nextState,1,false));j:close();local e=j:snapshot();assert(Store.validate(e))
e.steps[1].observation.featureSchemaVersion=5;assert(not Store.validate(e));e.steps[1].observation.featureSchemaVersion=6
e.steps[1].nextObservation.health=nil;assert(not Store.validate(e))
print('PASS feature6 envelope, mixed before/after versions and missing safety inputs rejected')
local j=Journal.new('movement',{observation=6,action=4,combat=1,partSet=2,contactScope='all-projectile',weaponRules=2})
local id=assert(j:begin(nextState,{actor='ninilite',name='bmove',weapon='none',origin='model'},0,true));assert(j:finish(id,nextState,.25,false,'stopped'));j:close()
local e=j:snapshot();assert(Store.validate(e))
e.versions.action=3;assert(not Store.validate(e));e.versions.action=4
e.steps[1].action.emitted=1;assert(not Store.validate(e));e.steps[1].action.emitted=nil
e.steps[1].action.origin=nil;assert(not Store.validate(e));e.steps[1].action.origin='scripted';assert(Store.validate(e))
print('PASS action4 movement, rejected legacy action set, forbidden movement emission and missing origin')
e.versions.clock='simulation';assert(Store.validate(e));e.versions.clock='unknown';assert(not Store.validate(e))
print('PASS explicit simulation clock accepted and unknown clock rejected')
