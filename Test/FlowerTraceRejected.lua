local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
package.loaded.Dora={App={totalTime=1}}
package.loaded['Training.FlowerFeatures']={capture=function()error('Rejected request sampled a boundary')end}
package.loaded['Training.FlowerPolicy']={}
local calls=0
local a={character={id='ninilite'},student={},physical={idle='wait'},mode='demo',available=function()return false end}
a.request=function(_,action,source)calls=calls+1;assert(action=='idle' and source=='demo');return false,'ORIGINAL_REJECTION'end
local b={phase='ready',learners={a},support={spent=0,update=function()end},start=function()end,finish=function()end}
local trace=require('Training.FlowerDecisionTrace').attach(b);b.phase='playing'
for i=1,100 do local ok,why=a:request('idle','demo');assert(not ok and why=='ORIGINAL_REJECTION')end
assert(calls==100 and #trace.actors.ninilite.steps==0)
a.available=function()return true end;a.student.isDoing=function()return true end
local ok,why=a:request('idle','demo');assert(not ok and why=='ORIGINAL_REJECTION' and calls==101)
print('PASS 101 rejected requests preserve executor effects and reason; no boundary or aim queries')
