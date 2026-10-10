-- Held-out encounter starts: available only to automatic evaluation, never demos.
local S={resourceIds={'field','near','far','reproduction','exposed'},ids={'near','far','reproduction'},menuIds={'near','far','reproduction','field'}}
local definitions={
 exposed={id='exposed',name='已知全身破甲',resourceOnly=true,knownArmor=true,distance=450,bossHP=220,phase=1,armor={['flower-head']=0,['flower-core']=0,['petal-left']=0,['petal-right']=0,roots=0}},
 field={id='field',name='默认补给完整阵型',preserveFormation=true,supportGold=45,bossHP=220,phase=1,armor={['flower-head']=0,['flower-core']=40,['petal-left']=70,['petal-right']=70,roots=90}},
 near={id='near',name='近距完整护甲',distance=250,bossHP=220,phase=1,armor={['flower-head']=0,['flower-core']=40,['petal-left']=70,['petal-right']=70,roots=90}},
 far={id='far',name='远距完整护甲',distance=850,bossHP=220,phase=1,armor={['flower-head']=0,['flower-core']=40,['petal-left']=70,['petal-right']=70,roots=90}},
 reproduction={id='reproduction',name='繁殖期局部破甲',distance=450,bossHP=110,phase=2,armor={['flower-head']=0,['flower-core']=0,['petal-left']=0,['petal-right']=0,roots=90}}
}
local function copy(v)if type(v)~='table'then return v end;local t={};for k,n in pairs(v)do t[k]=copy(n)end;return t end
function S.get(id)return definitions[id] and copy(definitions[id])end
function S.validate(profile)return type(profile)=='table' and definitions[profile.id]~=nil and require('Training.FlowerIdentity').equal(profile,definitions[profile.id])end
function S.apply(battle,arena,id)
 local profile=assert(S.get(id),'Unknown flower evaluation scenario')
 if profile.resourceOnly then assert(battle.supplies and battle.supplies.isVirtual,'Resource scenario requires virtual supplies')end
 assert(battle.phase=='ready' and #battle.partCombat.journal.steps==0)
 local boss=battle.roots[3];local target=battle.partCombat.target
 if not profile.preserveFormation then arena.student.x=boss.enemy.x-profile.distance end;arena.student.velocityX=0
 boss.enemyHP=profile.bossHP;target.damage.hp=profile.bossHP
 for part,ap in pairs(profile.armor)do
  target.damage.parts[part].ap=ap
  if profile.knownArmor then battle.partCombat.known[part]={ap=ap,maxAP=target.damage.parts[part].maxAP}end
 end
 -- Keep authored phase transition and attack timelines; only initial conditions
 -- are changed. Pre-broken armor earns no synthetic break or assistance credit.
 if profile.phase==2 then boss.enemyCombat:updatePhase(require('Dora').App.runningTime)end
 assert(boss.enemyCombat.bossPhase==profile.phase)
 return profile
end
return S
