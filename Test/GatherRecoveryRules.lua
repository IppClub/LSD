package.path='./Script/?.lua;'..package.path
local G=require('Combat.GatherGesture');local F=require('Combat.Formation');local S=require('Ground.LifeSupport')
local playing=true;local orders={}
local g=G.new(function()return playing end,function(name)orders[#orders+1]=name;return true end)
assert(g:press('keyboard',0));g:update(.3);g:release('keyboard');g:update(1)
assert(#orders==1 and orders[1]=='gather','A short press issued recovery')
g:press('keyboard',2);g:press('keyboard',2.1);g:update(2.64)
assert(#orders==2,'Repeat or early hold issued an extra order')
g:update(2.7);g:update(3);g:update(9)
assert(#orders==3 and orders[3]=='recover-gather','A sustained hold must recover exactly once')
g:release('keyboard');g:press('touch',10);g:update(10.7);g:release('touch')
assert(#orders==5 and orders[5]=='recover-gather','Touch must share the hold behavior')
g:press('touch',12);g:press('keyboard',12.1);g:release('touch');g:update(12.7)
assert(#orders==7 and orders[7]=='recover-gather','Two input sources should form one held gesture')
playing=false;g:update(13);assert(next(g.held)==nil);assert(not g:press('keyboard',14))
playing=true;g:press('keyboard',15);g:update(15.2);g:clear();g:update(20)
assert(#orders==8,'An abandoned gesture survived clearing')
assert(F.recoverySpacing+F.tolerance<=S.healingRange)
assert(not F.recoveryNeeded({100,100,100},nil,true))
assert(F.recoveryNeeded({100,90,100},nil,true))
assert(not F.recoveryNeeded({90,100,100},{90,100,100},true),'An injury cap made recovery endless')
assert(not F.recoveryNeeded({0,100,100},nil,true),'Recovery revived a defeated role')
assert(not F.recoveryNeeded({50,50,50},nil,false),'A stopped machine kept actors waiting for healing')
local ready={{character={id='ninilite'},studentHP=100,student={x=800}},{character={id='wuyun'},studentHP=100,student={x=900}}}
local targets={ninilite=800,wuyun=900}
assert(F.recoveryDuration(targets,ready,{86,100,82},nil,S.healingRate)==9,'Recovery omitted actual healing time')
assert(F.recoveryDuration(targets,ready,{1,1,1},nil,S.healingRate)==12,'Recovery exceeded the finite bound')
assert(F.recoveryDuration(targets,ready,{80,100,100},{80,100,100},S.healingRate)==3,'Injury cap extended the order')
assert(F.recoveryDuration(targets,ready,{0,100,100},nil,S.healingRate)==3,'Defeated role extended recovery')
local plan={_anchor=1000,ninilite=800}
local actor={character={id='ninilite'},studentHP=100,student={x=800},regroupPlan=plan,regroupComplete=true}
local benefit=true
local battle={phase='playing',gatherMode='recover',gatherUntil=12,gatherPlan=plan,mentor={x=1000},gatherActive=function()return benefit end}
assert(F.owns(actor,battle,1)and F.stationaryRecovery(actor,battle,1),'Arrived recovery must retain movement ownership and permit stationary decisions')
actor.regroupComplete=false;assert(not F.stationaryRecovery(actor,battle,1));actor.regroupComplete=true
actor.student.x=819;assert(not F.stationaryRecovery(actor,battle,1),'Displaced actor kept its arrived window');actor.student.x=800
battle.mentor.x=1019;assert(not F.stationaryRecovery(actor,battle,1),'Moved mentor kept a stale window');battle.mentor.x=1000
actor.regroupPlan={};assert(not F.stationaryRecovery(actor,battle,1));actor.regroupPlan=plan
assert(not F.stationaryRecovery(actor,battle,12),'Expired recovery kept policy ownership')
benefit=false;assert(not F.stationaryRecovery(actor,battle,1));benefit=true
actor.studentHP=0;assert(not F.stationaryRecovery(actor,battle,1));actor.studentHP=100
battle.gatherMode='normal';assert(not F.stationaryRecovery(actor,battle,1));battle.gatherMode='recover'
battle.phase='settling';assert(not F.stationaryRecovery(actor,battle,1))
for _,case in ipairs({{1000,1600},{1000,400},{225,1600},{3600,3000}})do
 local normal=F.plan(case[1],case[2],{'wuyun','ninilite'},200,3640,{keepAway=true})
 local recover=F.plan(case[1],case[2],{'wuyun','ninilite'},200,3640,{keepAway=true,spacing=F.recoverySpacing})
 if case[1]==1000 then assert(math.abs(normal.ninilite-case[1])==360)end
 local s=S.new(90,'defence');s.hp={40,40,40}
 s:update(1,{case[1],recover.ninilite,recover.wuyun})
 assert(s.hp[1]==43 and s.hp[2]==43 and s.hp[3]==43,'Recovery formation left a role outside actual healing')
 assert(s.gold<90,'Recovery silently removed the real energy cost')
end
print('PASS: short/held/repeated/touch/mixed/cleared input and actual recovery/cost rules')
