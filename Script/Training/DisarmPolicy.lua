-- Independent C4.5 domain. Rewards and later combat outcomes are not features.
local legacyNames={'distance','weapon','enemySkill','enemyArmed','enemyCanFire','displaced','empAmmo','bladeAmmo','budget'}
local P={names={table.unpack(legacyNames)},featureSchemaVersion=2};P.names[#P.names+1]='meleeRange'
local function names(version)return version==1 and legacyNames or P.names end
local function set(s)local t={};for v in s:gmatch('%S+')do t[v]=true end;return t end
local categories={meleeRange=set('within outside none'),distance=set('near mid far none'),weapon=set('equipped disarmed'),enemySkill=set('idle rob punch shoot'),enemyArmed=set('true false'),enemyCanFire=set('true false'),displaced=set('true false'),empAmmo=set('unequipped empty low ready'),bladeAmmo=set('unequipped empty low ready'),budget=set('empty low ready')}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<1e12 end
local function array(t,min,max)if type(t)~='table'or #t<min or #t>max then return false end;local n=0;for k in pairs(t)do if type(k)~='number'or k%1~=0 or k<1 or k>#t then return false end;n=n+1 end;return n==#t end
local function legal(actor,action)return ({laser=true,fmove=true,bmove=true,idle=true})[action]or actor=='wuyun'and action=='melee'end
function P.project(s,actor,version)
 version=version or P.featureSchemaVersion;if version~=1 and version~=2 then return nil,'INVALID_FEATURE_VERSION'end
 if type(s)~='table'or s.actor~=actor or s.phase~='playing'or not categories.weapon[s.weapon]or not categories.enemySkill[s.enemySkill]or type(s.enemyArmed)~='boolean'or type(s.enemyCanFire)~='boolean'or type(s.displaced)~='boolean'or not require('Training.ResourceEvidence').observation(s.resources)or s.resources.actor~=actor then return nil,'INVALID_OBSERVATION'end
 local distance=s.enemyDistance;if distance~=nil and (not finite(distance)or distance<0)then return nil,'INVALID_DISTANCE'end
 local function ammo(item)local n=s.resources.ammo[item];return n==nil and 'unequipped'or n==0 and 'empty'or n<=3 and 'low'or'ready'end
 local result={distance=distance==nil and 'none'or distance<=250 and 'near'or distance<=650 and 'mid'or'far',weapon=s.weapon,enemySkill=s.enemySkill,enemyArmed=tostring(s.enemyArmed),enemyCanFire=tostring(s.enemyCanFire),displaced=tostring(s.displaced),empAmmo=ammo('emp'),bladeAmmo=ammo('blade'),budget=s.resources.budgetLeft==0 and 'empty'or s.resources.budgetLeft<=s.resources.reserved*.25 and 'low'or'ready'}
 if version==2 then result.meleeRange=distance==nil and 'none'or distance<=300 and 'within'or'outside'end
 return result
end
function P.inspect(records,actor,version)
 if actor~='ninilite'and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
 if not array(records,0,20)then return nil,'INVALID_SOURCES'end
 local data={samples={},sources={},actions={},excluded=0};local seen={}
 for _,record in ipairs(records)do
  local t=record.source and record.source.trace
  if type(t)~='table'then return nil,'INVALID_SOURCE'end
  if t.demonstrator==actor then
   if t.kind~='disarm-practice'then return nil,'INVALID_DEMONSTRATION_SOURCE'end
   local credit,why=require('Training.DisarmCredit').rebuild(t);if not credit then return nil,why end
   local episode=t.resources.attempt;if seen[episode]then return nil,'DUPLICATE_SOURCE'end;seen[episode]=true
   local steps={};for _,step in ipairs(credit.steps)do steps[step.id]=step end
   local used=false
   for _,s in ipairs(t.executions)do
    if s.actor==actor and s.source=='demo'and legal(actor,s.action)then
     local attack=s.action=='laser'or s.action=='melee'
     local eligible=attack and s.outcome=='completed'and steps[s.id].cost>0 or not attack and s.outcome=='stopped'and s.duration>=.15
     if eligible then
      local state,why=P.project(s.before,actor,version);if not state then return nil,why end
      if state.displaced=='true'or s.action=='laser'and (state.weapon=='disarmed'or state.empAmmo=='empty'or state.empAmmo=='unequipped')or s.action=='melee'and (state.bladeAmmo=='empty'or state.bladeAmmo=='unequipped')then return nil,'ILLEGAL_DEMONSTRATION'end
      data.samples[#data.samples+1]={state=state,action=s.action};data.actions[s.action]=true;used=true
     else data.excluded=data.excluded+1 end
    end
   end
   if used then data.sources[#data.sources+1]=episode end
  end
 end
 return data
end
function P.validate(m,actor)
 if type(m)~='table'or m.schemaVersion~=1 or m.algorithm~='disarm-c45'or (m.featureSchemaVersion~=1 and m.featureSchemaVersion~=2) or m.actionSetVersion~=1 or m.enemyAsset~='zhongyingzhao'or (m.characterId~='ninilite'and m.characterId~='wuyun')or actor and actor~=m.characterId then return false,'INCOMPATIBLE_MODEL'end
 if not finite(m.sampleCount)or m.sampleCount%1~=0 or m.sampleCount<6 or m.sampleCount>3000 or not finite(m.trainingAccuracy)or m.trainingAccuracy<0 or m.trainingAccuracy>1 or not array(m.rules,1,512)or not array(m.sourceEpisodes,1,20)then return false,'INVALID_MODEL'end
 local seen={};for _,id in ipairs(m.sourceEpisodes)do if type(id)~='string'or #id==0 or #id>256 or seen[id]then return false,'INVALID_PROVENANCE'end;seen[id]=true end
 for _,rule in ipairs(m.rules)do
  if type(rule)~='table'or not legal(m.characterId,rule.action)or not array(rule.conditions,0,#names(m.featureSchemaVersion))then return false,'INVALID_RULE'end
  for _,c in ipairs(rule.conditions)do if type(c)~='table'or c.op~='=='or m.featureSchemaVersion==1 and c.name=='meleeRange'or not categories[c.name]or not categories[c.name][c.value]then return false,'INVALID_CONDITION'end end
 end
 return true
end
function P.buildAsync(records,actor,version)
 version=version or P.featureSchemaVersion;if version~=1 and version~=2 then return nil,'INVALID_FEATURE_VERSION'end
 local fields=names(version)
 local data,why=P.inspect(records,actor,version);if not data then return nil,why end
 if #data.samples<6 then return nil,'TOO_FEW_SAMPLES'end;if #data.samples>3000 then return nil,'SAMPLE_LIMIT'end
 local count=0;for _ in pairs(data.actions)do count=count+1 end;if count<2 then return nil,'ACTION_VARIETY_REQUIRED'end
 local header,types={},{};for _,name in ipairs(fields)do header[#header+1]=name;types[#types+1]='C'end;header[#header+1]='action';types[#types+1]='C'
 local rows={table.concat(header,','),table.concat(types,',')}
 for _,sample in ipairs(data.samples)do local row={};for _,name in ipairs(fields)do row[#row+1]=sample.state[name]end;row[#row+1]=sample.action;rows[#rows+1]=table.concat(row,',')end
 local nodes={};local accuracy,err=require('Dora').ML.BuildDecisionTreeAsync(table.concat(rows,'\n'),5,function(depth,name,op,value)nodes[#nodes+1]={depth=depth,name=name,op=op,value=value}end)
 if not accuracy then return nil,err or 'BUILD_FAILED'end
 local path,rules={},{}
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
 local m={schemaVersion=1,algorithm='disarm-c45',featureSchemaVersion=version,actionSetVersion=1,enemyAsset='zhongyingzhao',characterId=actor,sampleCount=#data.samples,trainingAccuracy=accuracy,sourceEpisodes=data.sources,rules=rules}
 local ok,why=P.validate(m,actor);if not ok then return nil,why end
 -- Canonicalize native floating accuracy through the archive representation.
 local D=require('Dora');return D.json.decode(D.json.encode(m,false,true),32)
end
function P.predict(m,observation,available)
 local ok,why=P.validate(m);if not ok then return nil,why end
 local state,why=P.project(observation,m.characterId,m.featureSchemaVersion);if not state then return nil,why end
 for _,rule in ipairs(m.rules)do local match=true;for _,c in ipairs(rule.conditions)do if state[c.name]~=c.value then match=false;break end end
  if match then if available and not available(rule.action)then return nil,'ACTION_UNAVAILABLE'end;return rule.action end
 end
 return nil,'NO_MATCH'
end
return P
