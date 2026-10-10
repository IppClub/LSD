-- Observable authored clip progress only; hidden actors expose no timing.
local M={}
local T=require('Enemy.BigYingzhaoTimeline')
local skills={punch=true,massive=true,wave=true,hunt=true,hero=true}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function remaining(raw,at)
 if type(raw)~='table'or not skills[raw.skill]or not finite(raw.stage)or raw.stage%1~=0 or not finite(raw.started)or not finite(raw.duration)or raw.duration<=0 or not finite(at)or raw.started>at then return nil end
 local stage=T.stages(raw.skill)[raw.stage];if not stage then return nil end
 local elapsed=at-raw.started
 if elapsed>raw.duration+2 then return nil end
 if not stage.impacts or #stage.impacts==0 then return 'unknown'end
 for _,impact in ipairs(stage.impacts or {})do
  if impact>raw.duration then return nil end
  if impact>=elapsed then return impact-elapsed end
 end
 return 'recovery'
end
function M.project(raw,at)
 local lead=remaining(raw,at)
 if type(lead)=='number'then return lead>.45 and'early'or'imminent'end
 return lead
end
-- Decision-time distance to the next authored impact, not a promise of safety.
function M.impactLead(s)
 if not s.bossVisible then return 'unknown'end
 if not s.bossTiming then return 'idle'end
 local lead=remaining(s.bossTiming,s.at)
 if type(lead)=='number'then return lead<=.2 and'urgent'or lead<=.45 and'near'or'ahead'end
 return lead
end
function M.capture(guard,visible,at)
 if not visible then return nil,'unknown'end
 local s=guard.sequence
 if not s or s.status~='playing'then return nil,'idle'end
 local raw={skill=guard.strike and guard.strike.skill,stage=s.index,started=s.started,duration=s.duration}
 return raw,M.project(raw,at)or'unknown'
end
-- A current clip's recovery does not imply the authored skill has finished.
-- This reports visible authored timing only, never guarantees a safe crossing.
function M.recoveryTail(raw,at)
 local lead=remaining(raw,at)
 if lead~='recovery'then return nil,lead end
 local stages=T.stages(raw.skill)
 for i=raw.stage+1,#stages do
  if #(stages[i].impacts or {})>0 then return nil,'follow-up'end
 end
 local tail=raw.duration-(at-raw.started)
 if tail<=0 then return nil,'ended'end
 return tail,'recovery'
end
function M.validate(s)
 if not s.bossVisible then return s.bossTiming==nil and s.bossWindow=='unknown'end
 if not s.bossTiming then return s.bossWindow=='idle'end
 return M.project(s.bossTiming,s.at)==s.bossWindow
end
return M
