-- Captured is earned by a completed 2-15 physical encounter, never by dialogue alone.
local D=require('Dora');local S={};S.__index=S
function S.open()
 local path,why=require('Story.InfiltrationPathStore').open();if not path then return nil,why end
 local state,err=path:load();if not state then return nil,err end
 if not state.completed then return nil,'INFILTRATION_PATH_REQUIRED'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0Researcher (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL,caught INTEGER NOT NULL CHECK(caught IN(0,1)),report TEXT NOT NULL)')<0 or D.DB:exec("INSERT OR IGNORE INTO lsd.Game0Researcher VALUES(1,1,0,'{}')")<0 then return nil,'SCHEMA_FAILED'end
 local self=setmetatable({},S);local loaded,readError=self:load();if not loaded then return nil,readError end;return self
end
function S:load()
 local rows=D.DB:query('SELECT schemaVersion,caught,report FROM lsd.Game0Researcher WHERE id=1')
 if not rows or not rows[1]then return nil,'READ_FAILED'end
 if rows[1][1]~=1 then return nil,'INCOMPATIBLE_RESEARCHER_SAVE'end
 return {caught=rows[1][2]==1,report=D.json.decode(rows[1][3])}
end
function S.operations(proof)
 local fresh,why=S.open();if not fresh then return nil,why end
 local state,err=fresh:load();if not state then return nil,err end
 if state.caught then return {},'ALREADY_CAUGHT'end
 local main=assert(require('Story.InfiltrationStore').open());if not assert(main:load()).active then return nil,'INACTIVE_INFILTRATION'end
 local facts=assert(require('Story.Service').open()):summary()
 if not facts.completed['researcher-contact'] then return nil,'RESEARCHER_CONTACT_REQUIRED'end
 if type(proof)~='table' or proof.encounter~='researcher-capture' or proof.status~='won' or (proof.seconds or 0)<=0 or type(proof.guards)~='table' or #proof.guards~=1 then return nil,'CAPTURE_BATTLE_REQUIRED'end
 local actor=proof.guards[1]
 if not actor.capturedAt or actor.escaped or type(actor.reactions)~='table' or #actor.reactions==0 then return nil,'CAPTURE_BATTLE_REQUIRED'end
 for _,hit in ipairs(actor.reactions)do
  if not hit.started or not hit.ended or not hit.duration or hit.duration<.6 or hit.ended-hit.started<hit.duration-.035 then return nil,'FULL_REACTION_REQUIRED'end
 end
 local hits=(proof.mentorHits or 0)+(proof.fireHits or 0)+(proof.windHits or 0)
 for _,id in ipairs({'ninilite','wuyun'})do
  local learner=proof.learners and proof.learners[id]
  if not learner or (learner.samples or 0)<=0 then return nil,'ADOPTED_LEARNERS_REQUIRED'end
  hits=hits+(learner.hits or 0)
 end
 if hits<=0 then return nil,'PHYSICAL_HITS_REQUIRED'end
 return {{'UPDATE lsd.Game0Researcher SET caught=1,report=? WHERE id=1 AND caught=0',{{D.json.encode(proof,false,true)}}}}
end
function S:writeAsync(proof)
 if self.busy then return false,'BUSY'end
 local ops,why=S.operations(proof);if not ops then return false,why end
 self.busy=true;local ok=D.DB:transactionAsync(ops);self.busy=false
 if ok then return true end;return false,'SAVE_FAILED'
end
return S
