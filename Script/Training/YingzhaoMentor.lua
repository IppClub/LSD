-- Shared, visible-observation-only mentor assistance for training/evaluation.
local M={version='mentor-range-fire-wind-v14'}
function M.new(options)
 local actors={};for _,actor in ipairs(options and options.independentActors or {})do actors[actor]=true end
 return {independentActor=options and options.independentActor,independentActors=actors}
end
-- Enter cover at close range; retain it across a short retreat. Release only
-- when the visible reinforcement is dead/hidden or safely separated from all allies.
local function reinforcementPriority(b,state)
 state=state or b.yingzhaoMentorCover
 if not state then state={};b.yingzhaoMentorCover=state end
 local previous=state.reinforcements or {};local current={};local urgent=false
 for _,enemy in ipairs(b.enemies)do
  if enemy~=b.bossCombat.boss and enemy.enemyHP>0 and enemy.enemy.visible and enemy.enemy.opacity>.1 then
   local distance=math.huge
   for _,target in ipairs(b:targets())do
    if target.hp()>0 then distance=math.min(distance,math.abs(target.unit.x-enemy.enemy.x))end
   end
   if distance<=350 or previous[enemy]and distance<=700 then current[enemy]=true;urgent=true end
  end
 end
 state.reinforcements=current
 return urgent
end
function M.shoot(b,state)
 local urgent=reinforcementPriority(b,state)
 if not b.mentorAim.canStart()then return false,'AIM_UNAVAILABLE'end
 local observed=b.observeYingzhao(b.mentor);local parts={};local used={}
 if urgent then parts[#parts+1]='summon';used.summon=true end
 for _,part in ipairs(require('Training.YingzhaoFeatures').parts)do
  if observed['part_'..part]=='exposed'then parts[#parts+1]=part;used[part]=true end
 end
 for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank','summon'})do if not used[part]then parts[#parts+1]=part end end
 for _,part in ipairs(parts)do
  local aim=require('Training.YingzhaoActions').plan(b,{student=b.mentor},part)
  if aim then
   b.mentorPartAim=aim;b.mentorActionOrigin='mentor-assistance'
   local ok,why=b.mentorAim:fireAt(aim.angle,aim.faceRight)
   b.mentorPartAim=nil;b.mentorActionOrigin=nil
   return ok,why
  end
 end
 return false,'NO_REACHABLE_PART'
end
function M.step(b,state)
 if b.phase~='playing'then return end
 reinforcementPriority(b,state)
 -- Evaluation assistance must not take control of the learners' locomotion.
 -- The public manual gather command remains available to the player.
 local target=b:target(b.mentor)
 if target then
  local boss=b.bossCombat.boss
  local visible=b.bossCombat.armor:available()
  -- A nearby summon must not lure the ranged mentor back into Boss melee.
  local anchor=visible and boss or target
  local dx=anchor.enemy.x-b.mentor.x
  local minX,maxX=b.minX or 1200,b.maxX or 3300
  local near,far=visible and 1250 or 350,visible and 1550 or 600
  if not visible then state.flank=nil end
  if state.flank and ((b.mentor.x-anchor.enemy.x)*state.flank>=near or (state.flank>0 and b.mentor.x>=maxX-50)or(state.flank<0 and b.mentor.x<=minX+50))then state.flank=nil end
  if visible and not state.flank and math.abs(dx)<near and ((dx>0 and b.mentor.x<=minX+80)or(dx<0 and b.mentor.x>=maxX-80))then state.flank=dx>0 and 1 or -1 end
  local escape=require('Enemy.GroundWave').escapeDirection(boss.guard,b.mentor,visible)
  if escape then
   -- A valid firing distance can still be inside the wave's finite reach.
   -- Retreat on the visible cue; do not cross toward the Boss to change flank.
   state.flank=nil
   local room=escape>0 and maxX-b.mentor.x or b.mentor.x-minX
   if room<=20 then
    -- The arena clamp makes further retreat impossible. Use a real reachable
    -- shot instead of holding the wall while reinforcements attack.
    b:command('stop');M.shoot(b,state)
   else b:command(escape>0 and'right'or'left')end
  elseif state.flank then b:command(state.flank>0 and'right'or'left')
  elseif math.abs(dx)>far then b:command(dx>0 and'right'or'left')
  elseif math.abs(dx)<near then b:command(dx>0 and'left'or'right')
  else b:command('stop');M.shoot(b,state)end
  -- Do not queue an automatic cast behind an attack: that queue can release
  -- during a later dodge. Manual commands retain their existing semantics.
  for _,entry in ipairs({{name='fire',arena=b.arena},{name='wind',arena=b.wuyun}})do
   local a=entry.arena
   if a and a.character.id~=state.independentActor and not (state.independentActors and state.independentActors[a.character.id])and a.studentHP>0 and not a:isAttacking()and not a.student:isDoing(a.physical.fmove)and not a.student:isDoing(a.physical.bmove)and b.observeYingzhao(a.student).threat=='none'then
    b:command(entry.name)
   end
  end
 else state.flank=nil;b:command('stop')end

end
return M
