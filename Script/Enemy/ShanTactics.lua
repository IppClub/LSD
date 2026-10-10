-- Authored thresholds overlap at two other small allies: support takes priority.
local T={radius=900}
function T.context(actor,enemies)
 local boss,others=false,0
 for _,e in ipairs(enemies)do
  if e~=actor and e.hp>0 and math.abs(e.unit.x-actor.unit.x)<=T.radius then
   if e.asset=='dashanxiao' then boss=true else others=others+1 end
  end
 end
 return {boss=boss,others=others,supported=boss or others>=2}
end
function T.choose(context,distance,sequence)
 if context.supported then return ({'litter',distance<195 and 'scratch' or 'throw','rush'})[(sequence-1)%3+1]end
 if distance<260 and not context.boss and context.others<3 and sequence%2==1 then return 'evade'end
 return distance<195 and 'scratch' or 'throw'
end
return T
