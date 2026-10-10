package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local V=require('Training.CombatVitals');local v=V.new()
v:record('ninilite',100,80,{kind='twine',source='boss',attackId='a'},1)
v:record('ninilite',80,82,{kind='support-heal',source='life-support'},2)
v:record('ninilite',82,84,{kind='support-heal',source='life-support'},2.02)
v:record('ninilite',84,82,{kind='poison',source='boss',attackId='a'},3)
v:record('ninilite',82,80,{kind='support-hazard',source='life-support'},4)
assert(not pcall(v.record,v,'ninilite',79,70,{kind='attack',source='boss'},5))
local s=v:snapshot();assert(V.validate(s));local a=s.actors.ninilite
assert(a.damage==24 and a.healing==4 and a.finalHP==80 and #a.events==4 and a.events[2].samples==2)
assert(not pcall(v.record,v,'ninilite',80,70,{kind='attack',source='boss'},5))
a.damage=20;assert(not V.validate(s));a.damage=24
a.events[3].hpBefore=100;assert(not V.validate(s));a.events[3].hpBefore=84
a.events[3].started=1;assert(not V.validate(s))
print('PASS exact damage/healing, continuous support coalescing, poison provenance, missing change/time/total rejection, closed ledger')
