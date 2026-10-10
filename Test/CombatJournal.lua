local base='/Users/Jin/Workspace/Dora/LSD/Script/'
local J=dofile(base..'Training/CombatJournal.lua')
local Damage=dofile(base..'Combat/Damage.lua')
local j=J.new('episode-1',{observation=3,action=2,reward=1},4)
local before={part='head',armor='intact',nested={hp=100}}
local step=assert(j:begin(before,{name='laser',intendedPart='head'},0,true));before.nested.hp=0
assert(j:attach(step,'projectile-1'))
assert(j:finish(step,{part='body',armor='intact'},.5,false))
assert(not j:transition(step),'Flying bullet was treated as a miss')
local d=Damage.new({id='boss',maxHP=100,parts={body={maxAP=20,armoredMultiplier=0,exposedMultiplier=1,armoredResponse='stop'}}})
assert(d:beginAttack('projectile-1'))
local event=assert(d:hit({attackId='projectile-1',hitId='one',source='nini',part='body',position={x=1,y=2},normal={x=-1,y=0}},{id='emp',armorDamage=25,healthDamage=0}))
assert(j:hit(event));assert(not j:hit(event));event.part='head'
assert(j:expire('projectile-1'));local t=assert(j:transition(step))
assert(t.observation.nested.hp==100 and not t.observation.hits)
assert(t.action.intendedPart=='head' and t.hits[1].part=='body')
assert(t.totals.armorDamage==20 and t.totals.armorBreaks==1 and t.totals.healthDamage==0)
t.totals.armorDamage=999;assert(j:transition(step).totals.armorDamage==20)
assert(not j:hit(event) and not j:attach(step,'projectile-1'))
assert(not j:begin({}, {name='laser'},1,false))
local interrupted=assert(j:begin({}, {name='laser'},1,true));assert(j:attach(interrupted,'late'))
j:close('ABORTED');assert(not j:transition(interrupted));assert(j.steps[interrupted].truncated)
assert(not j:hit(event) and not j:begin({}, {name='idle'},2,true))
print('PASS immutable before/after, actual vs intended part, delayed impact, dedup, exact deltas, interrupted episode')
