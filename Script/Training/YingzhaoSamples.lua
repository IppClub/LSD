-- Decision-time features only. Outcome accounting is retained separately and
-- never changes a demonstrated action label (misses are valid demonstrations).
local F=require('Training.YingzhaoFeatures');local M={version=1}
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function M.project(observation,actor,version)
 if not F.validate(observation)then return nil,'INVALID_OBSERVATION'end
 return F.project(observation,version)
end
function M.extract(records,actor,version,actionVersion)
 version=version or F.version
 actionVersion=actionVersion or (version>=6 and 2 or 1)
 if (actionVersion~=1 and actionVersion~=2)or(actionVersion==2 and version<6)then return nil,'INVALID_ACTION_VERSION'end
 if not F.fields(version)then return nil,'INVALID_FEATURE_VERSION'end
 if actor~='ninilite'and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
 if type(records)~='table'or #records>32 then return nil,'INVALID_SOURCES'end
 local count=0;for key in pairs(records)do if type(key)~='number'or key%1~=0 or key<1 or key>#records then return nil,'INVALID_SOURCES'end;count=count+1 end
 if count~=#records then return nil,'INVALID_SOURCES'end
 local data={version=1,featureSchemaVersion=version,actionSetVersion=actionVersion,characterId=actor,samples={},sources={},actions={},excluded=0};local seen={}
 for _,e in ipairs(records)do
  local review,why=require('Training.YingzhaoReview').rebuild(e);if not review then return nil,why end
  if seen[e.episode]then return nil,'DUPLICATE_SOURCE'end;seen[e.episode]=true
  if e.demonstrator==actor then
   data.sources[#data.sources+1]=e.episode
   local pending
   local function add(step,index,label,last)
    local state,why=M.project(step.before,actor,version);if not state then return nil,why end
    data.samples[#data.samples+1]={state=state,action=label,episode=e.episode,firstStep=index,lastStep=last or index}
    data.actions[label]=(data.actions[label]or 0)+1;return true
   end
   local function flush()
    if pending then
     if pending.ended-pending.step.started>=.15 then add(pending.step,pending.index,pending.action,pending.last)else data.excluded=data.excluded+1 end
     pending=nil
    end
   end
   for i,s in ipairs(e.boss.steps)do if s.actor==actor then
    if finite(s.started)and s.before.at>s.started+.01 then return nil,'FUTURE_DECISION_OBSERVATION'end
    if not finite(s.started)or not finite(s.ended)or s.ended<s.started or not s.after then flush();data.excluded=data.excluded+1
    elseif s.origin~='demo'then flush();data.excluded=data.excluded+1
    elseif s.action=='fmove'or s.action=='bmove'or s.action=='idle'then
     local key=F.key(s.before,version)
     if pending and pending.action==s.action and pending.key==key and s.started>=pending.ended and s.started-pending.ended<=.05 then pending.ended=s.ended;pending.last=i
     else flush();pending={step=s,index=i,last=i,action=s.action,key=key,ended=s.ended}end
    elseif s.action=='fire'or s.action=='wind'then
     flush()
     if actionVersion==2 and s.before.featureSchemaVersion>=6 and s.emitted==1 then
      local label=s.action..(s.skill.direction==1 and'@right'or'@left')
      if require('Training.YingzhaoActions').legal(actor,label,actionVersion)then
       local ok,why=add(s,i,label);if not ok then return nil,why end
      else data.excluded=data.excluded+1 end
     else data.excluded=data.excluded+1 end
    else
     flush();local label=s.action=='shoot'and s.aim and ('shoot@'..s.aim.intent)or s.action=='melee'and actor=='wuyun'and'melee'
     if label and review.rows[i].units>0 and (s.action~='shoot'or s.emitted==1)then
      local ok,why=add(s,i,label);if not ok then return nil,why end
     else data.excluded=data.excluded+1 end
    end
   end end
   flush()
  end
 end
 if #data.samples>3000 then return nil,'SAMPLE_LIMIT'end
 return data
end
return M
