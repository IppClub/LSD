package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
package.preload.Dora=function()return {}end
local J=require('Training.CombatJournal');local C=require('Training.FlowerCredit');local V=require('Training.CombatVitals');local E=require('Training.FlowerEvaluation')
local state={featureSchemaVersion=5,partSetVersion=2,enemyAsset='dahuayao',phase='entrenched',phasePending=false,distance='mid',facing='toward',target='boss',confused=false,poisoned=false,virus=false,part_head='unknown',part_core='unknown',part_left='unknown',part_right='unknown',part_roots='unknown'}
local j=J.new('evaluation',{observation=5,action=3,combat=1,partSet=2,contactScope='all-projectile',weaponRules=2,credit=2,vitals=1});local c=C.new();local v=V.new()
local cfg={target='factory-flower',maxHP=220,parts={['flower-head']=0,['flower-core']=40,['petal-left']=70,['petal-right']=70,roots=90},summoned=false}
local function action(actor,weapon,at,hit)
 local id=assert(j:begin(state,{actor=actor,weapon=weapon,name='shoot',emitted=1},at,true));hit.attackId='shot-'..id;hit.hitId='impact';hit.source=actor;hit.weapon=weapon
 if hit.relation=='hostile'then hit.credit=c:hit(hit,cfg,at+.1)end
 assert(j:attach(id,hit.attackId));assert(j:hit(hit));assert(j:expire(hit.attackId));assert(j:finish(id,state,at+.8,false))
end
action('ninilite','emp',1,{relation='hostile',target='factory-flower',targetStage='boss',part='petal-left',hpBefore=220,hpAfter=220,healthDamage=0,apBefore=35,apAfter=0,armorDamage=35,armorBroken=true})
action('mentor','kinetic',2,{relation='hostile',target='factory-flower',targetStage='boss',part='petal-left',hpBefore=220,hpAfter=205,healthDamage=15,apBefore=0,apAfter=0,armorDamage=0,armorBroken=false})
action('ninilite','emp',3,{relation='friendly',cause='virus',target='wuyun',part='body',hpBefore=100,hpAfter=100,healthDamage=0,apBefore=0,apAfter=0,armorDamage=0,armorBroken=false})
assert(j:begin(state,{actor='mentor',weapon='kinetic',name='shoot'},4,true));j:close('aborted')
v:record('ninilite',100,90,{kind='attack',source='factory-flower',attackId='enemy-1'},3)
v:record('ninilite',90,95,{kind='support-heal',source='life-support'},3.5)
local e=j:snapshot();e.creditTargets=c.targets;e.vitals=v:snapshot()
local result=assert(E.build(e));local ni=result.actors.ninilite;local mentor=result.actors.mentor
assert(ni.health==0 and ni.armor==35 and ni.breaks==1 and ni.assistedHealth==15)
assert(ni.friendlyContacts==1 and ni.friendlyDamage==0 and ni.damageTaken==10 and ni.healing==5 and ni.shots==2)
assert(mentor.health==15 and mentor.shots==1 and mentor.incompleteActions==1 and result.incompleteActions==1)
assert(E.text(result):find('协作'))
e.versions.vitals=nil;assert(not E.build(e),'Old missing intake treated as zero')
print('PASS actor-separated effective output, break assist, real emissions, zero-damage contact, intake/healing, interrupted action, missing coverage')
