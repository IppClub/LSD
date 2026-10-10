-- Authored support AI, distinct from learned student decisions and player input.
local T={}
function T.plan(x,bossX,strike,minX,maxX,previous,spec)
 local delta=bossX-x;local distance=math.abs(delta);local toward=delta>=0 and 1 or -1
 if strike then
  spec=spec or require('Ground.BossCombat').specs[strike.kind]
  if spec and spec.knockX then
   local direction=(strike.direction or toward)*(spec.rear and -1 or 1)
   local exposed=(x-bossX)*direction>=0 or strike.kind=='rush'
   if exposed then
    if distance>=spec.range+140 then return {mode='hold',speed=0,face=toward,reason='outside-threat'}end
    local move=-toward;local room=move<0 and x-minX or maxX-x
    if room>25 then return {mode='evade',direction=move,speed=280,face=toward,reason=strike.kind}end
    return {mode='hold',speed=0,face=toward,reason='boundary'}
   end
  end
 end
 local approach=distance>(previous=='approach'and 310 or 360)
 if approach then
  local room=toward<0 and x-minX or maxX-x
  if room>25 then return {mode='approach',direction=toward,speed=180,face=toward,reason='melee-range'}end
  return {mode='hold',speed=0,face=toward,reason='boundary'}
 end
 return {mode='attack',speed=0,face=toward,reason='in-range'}
end
function T.move(unit,plan)
 unit.faceRight=plan.face>0;unit.velocityX=(plan.direction or 0)*plan.speed
 local Animation=require('CombatAnimation')
 if plan.speed>0 then
  local animation=plan.mode=='evade'and'bmove'or'fmove'
  if unit.playable.current~=animation then Animation.play(unit,animation,true)end
 else Animation.rest(unit)end
end
return T
