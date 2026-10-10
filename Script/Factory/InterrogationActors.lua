-- Paired interrogation choreography on each character's original rig.
-- The caller owns story progression; this component never writes progress.
local D=require('Dora')
local Actors={};Actors.__index=Actors
Actors.wuyunAsset='Spine/StoryActions/wuyun.skel|Spine/wuyun.atlas'
Actors.researcherAsset='Spine/StoryActions/researcher.skel|Spine/shujuyuan.atlas'
function Actors.new(parent)
 local self=setmetatable({node=D.Node(),phase='ready',alive=true,events={}},Actors)
 self.node:addTo(parent)
 self.researcher=assert(D.Spine(Actors.researcherAsset));self.researcher:addTo(self.node)
 self.wuyun=assert(D.Spine(Actors.wuyunAsset));self.wuyun.order=1;self.wuyun:addTo(self.node)
 self.researcher.recovery=0;self.researcher:play('restrained',true)
 -- Authored coverHold contact: actual native point on Wuyun's left-facing palm.
 self.holdPalm=D.Vec2(-100.691658,192.831619)
 self.wuyun.x=115.24;self.wuyun.recovery=0;self.wuyun:play('idle',true)
 self.wuyun:slot('AnimationEnd',function(name)
  local active=self.active
  if active and active.name==name and D.App.runningTime-active.started>=active.duration-.035 then active.ended=D.App.runningTime end
 end)
 self.node:slot('Cleanup',function()self.alive=false;self.active=nil end)
 return self
end
function Actors:contact()
 local m=self.researcher:getKey('contact:mouth/mouth');local p=self.wuyun:getKey('s:melee/s:melee')
 return D.Vec2(self.researcher.x+m.x,self.researcher.y+m.y),D.Vec2(self.wuyun.x+p.x,self.wuyun.y+p.y)
end
function Actors:finiteAsync(name)
 if not self.alive then return nil,'CANCELLED' end
 self.active=nil;self.wuyun.recovery=0
 local duration=self.wuyun:play(name,false);assert(duration>0,'Missing interaction animation: '..name)
 local active={name=name,started=D.App.runningTime,duration=duration};self.active=active
 while self.alive and not active.ended do
  assert(D.App.runningTime-active.started<duration+2,'Interaction animation did not finish: '..name)
  D.sleep(.02)
 end
 if not self.alive then return nil,'CANCELLED' end
 self.active=nil;self.events[#self.events+1]=active;return true
end
function Actors:coverAsync()
 if self.phase~='ready' then return nil,'BUSY' end
 self.phase='reaching'
 -- Spine applies a newly played pose on the next frame; never align to setup.
 D.sleep(.02);if not self.alive then return nil,'CANCELLED' end
 local mouth=self.researcher:getKey('contact:mouth/mouth')
 self.wuyun.x=self.researcher.x+mouth.x-self.holdPalm.x
 local ok,err=self:finiteAsync('coverReach');if not ok then return nil,err end
 self.phase='holding';self.wuyun.recovery=0;self.wuyun:play('coverHold',true)
 return true
end
function Actors:releaseAsync()
 if self.phase~='holding' then return nil,'NOT_HOLDING' end
 self.phase='releasing'
 local ok,err=self:finiteAsync('coverRelease');if not ok then return nil,err end
 self.wuyun.recovery=.15;self.wuyun:play('idle',true);self.phase='ready'
 return true
end
function Actors:addCompanions(name)
 assert(name=='charM' or name=='charF')
 self.mentorName=name
 self.mentor=assert(D.Spine('Spine/StoryActions/'..name..'.skel|Spine/'..name..'.atlas'))
 self.mentor.x=-240;self.mentor.order=2;self.mentor:addTo(self.node);self.mentor:play('idle',true)
 self.mentorContact=D.json.decode(assert(D.Content:load('Spine/StoryActions/'..name..'-hand-fit.json')))
 require('Story.FoxCompanion').loadAnimatedAsync();self.fox=require('Story.FoxCompanion').createAnimated()
 self.fox.x=-470;self.fox.fliped=true;self.fox:addTo(self.node)
 self.threat=require('Story.FoxSpineThreat').attach(self.fox)
end
function Actors:warnAsync()
 assert(self.threat,'Companions must be attached')
 local began=D.App.runningTime;local ok,err=self.threat:warnAsync()
 if ok then self.events[#self.events+1]={name='foxWarning',started=began,ended=D.App.runningTime,duration=1.2}end
 return ok,err
end
function Actors:slapAsync()
 if self.phase~='ready' then return nil,'BUSY'end
 assert(self.mentor,'Companions must be attached');self.phase='approaching'
 local function walk(actor,target)
  local from=actor.x;local duration=math.abs(target-from)/150
  actor.recovery=.15;actor:play('fmove',true)
  local started=D.App.runningTime
  while self.alive and D.App.runningTime-started<duration do actor.x=from+(target-from)*math.min(1,(D.App.runningTime-started)/duration);D.sleep(.02)end
  if not self.alive then return nil end
  actor.x=target;actor.recovery=.15;actor:play('idle',true);return true
 end
 -- Wuyun lets go and makes room before the mentor steps toward the researcher.
 self.wuyun.fliped=true;if not walk(self.wuyun,310) then return nil,'CANCELLED'end
 self.wuyun.fliped=false;self.researcher.fliped=true;D.sleep(.02)
 local mouth=self.researcher:getKey('contact:mouth/mouth')
 if not walk(self.mentor,self.researcher.x+mouth.x-self.mentorContact.palmX) then return nil,'CANCELLED'end
 self.phase='slapping'
 local log={name='mentorSlap',mentor=self.mentorName};self.slapLog=log
 local active=false;local mentorEnded,researchEnded
 self.mentor:slot('interrogationSlap',function()
  if not active or log.impact then return end
  log.impact=D.App.runningTime
  self.researcher.speed=1;self.researcher.recovery=.15
  log.fallDuration=self.researcher:play('knockout',false)
 end)
 self.mentor:slot('AnimationEnd',function(name)
  if active and name=='interrogationSlap' and D.App.runningTime-log.started>=.865 then mentorEnded=D.App.runningTime end
 end)
 self.researcher:slot('AnimationEnd',function(name)
  if active and name=='knockout' and log.impact and D.App.runningTime-log.impact>=log.fallDuration-.04 then researchEnded=D.App.runningTime end
 end)
 self.mentor.speed=1;self.mentor.recovery=0;log.duration=self.mentor:play('interrogationSlap',false)
 log.started=D.App.runningTime;active=true
 while self.alive and not(mentorEnded and researchEnded)do
  assert(D.App.runningTime-log.started<5,'Slap choreography did not finish');D.sleep(.02)
 end
 active=false;if not self.alive then return nil,'CANCELLED'end
 log.ended=mentorEnded;log.fallEnded=researchEnded
 self.mentor.recovery=.15;self.mentor:play('idle',true)
 self.researcher.recovery=0;self.researcher:play('unconscious',true)
 self.phase='unconscious';self.events[#self.events+1]=log;return true
end
return Actors
