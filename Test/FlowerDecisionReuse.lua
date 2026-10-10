local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local D={App={totalTime=1}};package.loaded.Dora=D
local captures,aimCalls=0,0
package.loaded['Training.FlowerFeatures']={capture=function(_,owner)captures=captures+1;return {x=owner.x}end}
package.loaded['Training.FlowerPolicy']={decodeAction=function(label)local name,part=label:match('^([^@]+)@(.+)$');return name or label,part end}
local a={character={id='ninilite'},student={x=10,isDoing=function()return false end},physical={idle='wait',laser='shoot',fmove='f',bmove='b'},mode='demo',available=function()return true end}
local journal={steps={}};local expectedAim
local b={phase='ready',learners={a},roots={{},{},{enemy={x=100}}},support={spent=0,update=function()end},start=function()end,finish=function()end,
 partCombat={known={},journal=journal,vitals={actors={},checkpoint=function()end},aim=function(_,_,part)aimCalls=aimCalls+1;return {angle=aimCalls,part=part}end}}
a.request=function(_,action,source)if expectedAim then assert(a.flowerTargetAim==expectedAim)end;local i=#journal.steps+1;journal.steps[i]={id=i,action={actor='ninilite'}};return true,'ACCEPTED'end
local T=require('Training.FlowerDecisionTrace');local trace=T.attach(b);b.phase='playing'
local decision=T.decision(b,a);assert(captures==1 and aimCalls==5)
expectedAim=decision.aims['flower-head'];a.flowerTargetPart='flower-head';a.flowerTargetAim=expectedAim
assert(a:request('laser','model',decision));assert(captures==1 and aimCalls==5 and decision.used)
assert(trace.actors.ninilite.steps[1].state.x==10 and #trace.actors.ninilite.steps[1].actions==9)
expectedAim=nil;a.flowerTargetPart=nil
assert(a:request('idle','model',decision));assert(captures==2 and aimCalls==10,'Consumed result reused')
local stale=T.decision(b,a);D.App.totalTime=2;a.student.x=20
assert(a:request('idle','model',stale));assert(captures==4 and aimCalls==20,'Previous frame reused')
assert(trace.actors.ninilite.steps[3].state.x==20)
local foreign=T.decision(b,a);foreign.owner={}
assert(a:request('idle','model',foreign));assert(captures==6 and aimCalls==30,'Other actor reused')
local E=require('Training.FlowerQExecutor');local counts=E.counters();local policy={choose=function(_,_,legal)assert(legal('shoot@flower-head'));return 'shoot@flower-head','Q'end}
local before=aimCalls;assert(E.step(b,a,policy,{},counts));assert(aimCalls-before==5,'Executor recomputed selected aim or boundary')
assert(counts.q==1 and counts.accepted==1 and a.flowerTargetAim==nil)
print('PASS one solve per part; selected aim and accepted boundary reused; consumed, stale and foreign results rejected')
-- A costly decision can cross a wall-clock cooldown even without yielding a
-- simulation frame. Fallback must use the same mask as the recorded boundary.
local laserReady=false
local originalAvailable=a.available
a.available=function(_,name)return name~='laser' or laserReady end
a.snapshot=function()return {attackReady='yes'}end
package.loaded['Training.Model']={predict=function(_,_,available)return available('laser') and 'laser' or available('idle') and 'idle' or nil end}
local fallback={choose=function(_,_,legal)
 assert(not legal('shoot'),'Cooldown must be closed at boundary')
 laserReady=true
 return nil,'UNSEEN_STATE'
end}
local fallbackCounts=E.counters()
assert(E.step(b,a,fallback,{},fallbackCounts))
assert(trace.actors.ninilite.steps[#trace.actors.ninilite.steps].action=='idle','Fallback escaped original legal mask')
assert(fallbackCounts.fallback==1 and fallbackCounts.accepted==1)
a.available=originalAvailable
print('PASS cooldown opening during decision cannot admit an unrecorded fallback action')
local baseMask=T.baseActions({actions={'idle','shoot@flower-head','melee'}})
assert(baseMask.idle and baseMask.melee and not baseMask.laser and not baseMask.fmove and not baseMask.bmove)
print('PASS part-specific legality does not invent ordinary fallback shooting')

-- Busy/controlled actors have no decision to infer or record. In particular,
-- do not sample animated hulls just to discover that execution is impossible.
local beforeCapture,beforeAim=captures,aimCalls
local original=a.available;a.available=function()return false end
local none,reason=T.decision(b,a)
assert(none==nil and reason=='NO_AVAILABLE_ACTIONS')
local skipped=E.counters()
local ok,why=E.step(b,a,{choose=function()error('Inferred policy with no legal action')end},{},skipped)
assert(not ok and why=='NO_AVAILABLE_ACTIONS' and skipped.skipped==1)
assert(captures==beforeCapture and aimCalls==beforeAim,'Unavailable decision sampled geometry')
a.available=original
assert(T.decision(b,a),'Legal action did not resume after unavailable period')
print('PASS no-action polling skips geometry/inference and resumes when an action is legal')
