-- Actual party HP changes through the encounter's damage callbacks. Keep this
-- outcome stream separate from the decision-time feature projection.
local D=require('Dora');local M={version=1}
local function snapshot(b)return {mentor=b.mentorHP,ninilite=b.arena.studentHP,wuyun=b.wuyun.studentHP}end
local pending=setmetatable({},{__mode='k'})
local function append(v,e)
 if #v.events>=1500 then v.truncated=true else v.events[#v.events+1]=e end
end
function M.flush(v)
 local state=pending[v];if not state then return end
 local rows={};for _,e in pairs(state.rows)do rows[#rows+1]=e end
 table.sort(rows,function(a,b)return a.at==b.at and a.actor<b.actor or a.at<b.at end)
 for _,e in ipairs(rows)do append(v,e)end
 state.rows={};state.last=D.App.runningTime
end
function M.record(v,actor,before,after,context)
 if v.closed or before==after then return end
 local kind=context and context.kind or 'unknown'
 local e={at=D.App.runningTime,actor=actor,before=before,after=after,damage=math.max(0,before-after),kind=kind,skill=context and context.skill or 'unknown'}
 if context and context.attackerId then e.attackerId=context.attackerId;e.strikeStarted=context.strikeStarted;e.hitIndex=context.hitIndex end
 if v.schemaVersion==2 then e.healing=math.max(0,after-before)end
 if context and context.physicalShieldEvent then
  e.at=context.physicalShieldEvent.at;e.physicalShieldEvent=context.physicalShieldEvent.index
 end
 if v.schemaVersion==2 and (kind=='support-heal'or kind=='support-hazard')then
  local state=pending[v];if not state then state={rows={},last=D.App.runningTime};pending[v]=state end
  local previous=state.rows[actor]
  if previous and (previous.kind~=kind or previous.after~=before)then M.flush(v);previous=nil end
  if previous then previous.after=after;previous.at=e.at;previous.damage=math.max(0,previous.before-after);previous.healing=math.max(0,after-previous.before)
  else state.rows[actor]=e end
  if D.App.runningTime-state.last>=.5 then M.flush(v)end
 else M.flush(v);append(v,e)end
end

function M.attach(b)
 local v={schemaVersion=1,events={}};b.bossTrace.vitals=v
 local start=b.start
 b.start=function(self,...)
  local ok,why=start(self,...);if ok then v.initial=snapshot(self);v.started=D.App.runningTime end;return ok,why
 end
 local targets=b.targets
 b.targets=function(self)
  local list=targets(self)
  for _,target in ipairs(list)do
   local damage=target.damage
   target.damage=function(n,context)
    local before=target.hp();local result=damage(n,context);local after=target.hp()
    local actor=target.unit==self.mentor and'mentor'or target.unit==self.arena.student and'ninilite'or target.unit==self.wuyun.student and'wuyun'
    if actor then M.record(v,actor,before,after,context)end
    return result
   end
  end
  return list
 end
 return function()
  if v.closed then return end
  M.flush(v);pending[v]=nil;v.initial=v.initial or snapshot(b);v.started=v.started or D.App.runningTime;v.final=snapshot(b);v.finished=D.App.runningTime;v.closed=true
 end
end
local function hp(n)return type(n)=='number'and n==n and n>=0 and n<=100 end
local function close(a,b)return type(a)=='number' and a==a and math.abs(a-b)<=1e-6 end
function M.validate(v)
 if type(v)~='table'or (v.schemaVersion~=1 and v.schemaVersion~=2) or not v.closed or v.truncated or type(v.initial)~='table'or type(v.final)~='table'or type(v.events)~='table'or #v.events>1500 or type(v.started)~='number'or type(v.finished)~='number'or v.started~=v.started or v.finished~=v.finished or v.finished<v.started then return false end
 local current={};for _,actor in ipairs({'mentor','ninilite','wuyun'})do if not hp(v.initial[actor])or not hp(v.final[actor])then return false end;current[actor]=v.initial[actor]end
 local at=v.started
 for _,e in ipairs(v.events)do
  if type(e)~='table'or not current[e.actor]or not hp(e.before)or not hp(e.after)or (v.schemaVersion==1 and e.before~=current[e.actor]) or (v.schemaVersion==2 and not close(e.before,current[e.actor]))or (v.schemaVersion==1 and (e.after>e.before or e.damage~=e.before-e.after)) or (v.schemaVersion==2 and (not hp(e.damage) or not hp(e.healing) or not close(e.damage,math.max(0,e.before-e.after)) or not close(e.healing,math.max(0,e.after-e.before)) or (e.healing>0 and (e.kind~='support-heal' or e.skill~='life-support')))) or type(e.at)~='number'or e.at~=e.at or e.at<at or e.at>v.finished then return false end
  if e.attackerId~=nil or e.strikeStarted~=nil or e.hitIndex~=nil then
   if type(e.attackerId)~='string'or e.attackerId==''or #e.attackerId>128 or type(e.strikeStarted)~='number'or e.strikeStarted~=e.strikeStarted or math.abs(e.strikeStarted)==math.huge or e.strikeStarted>e.at or type(e.hitIndex)~='number'or e.hitIndex~=e.hitIndex or math.abs(e.hitIndex)==math.huge or e.hitIndex<1 or e.hitIndex%1~=0 then return false end
  end
  current[e.actor]=e.after;at=e.at
 end
 for actor,value in pairs(current)do if (v.schemaVersion==1 and value~=v.final[actor])or(v.schemaVersion==2 and not close(value,v.final[actor]))then return false end end
 return true
end
return M
