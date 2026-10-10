package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local A=require('Training.FlowerAimEvaluation')
local e={versions={aim=1},steps={}}
local function step(part,status,hits,sealed,redirected)
 e.steps[#e.steps+1]={sealed=sealed,action={name='shoot',actor='ninilite',emitted=1,aimSource=status,intendedPart=part,redirected=redirected},hits=hits or {}}
end
local function hit(part,target,id)return {attackId=id or 'x',target=target or 'factory-flower',part=part,relation='hostile'}end
step('petal-left','manual-sweep-v1',{hit('petal-left'),hit('petal-left')},true)
step('flower-head','manual-sweep-v1',{hit('flower-core')},true)
step('roots','part-policy-v1',{hit('body','flower-unit')},true)
step('roots','part-policy-v1',{},true)
step('unknown',nil,{hit('petal-left')},true)
step('roots','part-policy-v1',{},true,true)
step('roots','part-policy-v1',{},false)
local r=A.build(e).actors.ninilite
assert(r.emitted==7 and r.aimed==4 and r.correct==1 and r.wrongPart==1 and r.otherEnemy==1 and r.missOrBlocked==1)
assert(r.unknownIntent==1 and r.redirected==1 and r.unresolved==1)
assert(r.emitted==r.aimed+r.unknownIntent+r.redirected+r.unresolved)
e.versions.aim=nil;assert(A.build(e)==nil)
print('PASS explicit denominators, no backfilled intent, duplicate contacts, incomplete/redirected isolation, legacy unknown')
