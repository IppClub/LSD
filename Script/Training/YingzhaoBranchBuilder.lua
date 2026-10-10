-- Use native categorical C4.5 for each split, removing constants again in
-- each branch. The historical depth 5 starts at 1: at most four conditions.
local D=require('Dora');local M={}
function M.buildAsync(samples,fields,maxConditions)
 maxConditions=maxConditions or 4
 local rules={};local failure
 local function leaf(rows,path,action)
  if not action then
   local counts={};for _,s in ipairs(rows)do counts[s.action]=(counts[s.action]or 0)+1 end
   local best=0;for _,s in ipairs(rows)do if counts[s.action]>best then action=s.action;best=counts[s.action]end end
  end
  local conditions={};for i,c in ipairs(path)do conditions[i]=c end
  rules[#rules+1]={conditions=conditions,action=action}
  if #rules>512 then failure='RULE_LIMIT'end
 end
 local function branch(rows,path)
  if failure then return end
  local varied={};local allowed={}
  for _,name in ipairs(fields)do
   for i=2,#rows do if rows[i].state[name]~=rows[1].state[name]then varied[#varied+1]=name;allowed[name]=true;break end end
  end
  if #varied==0 and #path==0 then failure='NO_VARIABLE_FEATURES';return end
  local same=true;for i=2,#rows do if rows[i].action~=rows[1].action then same=false;break end end
  if same or #varied==0 or #path>=maxConditions then leaf(rows,path);return end
  local header,types={},{};for _,n in ipairs(varied)do header[#header+1]=n;types[#types+1]='C'end
  header[#header+1]='action';types[#types+1]='C'
  local csv={table.concat(header,','),table.concat(types,',')}
  for _,s in ipairs(rows)do local row={};for _,n in ipairs(varied)do row[#row+1]=s.state[n]end;row[#row+1]=s.action;csv[#csv+1]=table.concat(row,',')end
  local split,terminal;local values,seen={},{}
  local accuracy,why=D.ML.BuildDecisionTreeAsync(table.concat(csv,'\n'),2,function(depth,name,op,value)
   if depth==0 and op=='return'then terminal=value
   elseif depth==0 then
    if op~='=='or not allowed[name]or split and split~=name or seen[value]then failure='INVALID_NATIVE_SPLIT';return end
    split=name;seen[value]=true;values[#values+1]=value
   end
  end)
  if not accuracy then failure=why or'BUILD_FAILED';return end
  if failure then return end
  if not split then
   local valid=false;for _,s in ipairs(rows)do if s.action==terminal then valid=true;break end end
   if not valid then failure='INVALID_NATIVE_LEAF';return end
   leaf(rows,path,terminal);return
  end
  local groups={};for _,s in ipairs(rows)do local value=s.state[split];if not seen[value]then failure='MISSING_NATIVE_BRANCH';return end;groups[value]=groups[value]or{};table.insert(groups[value],s)end
  for _,value in ipairs(values)do
   if not groups[value]then failure='EMPTY_NATIVE_BRANCH';return end
   path[#path+1]={name=split,op='==',value=value};branch(groups[value],path);path[#path]=nil
  end
 end
 branch(samples,{})
 if failure then return nil,failure end
 local correct=0
 for _,s in ipairs(samples)do for _,rule in ipairs(rules)do
  local match=true;for _,c in ipairs(rule.conditions)do if s.state[c.name]~=c.value then match=false;break end end
  if match then if rule.action==s.action then correct=correct+1 end;break end
 end end
 return rules,correct/#samples
end
return M
