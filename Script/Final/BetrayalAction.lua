-- Native authored attack event drives impact; no elapsed-time shortcut ends a pose.
local D=require('Dora');local Action={}
function Action.playAsync(c)
 local lin,mentor=c.lin,c.mentor;local report={version=1,mentor=c.mentorAsset};c.actionReport=report
 local function wait(f,seconds)
  local deadline=D.App.runningTime+seconds
  while not f()do
   if c.closed then return false end
   -- The engine swallows thread errors; continue instead of a silent stall.
   if D.App.runningTime>=deadline then print('FinalBetrayalAction: native animation did not finish, continuing')break end
   D.sleep(.01)
  end
  return not c.closed
 end
 local ends={};local function track(m,key)m:slot('AnimationEnd',function(name)ends[key..':'..name]=D.App.runningTime end)end
 track(lin,'lin');track(mentor,'mentor')
 lin.speed=1;lin.recovery=.2;lin.fliped=false;lin:play('fmove',true)
 local from=lin.x;local began=D.App.runningTime
 while lin.x<mentor.x-160 do
  if c.closed then return end
  lin.x=math.min(mentor.x-160,lin.x+140*D.App.deltaTime);D.sleep()
 end
 report.approach={distance=lin.x-from,seconds=D.App.runningTime-began,endX=lin.x,mentorX=mentor.x}
 lin:play('prepare',true);D.sleep(.25);if c.closed then return end
 mentor.fliped=true;mentor.recovery=.2;mentor.speed=1
 local attack=function()
  if c.closed or report.impactAt or not report.attackStarted then return end
  report.impactAt=D.App.runningTime;report.impactDistance=math.abs(lin.x-mentor.x)
  report.hitStarted=D.App.runningTime;report.hitDuration=mentor:play('hit',false)
  if c.onImpact then c.onImpact()end
 end
 lin:slot('attack',attack)
 report.attackStarted=D.App.runningTime;report.attackDuration=lin:play('melee',false);assert(report.attackDuration>0)
 if not wait(function()return ends['lin:melee']and ends['lin:melee']>=report.attackStarted end,report.attackDuration+2)then lin:slot('attack'):remove(attack);return end
 report.attackEnded=ends['lin:melee'];lin:slot('attack'):remove(attack);assert(report.impactAt,'Sunborn melee has no authored attack event')
 assert(report.hitDuration>0);if not wait(function()return ends['mentor:hit']and ends['mentor:hit']>=report.hitStarted end,report.hitDuration+2)then return end
 report.hitEnded=ends['mentor:hit'];lin.recovery=.2;lin:play('prepare',true)
 report.fallStarted=D.App.runningTime;report.fallDuration=mentor:play('finalCollapse',false);assert(report.fallDuration>0)
 if not wait(function()return ends['mentor:finalCollapse']and ends['mentor:finalCollapse']>=report.fallStarted end,report.fallDuration+2)then return end
 report.fallEnded=ends['mentor:finalCollapse'];mentor.speed=0;report.held=true
 return report
end
return Action
