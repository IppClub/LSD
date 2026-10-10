-- Whole episodes stay together. Depth selection is evidence, not adoption.
local B=require('Training.YingzhaoBranchBuilder');local M={}
local function predict(rules,state)
 for _,rule in ipairs(rules or {})do
  local match=true;for _,c in ipairs(rule.conditions)do if state[c.name]~=c.value then match=false;break end end
  if match then return rule.action end
 end
end
function M.validate(v)
 if type(v)~='table'or v.method~='leave-episode-out'or(v.depth~=4 and v.depth~=6 and v.depth~=8)then return false end
 local function integer(n)return type(n)=='number'and n==n and n>=0 and n<=3000 and n%1==0 end
 if not integer(v.folds)or v.folds>32 or not integer(v.total)or not integer(v.correct)or v.correct>v.total then return false end
 if v.folds<2 then return v.depth==4 and v.total==0 and v.correct==0 and v.macroAccuracy==nil end
 return v.total>0 and type(v.macroAccuracy)=='number'and v.macroAccuracy>=0 and v.macroAccuracy<=1
end
function M.buildAsync(samples,fields)
 local episodes,seen={},{}
 for _,s in ipairs(samples)do if not seen[s.episode]then seen[s.episode]=true;episodes[#episodes+1]=s.episode end end
 local best={method='leave-episode-out',depth=4,folds=#episodes,total=0,correct=0}
 if #episodes>=2 then
  for _,depth in ipairs({4,6,8})do
   local result={method='leave-episode-out',depth=depth,folds=#episodes,total=0,correct=0,macroAccuracy=0}
   for _,episode in ipairs(episodes)do
    local train,held={},{}
    for _,s in ipairs(samples)do local list=s.episode==episode and held or train;list[#list+1]=s end
    local rules,why=B.buildAsync(train,fields,depth)
    if not rules and why~='NO_VARIABLE_FEATURES'then return nil,why end
    local correct=0
    for _,s in ipairs(held)do if predict(rules,s.state)==s.action then correct=correct+1 end end
    result.total=result.total+#held;result.correct=result.correct+correct
    result.macroAccuracy=result.macroAccuracy+correct/#held/#episodes
   end
   -- Equal episode weight prevents a single long recording dominating depth.
   -- Strict improvement keeps the shallower tree when scores tie.
   if not best.macroAccuracy or result.macroAccuracy>best.macroAccuracy+1e-12 then best=result end
  end
 end
 local rules,accuracy=B.buildAsync(samples,fields,best.depth)
 return rules,accuracy,best
end
return M
