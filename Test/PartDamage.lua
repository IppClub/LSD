local Damage=dofile('/Users/Jin/Workspace/Dora/LSD/Script/Combat/Damage.lua')
local d=Damage.new({id='boss',maxHP=100,parts={
 head={maxAP=20,armoredMultiplier=0,exposedMultiplier=2,armoredResponse='reflect'},
 body={maxAP=80,armoredMultiplier=.1,exposedMultiplier=1,armoredResponse='stop'}}})
local function hit(attack,part,weapon)
 return d:hit({attackId=attack,hitId='contact',part=part,source='nini',position={x=3,y=8},normal={x=-1,y=0}},weapon)
end
local emp={id='emp',armorDamage=25,healthDamage=0}
local ball={id='kinetic',armorDamage=0,healthDamage=15}
assert(d:beginAttack('one'));local a=assert(hit('one','head',emp))
assert(a.armorBroken and a.armorDamage==20 and a.healthDamage==0 and d.parts.body.ap==80)
assert(not hit('one','head',emp),'Duplicate contact was applied')
assert(d:finishAttack('one'));assert(not d:beginAttack('one'),'Finished token reopened');assert(not hit('one','head',ball))
assert(d:beginAttack('two'));local b=assert(hit('two','body',ball))
assert(b.healthDamage==1.5 and b.apAfter==80,'Other part inherited weakness')
assert(d:beginAttack('three'));local c=assert(hit('three','head',ball));assert(c.healthDamage==30)
assert(d:beginAttack('bad'));local hp=d.hp
assert(not hit('bad','missing',ball));assert(d.hp==hp)
assert(d:beginAttack('kill'));local k=assert(hit('kill','head',{id='heavy',armorDamage=0,healthDamage=1000}))
assert(k.killed and k.healthDamage==hp and d.hp==0,'Overkill counted as real damage')
assert(d:beginAttack('late'));assert(not hit('late','head',ball));d:close();assert(not d:beginAttack('closed'))
print('PASS local armor, exact deltas, contact dedup, inactive attacks, invalid part, overkill, death, cleanup')
