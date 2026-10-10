local D=require('Dora');local A=require('CombatAnimation');local Sequence=require('Enemy.Sequence')
local Ambush={warningDuration=1.0}
function Ambush.start(b,e,spec)
 if e.busy or e.hp<=0 or b.phase~='playing' then return false end
 local u=e.unit;u:stop();u.velocityX=0;u.faceRight=b.mentor.x>=u.x;e.busy=true;b.ambushActive=true
 local origin=u.position;local group=u.group;local acceleration=u.linearAcceleration
 local strike={kind='ambush',started=D.App.runningTime,hits=0,impacts={},stages={},targetX=b.mentor.x}
 e.strikes[#e.strikes+1]=strike
 local portal=require('Enemy.ShadowPortal').new(u);local warning=D.DrawNode();warning.order=30;warning:addTo(b.world)
 strike.portal=portal;strike.warning=warning
 local landed=false;local closed=false
 local function cleanup()
  if closed then return end;closed=true;b.ambushActive=false;portal:close();warning:removeFromParent()
  e.untargetable=false
  if b.world.parent and u.parent then
   u.group=group;u.linearAcceleration=acceleration;u.velocityX=0
   if not landed then u.position=origin;u.velocityY=0 end
  end
 end
 local sequence=Sequence.new({now=function()return D.App.runningTime end,
  play=function(name)
   if name=='ambush2' then
    -- Authored palm offset at the landing pose, transformed by actual model scale.
    local palmX=498.0618*math.abs(u.playable.scaleX)*(u.faceRight and 1 or -1)
    u.position=D.Vec2(strike.targetX-palmX,b.world.offset+155);u.velocityY=0
    u.group=D.Platformer.Data.groupHide;u.linearAcceleration=D.Vec2.zero;e.untargetable=true;landed=true
   end
   u.data.combatCompletedName='';u.data.combatCompletedAt=-1
   local duration=A.play(u,name,false)
   strike.stages[#strike.stages+1]={name=name,started=D.App.runningTime,duration=duration};return duration
  end,
  impact=function()
   if b.phase~='playing' or e.hp<=0 then return end
   u.group=group;u.linearAcceleration=acceleration;e.untargetable=false
   local point=require('Enemy.BigShanRelease').point(u,b.world);strike.impactX=point.x;strike.impactY=point.y
   strike.impacts[#strike.impacts+1]=D.App.runningTime-strike.started
   local targets={b.mentor};for _,escort in ipairs(b.escorts)do targets[#targets+1]=escort.unit end
   for _,target in ipairs(targets)do
    if math.abs(target.x-point.x)<=spec.range and math.abs(target.y-(b.world.offset+155))<240 then
     if b:inSmoke(target.x)then b.smokeBlockedAttacks=b.smokeBlockedAttacks+1
     elseif b:damageFriendly(target,spec.damage,spec.stamina)then strike.hits=strike.hits+1 end
    end
   end
   warning:clear();warning:drawSegment(D.Vec2(point.x-spec.range,b.world.offset+12),D.Vec2(point.x+spec.range,b.world.offset+12),10,D.Color(0xffeab985))
  end,
  complete=function()strike.completed=D.App.runningTime;cleanup()end,
  stop=function(reason)strike.cancelled=reason;strike.cancelledAt=D.App.runningTime;cleanup();if e.hp>0 and b.world.parent and u.parent then A.rest(u)end end})
 -- Latch and show the landing zone before the authored portal clips begin.
 -- At the tutorial's half-speed backstep, the old 1.4-second window could
 -- not clear this 260-unit impact radius. Keep clip speed and impact unchanged.
 local preparing=true
 local preparation={}
 function preparation:cancel(reason)
  if not preparing then return false end
  preparing=false;strike.cancelled=reason;strike.cancelledAt=D.App.runningTime
  cleanup();if e.hp>0 and b.world.parent and u.parent then A.rest(u)end
  return true
 end
 e.attackSequence=preparation
 A.rest(u)
 local function drawWarning()
  warning:clear();local pulse=4+2*math.sin((D.App.runningTime-strike.started)*12)
  warning:drawSegment(D.Vec2(strike.targetX-spec.range-50,b.world.offset+12),D.Vec2(strike.targetX+spec.range+50,b.world.offset+12),pulse,D.Color(0xffea785c))
 end
 drawWarning();strike.warningStarted=D.App.runningTime
 D.thread(function()
  while preparing and D.App.runningTime-strike.warningStarted<Ambush.warningDuration do
   if b.phase~='playing' or e.hp<=0 or not u.parent then preparation:cancel('BATTLE_ENDED');break end
   if D.App.runningTime<e.stunUntil then preparation:cancel('STUNNED');break end
   u.velocityX=0;drawWarning();D.sleep(.01)
  end
  if preparing then
   preparing=false;e.attackSequence=sequence;strike.animationStarted=D.App.runningTime
   sequence:start({{name='ambush1'},{name='ambush2',impacts={.4}}})
  end
  while sequence.status=='playing' do
   if b.phase~='playing' or e.hp<=0 or not u.parent then sequence:cancel('BATTLE_ENDED');break end
   if D.App.runningTime<e.stunUntil then sequence:cancel('STUNNED');break end
   local stage=sequence.stages[sequence.index];local elapsed=D.App.runningTime-sequence.started
   u.velocityX=0
   if stage.name=='ambush1' and elapsed>=.7 then u.group=D.Platformer.Data.groupHide;u.linearAcceleration=D.Vec2.zero;u.velocityY=0;e.untargetable=true end
   local opacity=stage.name=='ambush1' and math.min(1,elapsed/.15,math.max(0,(1-elapsed)/.25)) or math.max(0,1-elapsed/.4)
   portal:update(opacity)
   if stage.name=='ambush2' and elapsed>0 and #strike.impacts==0 then
    -- Keep the falling palm over the latched warning despite authored lateral
    -- root motion and frame overshoot at the impact event. Stop anchoring once
    -- it hits, so recovery retains the original hand motion.
    local palm=require('Enemy.BigShanRelease').point(u,b.world)
    u.x=u.x+strike.targetX-palm.x
   end
   if #strike.impacts==0 then
    drawWarning()
   end
   if u.data.combatCompletedName==stage.name and (u.data.combatCompletedAt or -1)>=sequence.started then sequence:ended(stage.name,sequence.serial,sequence.index)end
   sequence:update();D.sleep(.01)
  end
  cleanup();if b.world.parent and u.parent then u.velocityX=0 end;e.busy=false;e.nextAttack=D.App.runningTime+1.2
  if b.phase=='playing' and e.hp>0 and b.world.parent and u.parent then A.rest(u)end
 end)
 return true
end
return Ambush
