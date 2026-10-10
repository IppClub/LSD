-- Flower-domain C4.5. Inputs are decision-time observations only; no outcome,
-- reward, future HP or generated Lua enters the classifier.
return function(resourceMode)
local F=require('Training.FlowerFeatures');local P={}
local defaultVersion=resourceMode and 8 or 7
P.names={'phase','phasePending','distance','facing','target','confused','poisoned','virus','part_head','part_core','part_left','part_right','part_roots','health','allyHealth','energyReady','support','supplies'}
P.names7={};for _,name in ipairs(P.names)do P.names7[#P.names7+1]=name end
for _,name in ipairs(require('Training.FlowerTacticsFeatures').names)do P.names7[#P.names7+1]=name end
local function set(values)local s={};for word in values:gmatch('%S+')do s[word]=true end;return s end
local categories={phase=set('entrenched reproduction'),phasePending=set('true false'),distance=set('near mid far'),facing=set('toward away'),target=set('none boss bud flower'),health=set('fallen danger wounded healthy'),energyReady=set('unlimited ready empty'),support=set('unknown inactive inside outside'),supplies=set('unknown empty low available')}
categories.allyHealth=categories.health
for name,values in pairs(require('Training.FlowerTacticsFeatures').categories)do categories[name]=set(values)end
local legacyNames={};for _,name in ipairs(P.names)do legacyNames[name]=true end
for _,name in ipairs({'confused','poisoned','virus'})do categories[name]=set('true false')end
for _,name in ipairs({'part_head','part_core','part_left','part_right','part_roots'})do categories[name]=set('unknown unarmored exposed armored')end
local resourceNames={}
if resourceMode then
 for _,name in ipairs(require('Training.ResourceFeatures').names)do P.names7[#P.names7+1]=name;resourceNames[name]=true end
 for name,values in pairs(require('Training.ResourceFeatures').categories)do categories[name]=set(values)end
end
local function project(state)
 local projected,why=require('Training.FlowerTacticsFeatures').project(state);if not projected then return nil,why end
 if resourceMode then
  local resources,why=require('Training.ResourceFeatures').project(state);if not resources then return nil,why end
  for name in pairs(resourceNames)do projected[name]=resources[name]end
 end
 return projected
end
local function value(state,name)local v=state[name];return type(v)=='boolean' and tostring(v)or v end
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function array(t,min,max)
 if type(t)~='table' or #t<min or #t>max then return false end
 local n=0;for k in pairs(t)do if type(k)~='number' or k%1~=0 or k<1 or k>#t then return false end;n=n+1 end
 return n==#t
end
local targetParts={['flower-head']=true,['flower-core']=true,['petal-left']=true,['petal-right']=true,roots=true}
function P.decodeAction(action)
 if type(action)=='string' and action:sub(1,6)=='shoot@' and targetParts[action:sub(7)]then return 'shoot',action:sub(7)end
 return action
end
function P.actionText(label)
 local action,part=P.decodeAction(label)
 local names={['flower-head']='头部',['flower-core']='躯干',['petal-left']='左花瓣',['petal-right']='右花瓣',roots='根部'}
 if part then return '瞄准'..names[part]..'射击' end
 return ({shoot='直射',melee='刀击',fmove='前进',bmove='后退',idle='等待',ACTION_UNAVAILABLE='当前动作不可执行，等待机会',NO_RULE='未覆盖当前情况，等待示范'})[action] or '等待决策'
end
local function legal(actor,action)local base=P.decodeAction(action);return ({shoot=true,fmove=true,bmove=true,idle=true})[base] or (actor=='wuyun' and action=='melee')end
function P.inspect(episodes,actor,version)
 version=version or defaultVersion
 if resourceMode and version~=8 or not resourceMode and version~=6 and version~=7 then return nil,'INCOMPATIBLE_FEATURE_VERSION'end
 local names=version>=7 and P.names7 or P.names
 if actor~='ninilite' and actor~='wuyun' then return nil,'INVALID_CHARACTER'end
 local samples,sources,seen,actions={},{},{},{}
 local coverage={featureSchemaVersion=version,excludedLegacyEpisodes=0,characterId=actor,actions={shoot=0,melee=0,fmove=0,bmove=0,idle=0},phases={entrenched=0,reproduction=0},aimed=0,knownUnarmoredShots=0,observedArmor=0,armor=0,excludedIncomplete=0,excludedUnemitted=0}
 if resourceMode then coverage.resources={empAmmo={ready=0,low=0,empty=0,unequipped=0},bladeAmmo={ready=0,low=0,empty=0,unequipped=0},missionBudget={ready=0,low=0,empty=0}}end
 for _,episode in ipairs(episodes)do
  local ok,why=require('Training.CombatStore').validate(episode);if not ok then return nil,why end
  if version==7 and episode.context=='flower-practice' and episode.versions.spatial~=2 then coverage.excludedLegacyEpisodes=coverage.excludedLegacyEpisodes+1 end
  local eligible=resourceMode and episode.context=='flower-resource-demo' and (episode.practiceProfile==nil or episode.practiceProfile=='standard') and episode.versions.resources==1 and episode.versions.resourceFeatures==1 or not resourceMode and not episode.versions.resources and episode.context=='flower-practice' and (episode.practiceProfile==nil or episode.practiceProfile=='standard')
  if eligible and episode.versions.observation==6 and episode.versions.action==4 and (version==6 or episode.versions.spatial==2) and not seen[episode.episode]then
   seen[episode.episode]=true;local used=false
   for _,step in ipairs(episode.steps)do
    local a=step.action
    if a.actor==actor and a.origin=='demo' and step.sealed and not step.truncated and legal(actor,a.name) and (a.name~='shoot' or (a.emitted or 0)>0)then
     local observation=step.observation
     if version>=7 then local why;observation,why=project(observation);if not observation then return nil,why end end
     local copy={};for _,name in ipairs(names)do copy[name]=value(observation,name)end
     local label=a.name
     if a.name=='shoot' and a.aimSource=='manual-sweep-v1' and a.aimStatus=='boss' and targetParts[a.intendedPart]then
      label='shoot@'..a.intendedPart;coverage.aimed=coverage.aimed+1
      -- Diagnose from knowledge at action start, never the later impact result.
      if a.weapon=='emp' then for key,part in pairs(F.parts)do
       if part==a.intendedPart and (copy['part_'..key]=='exposed' or copy['part_'..key]=='unarmored')then coverage.knownUnarmoredShots=coverage.knownUnarmoredShots+1 end
      end end
     end
     if coverage.resources then for name,counts in pairs(coverage.resources)do counts[copy[name]]=counts[copy[name]]+1 end end
     samples[#samples+1]={state=copy,action=label};actions[label]=true;used=true
     coverage.actions[a.name]=coverage.actions[a.name]+1;coverage.phases[copy.phase]=coverage.phases[copy.phase]+1
     local observed=false;for _,name in ipairs({'part_head','part_core','part_left','part_right','part_roots'})do if copy[name]~='unknown'then observed=true end end
     if observed then coverage.observedArmor=coverage.observedArmor+1 end
     for _,hit in ipairs(step.hits)do if hit.relation~='friendly' and hit.credit then coverage.armor=coverage.armor+hit.credit.armor end end
    elseif a.actor==actor and a.origin=='demo' and legal(actor,a.name)then
     if not step.sealed or step.truncated then coverage.excludedIncomplete=coverage.excludedIncomplete+1
     elseif a.name=='shoot' and (a.emitted or 0)==0 then coverage.excludedUnemitted=coverage.excludedUnemitted+1 end
    end
   end
   if used then sources[#sources+1]=episode.episode end
  end
 end
 coverage.total=#samples
 return {featureSchemaVersion=version,samples=samples,sources=sources,actions=actions,characterId=actor,coverage=coverage}
end
function P.collect(episodes,actor,version)
 local data,why=P.inspect(episodes,actor,version);if not data then return nil,why end
 if #data.samples>3000 then return nil,'SAMPLE_LIMIT'end
 if #data.samples<6 then return nil,data.featureSchemaVersion==7 and data.coverage.excludedLegacyEpisodes>0 and 'SPATIAL_DEMONSTRATIONS_REQUIRED'or'TOO_FEW_SAMPLES'end
 local count=0;for _ in pairs(data.actions)do count=count+1 end;if count<2 then return nil,'ACTION_VARIETY_REQUIRED'end
 return data
end
function P.coverageText(c)
 if not c then return '示范统计暂不可用。'end
 local a=c.actions
 local text=string.format('可学习%d个示范：射击%d · 移动%d · 等待%d',c.total,a.shoot,a.fmove+a.bmove,a.idle)
 if c.featureSchemaVersion==7 then text=text..'（含距离与站位）';if (c.excludedLegacyEpisodes or 0)>0 then text=text..string.format('；保留%d轮旧示范，未混入新版学习',c.excludedLegacyEpisodes)end end
 if c.characterId=='wuyun'then text=text..string.format(' · 刀击%d',a.melee)end
 if c.resources then
  local ammo=c.resources.empAmmo;local budget=c.resources.missionBudget
  text=text..string.format('\n资源状态示范：EMP充足%d / 少量%d / 耗尽%d；预算紧张%d / 耗尽%d。',ammo.ready,ammo.low,ammo.empty,budget.low,budget.empty)
  if c.characterId=='wuyun'then local blade=c.resources.bladeAmmo;text=text..string.format(' 近战余量：充足%d / 少量%d / 耗尽%d。',blade.ready,blade.low,blade.empty)end
  if ammo.ready+ammo.low>0 and ammo.empty==0 then text=text..' 可补充弹药耗尽后的移动或等待。'end
 end
 if a.shoot+a.melee==0 then return text..'；尚无完整攻击示范。'end
 text=text..string.format('；部位瞄准%d · 有效削甲%.0f。',c.aimed or 0,c.armor)
 if (c.knownUnarmoredShots or 0)>0 then text=text..string.format(' 已知无甲部位仍发射EMP：%d次；建议补充换目标或等待示范。',c.knownUnarmoredShots)end
 return text
end

function P.learnedActionsText(model)
 if not model or type(model.rules)~='table' then return '' end
 local seen,names,attack={},{},false
 for _,rule in ipairs(model.rules)do
  if not seen[rule.action]then seen[rule.action]=true;names[#names+1]=P.actionText(rule.action) end
  local base=P.decodeAction(rule.action);if base=='shoot' or base=='melee'then attack=true end
 end
 local text='候选动作：'..table.concat(names,'、')
 if not attack then text=text..'；未学到攻击，请补充不同状态的攻击示范。'end
 return text
end

function P.validate(model,actor)
 if type(model)~='table' or model.schemaVersion~=1 or model.algorithm~=(resourceMode and 'flower-resource-c45' or 'c45') or (resourceMode and (model.featureSchemaVersion~=8 or model.resourceFeatureVersion~=1) or not resourceMode and model.featureSchemaVersion~=6 and model.featureSchemaVersion~=7) or (model.actionSetVersion~=4 and model.actionSetVersion~=5) or model.partSetVersion~=2 or model.enemyAsset~='dahuayao' then return false,'INCOMPATIBLE_MODEL'end
 if (model.characterId~='ninilite' and model.characterId~='wuyun') or (actor and model.characterId~=actor)then return false,'INCOMPATIBLE_CHARACTER'end
 if not finite(model.sampleCount) or model.sampleCount<6 or model.sampleCount>3000 or model.sampleCount%1~=0 or not finite(model.trainingAccuracy) or model.trainingAccuracy<0 or model.trainingAccuracy>1 or not array(model.rules,1,512) then return false,'INVALID_MODEL'end
 if not array(model.sourceEpisodes,1,20)then return false,'INVALID_PROVENANCE'end
 local seen={};for _,id in ipairs(model.sourceEpisodes)do if type(id)~='string' or #id<1 or #id>256 or seen[id]then return false,'INVALID_PROVENANCE'end;seen[id]=true end
 for _,rule in ipairs(model.rules)do
  if type(rule)~='table' or (model.actionSetVersion==4 and select(2,P.decodeAction(rule.action))~=nil) or not legal(model.characterId,rule.action) or not array(rule.conditions,0,resourceMode and 28 or 24) then return false,'INVALID_RULE'end
  for _,c in ipairs(rule.conditions)do if type(c)~='table' or (model.featureSchemaVersion==6 and not legacyNames[c.name]) or not categories[c.name] or c.op~='==' or not categories[c.name][c.value]then return false,'INVALID_CONDITION'end end
 end
 return true
end
function P.compile(nodes,actor,version)
 local path,rules={},{}
 for _,node in ipairs(nodes)do
  local depth=node.depth
  if not finite(depth) or depth<0 or depth>(resourceMode and 28 or 24) or depth%1~=0 then return nil,'INVALID_DEPTH'end
  if node.op=='return'then
   if not legal(actor,node.value)then return nil,'INVALID_ACTION'end
   local conditions={};for i=1,depth do if not path[i]then return nil,'MISSING_PARENT'end;local c=path[i];conditions[i]={name=c.name,op=c.op,value=c.value}end
   rules[#rules+1]={conditions=conditions,action=node.value}
  else
   if (version==6 and not legacyNames[node.name]) or not categories[node.name] or node.op~='==' or not categories[node.name][node.value]then return nil,'INVALID_CONDITION'end
   for i=1,depth do if not path[i]then return nil,'MISSING_PARENT'end end
   for i=#path,depth+1,-1 do path[i]=nil end
   path[depth+1]={name=node.name,op=node.op,value=node.value}
  end
 end
 return rules
end
function P.buildAsync(episodes,actor,version)
 version=version or defaultVersion
 local names=version>=7 and P.names7 or P.names
 local data,why=P.collect(episodes,actor,version);if not data then return nil,why end
 local header,types={},{};for _,name in ipairs(names)do header[#header+1]=name;types[#types+1]='C'end;header[#header+1]='action';types[#types+1]='C'
 local rows={table.concat(header,','),table.concat(types,',')}
 for _,sample in ipairs(data.samples)do local values={};for _,name in ipairs(names)do values[#values+1]=sample.state[name]end;values[#values+1]=sample.action;rows[#rows+1]=table.concat(values,',')end
 local nodes={};local accuracy,err=require('Dora').ML.BuildDecisionTreeAsync(table.concat(rows,'\n'),5,function(depth,name,op,value)nodes[#nodes+1]={depth=depth,name=name,op=op,value=value}end)
 if not accuracy then return nil,err or 'BUILD_FAILED'end
 local rules,why=P.compile(nodes,actor,version);if not rules then return nil,why end
 local targeted=false;for action in pairs(data.actions)do if select(2,P.decodeAction(action))then targeted=true end end
 local model={schemaVersion=1,algorithm=resourceMode and 'flower-resource-c45' or 'c45',resourceFeatureVersion=resourceMode and 1 or nil,featureSchemaVersion=version,actionSetVersion=targeted and 5 or 4,partSetVersion=2,enemyAsset='dahuayao',characterId=actor,sampleCount=#data.samples,trainingAccuracy=accuracy,rules=rules,sourceEpisodes=data.sources}
 local ok,why=P.validate(model,actor);if not ok then return nil,why end;return model
end
function P.predict(model,state,available)
 local ok,why=P.validate(model);if not ok then return nil,why end
 if not F.validate(state) or state.featureSchemaVersion~=6 then return nil,'INCOMPATIBLE_OBSERVATION'end
 if model.featureSchemaVersion>=7 then local why;state,why=project(state);if not state then return nil,why end end
 for _,rule in ipairs(model.rules)do
  local matches=true;for _,c in ipairs(rule.conditions)do if value(state,c.name)~=c.value then matches=false;break end end
  if matches then if available and not available(rule.action)then return nil,'ACTION_UNAVAILABLE'end;return rule.action end
 end
 return nil,'NO_MATCH'
end
return P
end
