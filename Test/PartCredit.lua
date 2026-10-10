package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local C=require('Training.PartCredit')
local function event(token,part,hp,damage,ap,armor)
 return {target='boss',attackId=token,hitId='hit',part=part,hpBefore=hp,hpAfter=hp-damage,healthDamage=damage,apBefore=ap,apAfter=ap-armor,armorDamage=armor,armorBroken=ap>0 and ap==armor}
end
local c=C.new({target='boss',maxHP=100,parts={head=20,tail=10}})
local e=event('emp','head',100,0,20,20)
local r=assert(c:hit(e,'ninilite',1));assert(r.armor==20 and r.breaks==1 and not r.assist)
assert(not c:hit(e,'ninilite',1))
r=assert(c:hit(event('shot','head',100,30,0,0),'mentor',2));assert(r.health==30 and r.assist.actor=='ninilite' and r.assist.health==30)
assert(c:snapshot().actors.ninilite.health==0 and c:snapshot().actors.ninilite.assistedHealth==30)
r=assert(c:hit(event('self','head',70,10,0,0),'ninilite',3));assert(not r.assist)
r=assert(c:hit(event('otherpart','tail',60,1,10,0),'mentor',4));assert(not r.assist)
r=assert(c:hit(event('expired','head',59,9,0,0),'mentor',8));assert(not r.assist)
-- Restored armor/health can be damaged again in game, but cannot farm credit.
r=assert(c:hit(event('rebreak','head',100,0,20,20),'ninilite',9));assert(r.armor==0 and r.breaks==0)
r=assert(c:hit(event('healed','head',100,100,0,0),'mentor',10));assert(r.health==50 and not r.assist)
r=assert(c:hit(event('again','head',100,100,0,0),'mentor',11));assert(r.health==0)
local snapshot=c:snapshot();snapshot.actors.mentor.health=999;assert(c:snapshot().actors.mentor.health~=999)
assert(not c:hit(event('late','head',100,0,0,0),'mentor',1))
c:close();assert(not c:hit(event('closed','head',100,0,0,0),'mentor',12))
print('PASS separate direct/assist attribution, dedup, part/window restrictions, regeneration budgets, snapshot isolation, close')
