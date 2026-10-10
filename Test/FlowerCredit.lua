package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local C=require('Training.FlowerCredit');local c=C.new()
local boss={target='factory-flower',maxHP=220,parts={['flower-head']=0,['flower-core']=40,['petal-left']=70,['petal-right']=70,roots=90},summoned=false}
local serial=0
local function hit(target,stage,hp,damage,ap,ad,actor,part)
 serial=serial+1
 return {target=target,targetStage=stage,relation='hostile',source=actor or 'mentor',attackId='attack-'..serial,hitId='impact',part=part or 'body',hpBefore=hp,hpAfter=hp-damage,healthDamage=damage,apBefore=ap or 0,apAfter=(ap or 0)-(ad or 0),armorDamage=ad or 0,armorBroken=(ap or 0)>0 and ap==ad}
end
local e=hit('factory-flower','boss',220,0,70,70,'ninilite','petal-left');local r=c:hit(e,boss,1);assert(r.armor==70 and r.breaks==1)
e=hit('factory-flower','boss',220,15,0,0,'mentor','petal-left');r=c:hit(e,boss,2);assert(r.assist.actor=='ninilite' and r.assist.health==15)
for i=1,20 do r=c:hit(hit('flower-unit-bud','bud',100,100),nil,3+i);assert(r.health==0 and r.excluded=='bud-transient')end
local cfg={target='flower-unit-bud',maxHP=30,parts={body=0},summoned=true}
r=c:hit(hit(cfg.target,'flower',30,30),cfg,24);assert(r.health==30)
r=c:hit(hit(cfg.target,'flower',30,30),cfg,25);assert(r.health==0)
local total=30
for i=1,10 do local cfg={target='flower-unit-'..i,maxHP=100,parts={body=0},summoned=true};r=c:hit(hit(cfg.target,'flower',100,100),cfg,25+i);total=total+r.health end
assert(total==300 and c.summonRemaining==0,'Repeated summon reward farm')
c:close();assert(not pcall(c.hit,c,hit('flower-unit-bud','bud',100,10),nil,40))
print('PASS Boss break assist, transient bud exclusion, mature HP budget, healing and summon farming limits, close')
