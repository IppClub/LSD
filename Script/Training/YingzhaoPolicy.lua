-- Dedicated Boss C4.5 model; declarative rules, no adoption side effects.
local F=require('Training.YingzhaoFeatures');local P={names=F.names,featureSchemaVersion=F.version,builderVersion=5}
local function names(version)return F.fields(version)end
local function known(name,version)for _,field in ipairs(names(version))do if field==name then return true end end;return false end
local categories={};for name,values in pairs(F.categories)do categories[name]={};for value in values:gmatch('%S+')do categories[name][value]=true end end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<1e12 end
local function array(t,min,max)if type(t)~='table'or #t<min or #t>max then return false end;local n=0;for k in pairs(t)do if type(k)~='number'or k%1~=0 or k<1 or k>#t then return false end;n=n+1 end;return n==#t end
local legal=require('Training.YingzhaoActions').legal
P.project=require('Training.YingzhaoSamples').project
P.inspect=require('Training.YingzhaoSamples').extract
function P.validate(m,actor)
 if type(m)~='table'or m.schemaVersion~=1 or m.algorithm~='yingzhao-c45'or not names(m.featureSchemaVersion) or (m.actionSetVersion~=1 and m.actionSetVersion~=2)or(m.actionSetVersion==2 and m.featureSchemaVersion<6)or m.enemyAsset~='dayingzhao'or (m.characterId~='ninilite'and m.characterId~='wuyun')or actor and actor~=m.characterId then return false,'INCOMPATIBLE_MODEL'end
 if m.builderVersion~=nil and m.builderVersion~=2 and m.builderVersion~=3 and m.builderVersion~=4 and m.builderVersion~=5 then return false,'INCOMPATIBLE_BUILDER'end
 if not finite(m.sampleCount)or m.sampleCount%1~=0 or m.sampleCount<6 or m.sampleCount>3000 or not finite(m.trainingAccuracy)or m.trainingAccuracy<0 or m.trainingAccuracy>1 or not array(m.rules,1,512)or not array(m.sourceEpisodes,1,32)then return false,'INVALID_MODEL'end
 if (m.builderVersion==4 or m.builderVersion==5) and not require('Training.YingzhaoValidatedBuilder').validate(m.validation)then return false,'INVALID_VALIDATION'end
 local seen={};for _,id in ipairs(m.sourceEpisodes)do if type(id)~='string'or #id==0 or #id>256 or seen[id]then return false,'INVALID_PROVENANCE'end;seen[id]=true end
 local supported=0
 for _,rule in ipairs(m.rules)do
  if type(rule)~='table'or not legal(m.characterId,rule.action,m.actionSetVersion)or not array(rule.conditions,0,#names(m.featureSchemaVersion))then return false,'INVALID_RULE'end
  if m.builderVersion==5 then
   if not array(rule.choices,1,16)or type(rule.choices[1])~='table'or rule.choices[1].action~=rule.action then return false,'INVALID_LEAF_ACTIONS'end
   local choices={};local prior
   for i,item in ipairs(rule.choices)do
    if type(item)~='table'or not legal(m.characterId,item.action,m.actionSetVersion)or choices[item.action]or not finite(item.count)or item.count%1~=0 or item.count<1 or item.count>m.sampleCount or type(item.episodes)~='table'then return false,'INVALID_LEAF_ACTIONS'end
    local total=0;for episode,count in pairs(item.episodes)do if not seen[episode]or not finite(count)or count%1~=0 or count<1 then return false,'INVALID_LEAF_PROVENANCE'end;total=total+count end
    if total~=item.count then return false,'INVALID_LEAF_PROVENANCE'end
    if i>2 and (prior.count<item.count or prior.count==item.count and prior.action>item.action)then return false,'INVALID_LEAF_ORDER'end
    choices[item.action]=true;prior=item;supported=supported+item.count
   end
  elseif rule.choices~=nil then return false,'UNVERSIONED_LEAF_ACTIONS'end
  for _,c in ipairs(rule.conditions)do if type(c)~='table'or c.op~='=='or not categories[c.name]or not known(c.name,m.featureSchemaVersion)or not categories[c.name][c.value]then return false,'INVALID_CONDITION'end end
 end
 if m.builderVersion==5 and supported~=m.sampleCount then return false,'INVALID_LEAF_SUPPORT'end
 return true
end
function P.buildAsync(records,actor,version,builderVersion,actionVersion)
 builderVersion=builderVersion or P.builderVersion;if builderVersion~=1 and builderVersion~=2 and builderVersion~=3 and builderVersion~=4 and builderVersion~=5 then return nil,'INCOMPATIBLE_BUILDER'end
 version=version or P.featureSchemaVersion;if not names(version)then return nil,'INVALID_FEATURE_VERSION'end
 local fields=names(version)
 local data,why=P.inspect(records,actor,version,actionVersion);if not data then return nil,why end
 if #data.samples<6 then return nil,'TOO_FEW_SAMPLES'end;if #data.samples>3000 then return nil,'SAMPLE_LIMIT'end
 local count=0;for _ in pairs(data.actions)do count=count+1 end;if count<2 then return nil,'ACTION_VARIETY_REQUIRED'end
 -- Constant columns contain no decision information and can produce zero-entropy
 -- gain ratios in the native builder. Keep the original route for old archives.
 if builderVersion==2 then
  local varied={}
  for _,name in ipairs(fields)do
   local first=data.samples[1].state[name]
   for i=2,#data.samples do if data.samples[i].state[name]~=first then varied[#varied+1]=name;break end end
  end
  fields=varied
  if #fields==0 then return nil,'NO_VARIABLE_FEATURES'end
 end
 local rules,accuracy,validation
 if builderVersion==4 or builderVersion==5 then
  rules,accuracy,validation=require('Training.YingzhaoValidatedBuilder').buildAsync(data.samples,fields)
  if not rules then return nil,accuracy end
 elseif builderVersion==3 then
  rules,accuracy=require('Training.YingzhaoBranchBuilder').buildAsync(data.samples,fields)
  if not rules then return nil,accuracy end
 else
 local header,types={},{};for _,name in ipairs(fields)do header[#header+1]=name;types[#types+1]='C'end;header[#header+1]='action';types[#types+1]='C'
 local rows={table.concat(header,','),table.concat(types,',')}
 for _,sample in ipairs(data.samples)do local row={};for _,name in ipairs(fields)do row[#row+1]=sample.state[name]end;row[#row+1]=sample.action;rows[#rows+1]=table.concat(row,',')end
 local nodes={};local err;accuracy,err=require('Dora').ML.BuildDecisionTreeAsync(table.concat(rows,'\n'),5,function(depth,name,op,value)nodes[#nodes+1]={depth=depth,name=name,op=op,value=value}end)
 if not accuracy then return nil,err or 'BUILD_FAILED'end
 local path={};rules={}
 for _,n in ipairs(nodes)do
  if not finite(n.depth)or n.depth%1~=0 or n.depth<0 or n.depth>#fields then return nil,'INVALID_DEPTH'end
  if n.op=='return'then
   local conditions={};for i=1,n.depth do if not path[i]then return nil,'MISSING_PARENT'end;conditions[i]=path[i]end
   rules[#rules+1]={action=n.value,conditions=conditions}
  else
   if not categories[n.name]or n.op~='=='or not categories[n.name][n.value]then return nil,'INVALID_CONDITION'end
   for i=1,n.depth do if not path[i]then return nil,'MISSING_PARENT'end end
   for i=#path,n.depth+1,-1 do path[i]=nil end;path[n.depth+1]={name=n.name,op=n.op,value=n.value}
  end
 end
 end
 if builderVersion==5 then require('Training.YingzhaoLeafActions').attach(rules,data.samples)end
 local m={schemaVersion=1,algorithm='yingzhao-c45',featureSchemaVersion=version,actionSetVersion=data.actionSetVersion,enemyAsset='dayingzhao',characterId=actor,sampleCount=#data.samples,trainingAccuracy=accuracy,sourceEpisodes=data.sources,rules=rules}
 if builderVersion>=2 then m.builderVersion=builderVersion end
 if validation then m.validation=validation end
 local ok,why=P.validate(m,actor);if not ok then return nil,why end
 -- Canonicalize native floating accuracy through the archive representation.
 local D=require('Dora');return D.json.decode(D.json.encode(m,false,true),32)
end
function P.predict(m,observation,available)
 local ok,why=P.validate(m);if not ok then return nil,why end
 local state,why=P.project(observation,m.characterId,m.featureSchemaVersion);if not state then return nil,why end
 for _,rule in ipairs(m.rules)do local match=true;for _,c in ipairs(rule.conditions)do if state[c.name]~=c.value then match=false;break end end
  if match then
   if m.builderVersion==5 and available then
    for _,choice in ipairs(rule.choices)do if available(choice.action)then return choice.action end end
    return nil,'ACTION_UNAVAILABLE'
   end
   if available and not available(rule.action)then return nil,'ACTION_UNAVAILABLE'end;return rule.action
  end
 end
 return nil,'NO_MATCH'
end
return P
