package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
package.preload.Dora=function()return {App={runningTime=10}}end
local F=require('Training.FlowerFeatures')
local mentor={x=0,faceRight=true};local ni={x=100,faceRight=true};local wu={x=200,faceRight=true}
local boss={enemy={x=600},enemyCombat={bossPhase=1}}
local b={mentor=mentor,mentorHP=100,learners={{student=ni,studentHP=100,studentEnergy=12,shotEnergyCost=12},{student=wu,studentHP=100}},roots={false,false,boss},effects={states={}},support={gold=45,machineHP=100,x=100,radius=180}}
function b:target()return boss end
local a=F.capture(b,ni,{});assert(F.validate(a) and a.featureSchemaVersion==6 and a.health=='healthy' and a.energyReady=='ready' and a.support=='inside' and a.supplies=='available' and a.allyHealth=='healthy' and a.part_left=='unknown')
b.learners[1].studentHP=30;b.learners[1].studentEnergy=11;b.learners[2].studentHP=0;b.support.gold=10
local injured=F.capture(b,ni,{['petal-left']={ap=0,maxAP=70}})
assert(injured.health=='danger' and injured.energyReady=='empty' and injured.allyHealth=='fallen' and injured.supplies=='low' and injured.part_left=='exposed')
assert(a.health=='healthy' and a.part_left=='unknown','Observation changed retroactively')
b.support.x=1000;assert(F.capture(b,ni,{}).support=='outside');b.support.machineHP=0;assert(F.capture(b,ni,{}).support=='inactive')
b.support=nil;local unknown=F.capture(b,mentor,{});assert(unknown.support=='unknown' and unknown.supplies=='unknown' and unknown.energyReady=='unlimited')
unknown.health=nil;assert(not F.validate(unknown));unknown.featureSchemaVersion=5;assert(F.validate(unknown),'Legacy observation unreadable')
print('PASS health/energy/ally/supply counterfactuals at same distance, field coverage, public armor knowledge, immutable snapshot, legacy version')
