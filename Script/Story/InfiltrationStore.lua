-- Safe checkpoints for authored 2-15. Combat is retried from a safe boundary.
local D=require('Dora');local S={};S.__index=S
local function exists(name)return D.DB:existDB('lsd') and D.DB:exist(name,'lsd')end
local function version()
 local rows=D.DB:query('SELECT schemaVersion FROM lsd.Game0InfiltrationMeta WHERE id=1')
 return rows and rows[1] and rows[1][1]==1
end
function S.open()
 local story,why=require('Story.Service').open();if not story then return nil,why end
 local facts=story:summary();if not facts or not facts.completed['command-assembly'] then return nil,'ASSEMBLY_REQUIRED' end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0InfiltrationMeta (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL)')<0 or D.DB:exec('INSERT OR IGNORE INTO lsd.Game0InfiltrationMeta VALUES (1,1)')<0 then return nil,'SCHEMA_FAILED' end
 if not version()then return nil,'INCOMPATIBLE_INFILTRATION_SAVE'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0Infiltration (id INTEGER PRIMARY KEY CHECK(id=1),active INTEGER NOT NULL CHECK(active IN (0,1)),located INTEGER NOT NULL CHECK(located IN (0,1)),firstPatrol INTEGER NOT NULL CHECK(firstPatrol IN (0,1)),report TEXT NOT NULL,CHECK(firstPatrol<=located))')<0 or D.DB:exec("INSERT OR IGNORE INTO lsd.Game0Infiltration VALUES (1,0,0,0,'{}')")<0 then return nil,'SCHEMA_FAILED'end
 return setmetatable({},S)
end
function S:load()
 if not version()then return nil,'INCOMPATIBLE_INFILTRATION_SAVE'end
 local rows=D.DB:query('SELECT active,located,firstPatrol,report FROM lsd.Game0Infiltration WHERE id=1');if not rows or not rows[1]then return nil,'READ_FAILED'end
 local r=rows[1];return {active=r[1]==1,located=r[2]==1,firstPatrol=r[3]==1,report=D.json.decode(r[4])}
end
function S.patrolOperations(proof)
 local current,why=S.open();if not current then return nil,why end
 local state,why=current:load();if not state then return nil,why end
  if state.firstPatrol then return {},'ALREADY_WON'end
  if not state.active or not state.located then return nil,'LOCATION_REQUIRED'end
  if not proof or proof.status~='won' or (proof.mentorHits or 0)<=0 or (proof.fireHits or 0)<=0 or (proof.windHits or 0)<=0 or not proof.guards or #proof.guards~=3 then return nil,'BATTLE_REQUIRED'end
  for _,guard in ipairs(proof.guards)do if not guard.loseEnded or not guard.loseStarted or guard.loseEnded-guard.loseStarted<1.55 then return nil,'BATTLE_REQUIRED'end end
 return {{'UPDATE lsd.Game0Infiltration SET firstPatrol=1,report=? WHERE id=1',{{D.json.encode(proof,false,true)}}}}
end
function S:writeAsync(kind,proof)
 local current,why=S.open();if not current then return false,why end
 if self.busy then return false,'BUSY'end
 local state,err=current:load();if not state then return false,err end
 local query
 if kind=='enter'then query={'UPDATE lsd.Game0Infiltration SET active=1 WHERE id=1'}
 elseif kind=='withdraw'then query={'UPDATE lsd.Game0Infiltration SET active=0 WHERE id=1'}
 elseif kind=='locate'then
  if state.located then return true,'ALREADY_LOCATED'end
  if not state.active or not proof or not proof.fromLens or type(proof.x)~='number' or math.abs(proof.x-1000)>=180 or (proof.seconds or 0)<2 then return false,'LOCATION_REQUIRED'end
  query={'UPDATE lsd.Game0Infiltration SET located=1 WHERE id=1'}
 elseif kind=='firstPatrol'then
  local why;query,why=S.patrolOperations(proof);if not query then return false,why end
 else return false,'INVALID_OPERATION'end
 self.busy=true;local ok=D.DB:transactionAsync(query);self.busy=false;if ok then return true end;return false,'SAVE_FAILED'
end
function S.resumeOptions(facts)
 if not facts.completed['command-assembly'] or not exists('Game0InfiltrationMeta')then return end
 if not version()then return nil,'INCOMPATIBLE_INFILTRATION_SAVE'end
 local rows=D.DB:query('SELECT active,firstPatrol FROM lsd.Game0Infiltration WHERE id=1')
 if rows and rows[1] and rows[1][1]==1 then
  local spawn=rows[1][2]==1 and 2200 or 1000
  if exists('Game0InfiltrationPath')then local path=D.DB:query('SELECT schemaVersion,completed FROM lsd.Game0InfiltrationPath WHERE id=1');if path and path[1]then if path[1][1]~=1 then return nil,'INCOMPATIBLE_INFILTRATION_PATH'end;if path[1][2]==1 then spawn=4100 end end end
  if exists('Game0Researcher')then local capture=D.DB:query('SELECT schemaVersion FROM lsd.Game0Researcher WHERE id=1');if not capture or not capture[1] or capture[1][1]~=1 then return nil,'INCOMPATIBLE_RESEARCHER_SAVE'end end
  if exists('Game0SecondPatrol')then local second=D.DB:query('SELECT schemaVersion FROM lsd.Game0SecondPatrol WHERE id=1');if not second or not second[1] or second[1][1]~=1 then return nil,'INCOMPATIBLE_SECOND_PATROL_SAVE'end end
  if exists('Game0RoofDuel')then local duel=D.DB:query('SELECT schemaVersion FROM lsd.Game0RoofDuel WHERE id=1');if not duel or not duel[1]or duel[1][1]~=1 then return nil,'INCOMPATIBLE_ROOF_DUEL_SAVE'end end
  if exists('Game0Roof')then
   local roof=D.DB:query('SELECT schemaVersion,active FROM lsd.Game0Roof WHERE id=1')
   if not roof or not roof[1] or roof[1][1]~=1 then return nil,'INCOMPATIBLE_ROOF_SAVE'end
   if roof[1][2]==1 then return {scene='FactoryRoof'}end
  end
  if exists('Game0ControlPod')then
   local pod=D.DB:query('SELECT schemaVersion,active FROM lsd.Game0ControlPod WHERE id=1')
   if not pod or not pod[1] or pod[1][1]~=1 then return nil,'INCOMPATIBLE_CONTROL_POD_SAVE'end
   if pod[1][2]==1 then return {scene='ControlPod'}end
  end
  return {scene='Factory',infiltrationRoute=true,spawn=spawn}
 end
end
return S
