-- A separate versioned checkpoint for the authored fox-led stealth route.
local D=require('Dora');local S={};S.__index=S
function S.open()
 local main,why=require('Story.InfiltrationStore').open();if not main then return nil,why end
 if not assert(main:load()).firstPatrol then return nil,'FIRST_PATROL_REQUIRED'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0InfiltrationPath (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL,started INTEGER NOT NULL CHECK(started IN(0,1)),completed INTEGER NOT NULL CHECK(completed IN(0,1)),report TEXT NOT NULL,CHECK(completed<=started))')<0 or D.DB:exec("INSERT OR IGNORE INTO lsd.Game0InfiltrationPath VALUES(1,1,0,0,'{}')")<0 then return nil,'SCHEMA_FAILED'end
 local rows=D.DB:query('SELECT schemaVersion FROM lsd.Game0InfiltrationPath WHERE id=1');if not rows or rows[1][1]~=1 then return nil,'INCOMPATIBLE_INFILTRATION_PATH'end
 return setmetatable({},S)
end
function S:load()
 local r=D.DB:query('SELECT schemaVersion,started,completed,report FROM lsd.Game0InfiltrationPath WHERE id=1');if not r or not r[1]then return nil,'READ_FAILED'end
 if r[1][1]~=1 then return nil,'INCOMPATIBLE_INFILTRATION_PATH'end
 return {started=r[1][2]==1,completed=r[1][3]==1,report=D.json.decode(r[1][4])}
end
function S:writeAsync(kind,proof)
 local fresh,why=S.open();if not fresh then return false,why end
 local state,err=fresh:load();if not state then return false,err end
 if self.busy then return false,'BUSY'end
 local main=assert(require('Story.InfiltrationStore').open());if not assert(main:load()).active then return false,'INACTIVE_INFILTRATION'end
 local queries
 if kind=='start'then
  local facts=assert(require('Story.Service').open()):summary();if not facts.completed['infiltration-fox-guide']then return false,'FOX_GUIDE_REQUIRED'end
  queries={'UPDATE lsd.Game0InfiltrationPath SET started=1 WHERE id=1'}
 elseif kind=='complete'then
  if state.completed then return true,'ALREADY_COMPLETE'end
  if not state.started or not proof or (proof.travelled or 0)<1500 or (proof.x or 0)<4050 or (proof.seconds or 0)<8 or not proof.covers or #proof.covers~=3 then return false,'PHYSICAL_PATH_REQUIRED'end
  for _,cover in ipairs(proof.covers)do if not cover.entered or not cover.left or cover.left-cover.entered<.4 then return false,'COVER_REQUIRED'end end
  queries={{'UPDATE lsd.Game0InfiltrationPath SET completed=1,report=? WHERE id=1',{{D.json.encode(proof,false,true)}}}}
 else return false,'INVALID_OPERATION'end
 self.busy=true;local ok=D.DB:transactionAsync(queries);self.busy=false;if ok then return true end;return false,'SAVE_FAILED'
end
return S
