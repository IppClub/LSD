-- Only actions actually demonstrated in a matching leaf may be alternatives.
local M={}
function M.attach(rules,samples)
 for _,rule in ipairs(rules)do
  local counts={}
  for _,sample in ipairs(samples)do
   local match=true;for _,c in ipairs(rule.conditions)do if sample.state[c.name]~=c.value then match=false;break end end
   if match then
    local item=counts[sample.action]or{action=sample.action,count=0,episodes={}};counts[sample.action]=item
    item.count=item.count+1;item.episodes[sample.episode]=(item.episodes[sample.episode]or 0)+1
   end
  end
  local choices={};for _,item in pairs(counts)do choices[#choices+1]=item end
  table.sort(choices,function(a,b)
   if a.action==b.action then return false end
   if a.action==rule.action then return true elseif b.action==rule.action then return false end
   if a.count~=b.count then return a.count>b.count end;return a.action<b.action
  end)
  assert(choices[1]and choices[1].action==rule.action,'Leaf primary lacks source samples')
  rule.choices=choices
 end
end
return M
