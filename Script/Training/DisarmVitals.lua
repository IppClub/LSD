-- Observe actual HP mutations at the shared target damage boundary.
local D=require('Dora');local V={}
function V.attach(b,trace)
 trace.vitalsVersion=1;trace.vitals={initial={},events={},final={}}
 local data=trace.vitals;local closed=false
 local function actor(u)
  if u==b.mentor then return 'mentor'end
  for _,a in ipairs(b.learners)do if u==a.student then return a.character.id end end
  return 'unknown'
 end
 local function enemy(u)for i,e in ipairs(b.enemies)do if e.enemy==u then return 'enemy:'..i end end;return 'unknown'end
 local targets=b.targets
 for _,t in ipairs(targets(b))do data.initial[actor(t.unit)]=t.hp()end
 b.targets=function(self,...)
  local list=targets(self,...)
  for _,t in ipairs(list)do
   local damage=t.damage
   t.damage=function(n,context)
    local before=t.hp();local result=damage(n,context);local after=t.hp()
    if not closed and before~=after then
     if #data.events>=trace.limit then trace.truncated=true else
      context=context or {}
      data.events[#data.events+1]={actor=actor(t.unit),before=before,after=after,damage=math.max(0,before-after),healing=math.max(0,after-before),requested=n,at=D.App.runningTime,phase=b.phase,
       kind=context.kind or 'unknown',attacker=enemy(context.attacker),skill=context.skill,weapon=context.weapon,weaponOwner=context.weaponOwner,shotAt=context.shotAt,strikeStarted=context.strikeStarted}
     end
    end
    return result
   end
  end
  return list
 end
 local function close()
  if closed then return end;closed=true
  for _,t in ipairs(targets(b))do data.final[actor(t.unit)]=t.hp()end
  local hp={};for id,n in pairs(data.initial)do hp[id]=n end
  data.damage=0;data.healing=0;data.continuous=not trace.truncated
  for _,e in ipairs(data.events)do if hp[e.actor]~=e.before then data.continuous=false end;hp[e.actor]=e.after;data.damage=data.damage+e.damage;data.healing=data.healing+e.healing end
  for id,n in pairs(data.final)do if hp[id]~=n then data.continuous=false end end
 end
 b.world:slot('Cleanup',close)
 return {finish=close}
end
function V.review(data)
 local function number(n)return type(n)=='number'and n==n and math.abs(n)<100000000 end
 if type(data)~='table'or type(data.initial)~='table'or type(data.final)~='table'or type(data.events)~='table'or #data.events>2000 then return nil,'INVALID_VITALS'end
 local hp={};for _,id in ipairs({'mentor','ninilite','wuyun'})do local n=data.initial[id];if not number(n)or n<0 or not number(data.final[id])then return nil,'INVALID_VITALS'end;hp[id]=n end
 local r={damage=0,healing=0,byKind={},byActor={}};local at=-math.huge
 local count=0;for k in pairs(data.events)do if type(k)~='number'or k%1~=0 or k<1 or k>#data.events then return nil,'INVALID_VITALS'end;count=count+1 end
 if count~=#data.events then return nil,'INVALID_VITALS'end
 for _,e in ipairs(data.events)do
  if type(e)~='table'or hp[e.actor]==nil or hp[e.actor]~=e.before or not number(e.after)or e.after<0 or not number(e.at)or e.at<at or e.damage~=math.max(0,e.before-e.after)or e.healing~=math.max(0,e.after-e.before)then return nil,'INCOMPLETE_VITALS'end
  if e.kind~='enemy-melee'and e.kind~='stolen-firearm'and e.kind~='unknown'then return nil,'UNKNOWN_DAMAGE_SOURCE'end
  hp[e.actor]=e.after;at=e.at;r.damage=r.damage+e.damage;r.healing=r.healing+e.healing;r.byKind[e.kind]=(r.byKind[e.kind]or 0)+e.damage;r.byActor[e.actor]=(r.byActor[e.actor]or 0)+e.damage
 end
 for id,n in pairs(hp)do if data.final[id]~=n then return nil,'INCOMPLETE_VITALS'end end
 return r
end
return V
