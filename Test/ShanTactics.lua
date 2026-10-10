package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local T=require('Enemy.ShanTactics')
local e={asset='xiaoshanxiao',hp=100,unit={x=0}}
local boss={asset='dashanxiao',hp=100,unit={x=800}}
local a={asset='xiaoshanxiao',hp=100,unit={x=400}};local b={asset='xiaoshanxiao',hp=100,unit={x=-400}}
assert(T.context(e,{e,boss}).supported)
boss.hp=0;assert(not T.context(e,{e,boss}).supported)
boss.hp=100;boss.unit.x=1000;assert(not T.context(e,{e,boss}).supported)
assert(not T.context(e,{e,a}).supported)
local c=T.context(e,{e,a,b});assert(c.supported and c.others==2)
assert(T.choose(c,400,1)=='litter' and T.choose(c,400,2)=='throw' and T.choose(c,400,3)=='rush')
assert(T.choose(c,100,2)=='scratch')
local lone=T.context(e,{e});assert(T.choose(lone,100,1)=='evade' and T.choose(lone,100,2)=='scratch')
for i=1,12 do assert(T.choose(lone,400,i)=='throw')end
print('PASS live nearby boss, dead/distant exclusion, two-allies threshold, supported attacks, lone evade/scratch, ranged throw')
