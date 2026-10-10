-- Separate checkpoint: interrogation and the first patrol remain untouched.
local D=require('Dora');local S={};S.__index=S
function S.open()
 local story,why=require('Story.Service').open();if not story then return nil,why end
 if not story:summary().completed['researcher-interrogation']then return nil,'INTERROGATION_REQUIRED'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0SecondPatrol (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL,completed INTEGER NOT NULL CHECK(completed IN(0,1)),report TEXT NOT NULL)')<0 or D.DB:exec("INSERT OR IGNORE INTO lsd.Game0SecondPatrol VALUES(1,1,0,'{}')")<0 then return nil,'SCHEMA_FAILED'end
 local self=setmetatable({},S);local state,err=self:load();if not state then return nil,err end;return self
end
function S:load()
 local rows=D.DB:query('SELECT schemaVersion,completed,report FROM lsd.Game0SecondPatrol WHERE id=1')
 if not rows or not rows[1]then return nil,'READ_FAILED'end
 if rows[1][1]~=1 then return nil,'INCOMPATIBLE_SECOND_PATROL_SAVE'end
 return {completed=rows[1][2]==1,report=D.json.decode(rows[1][3])}
end
function S.operations(proof)
 local fresh,why=S.open();if not fresh then return nil,why end
 local state,err=fresh:load();if not state then return nil,err end
 if state.completed then return {},'ALREADY_WON'end
 local main=assert(require('Story.InfiltrationStore').open());if not assert(main:load()).active then return nil,'INACTIVE_INFILTRATION'end
 if type(proof)~='table' or proof.encounter~='second-patrol' or proof.status~='won' or (proof.seconds or 0)<=0 or (proof.mentorHP or 0)<=0 or (proof.mentorHits or 0)<=0 or (proof.fireHits or 0)<=0 or type(proof.guards)~='table' or #proof.guards~=3 then return nil,'SECOND_PATROL_BATTLE_REQUIRED'end
 local ni=proof.learners and proof.learners.ninilite
 if not ni or (ni.samples or 0)<=0 or (ni.modelActions or 0)<=0 or (ni.hp or 0)<=0 then return nil,'ADOPTED_LEARNER_REQUIRED'end
 if proof.learners.wuyun or (proof.windHits or 0)~=0 then return nil,'WUYUN_MUST_STAY'end
 for _,g in ipairs(proof.guards)do
  if not g.loseStarted or not g.loseEnded or g.loseEnded-g.loseStarted<1.55 then return nil,'FULL_DEFEAT_REQUIRED'end
  for _,strike in ipairs(g.strikes or {})do
   if not strike.completed or strike.completed-strike.started<1.35 then return nil,'FULL_ATTACK_REQUIRED'end
  end
 end
 return {{'UPDATE lsd.Game0SecondPatrol SET completed=1,report=? WHERE id=1 AND completed=0',{{D.json.encode(proof,false,true)}}}}
end
function S:writeAsync(proof)
 if self.busy then return false,'BUSY'end
 local ops,why=S.operations(proof);if not ops then return false,why end
 self.busy=true;local ok=D.DB:transactionAsync(ops);self.busy=false
 if ok then return true end;return false,'SAVE_FAILED'
end
return S
