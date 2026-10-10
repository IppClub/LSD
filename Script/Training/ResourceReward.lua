-- Whole-episode normalization for verified online decision intervals.
-- This does not invent successor states from the interleaved attack journal.
local R={policy='mission-resources-v1',version=1}
local function number(n)return type(n)=='number' and n==n and n>=0 and n<math.huge end
function R.calculate(rows,status,budget)
 if type(rows)~='table' or #rows==0 or not number(budget) or budget<=0 or not ({won=true,failed=true,aborted=true})[status]then return nil,'INVALID_RESOURCE_REWARD_INPUT'end
 local total={progress=0,harm=0,duration=0,cost=0}
 for _,row in ipairs(rows)do
  if type(row)~='table'then return nil,'INVALID_RESOURCE_REWARD_ROW'end
  for _,key in ipairs({'progress','harm','duration','cost'})do if not number(row[key])then return nil,'INVALID_RESOURCE_REWARD_ROW'end;total[key]=total[key]+row[key]end
 end
 for _,value in pairs(total)do if not number(value)then return nil,'INVALID_RESOURCE_REWARD_TOTAL'end end
 if total.cost>budget then return nil,'COST_EXCEEDS_RESERVED_BUDGET'end
 local rewards={};local sum=0
 -- Across all intervals: progress <=2, harm <=2, time <=1, cost <=1.
 -- Thus every completed win >=6, every failure/withdrawal <=-8, before discount.
 for i,row in ipairs(rows)do
  local components={progress=row.progress/math.max(1,total.progress)*2,harm=-row.harm/math.max(1,total.harm)*2,
   duration=-row.duration/math.max(1,total.duration),cost=-row.cost/budget,terminal=i==#rows and (status=='won' and 10 or -10)or 0}
  -- Fixed order is required for model reconstruction across Lua hash seeds.
  local value=0;for _,name in ipairs({'progress','harm','duration','cost','terminal'})do value=value+components[name]end
  rewards[i]={value=value,components=components};sum=sum+value
 end
 return {policy=R.policy,version=1,rows=rewards,total=sum,normalization=total,budget=budget,status=status}
end
return R
