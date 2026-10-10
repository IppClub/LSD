-- Terminal projectile facts; these never turn a planned aim into a promised hit.
local M={}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function point(p)return type(p)=='table'and finite(p.x)and finite(p.y)end
function M.validate(trace)
 if trace.flightVersion==nil and trace.flights==nil then return true end
 if trace.flightVersion~=1 or type(trace.flights)~='table'or #trace.flights>1500 then return false end
 local hits={};for _,h in ipairs(trace.hits or {})do hits[h.attackId]=h end
 local ids={};local counts={};local previous=-math.huge
 for _,f in ipairs(trace.flights)do
  if type(f)~='table'or type(f.id)~='string'or ids[f.id]or not ({mentor=true,ninilite=true,wuyun=true})[f.actor]or not finite(f.started)or f.started<previous or not finite(f.ended)or f.ended<f.started or not point(f.origin)or not point(f.position)or not point(f.velocity)or not ({contact=true,terrain=true,removed=true,['battle-ended']=true,['contact-rejected']=true})[f.reason]then return false end
  local step=f.step and trace.steps and trace.steps[f.step]
  local kind=f.kind or 'firearm'
  if kind~='firearm'and kind~='fire'then return false end
  if not step or step.actor~=f.actor or step.action~=(kind=='fire'and'fire'or'shoot')or step.emitted~=1 or f.started<step.started or step.ended and f.started>step.ended then return false end
  if kind=='fire'and (f.actor~='ninilite'or not step.skill or not finite(step.skill.releaseAt)or f.started<step.skill.releaseAt)then return false end
  local hit=hits[f.id]
  if f.reason=='contact'then
   if not hit or hit.source~=f.actor or hit.step~=f.step or hit.target~=f.target or hit.part~=f.part or hit.at<f.started or hit.at>f.ended then return false end
  elseif hit or f.target~=nil or f.part~=nil then return false end
  counts[f.step]=(counts[f.step]or 0)+1;ids[f.id]=true;previous=f.started
 end
 for i,step in ipairs(trace.steps or {})do
  if step.action=='shoot'or step.action=='fire'then
   local expected=(step.emitted or 0)*(step.action=='fire'and 3 or 1)
   if (counts[i]or 0)~=expected then return false end
  end
 end
 -- Every recorded firearm contact must belong to its actual travelled shot.
 for id,h in pairs(hits)do if id:match('^yingzhao%-shot%-')and not ids[id]then return false end end
 return true
end
return M
