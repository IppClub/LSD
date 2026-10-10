local D=require('Dora');local S={};S.__index=S
function S.open()
 local story,why=require('Story.Service').open();if not story then return nil,why end
 if not story:summary().completed['roof-confrontation']then return nil,'ROOF_CONFRONTATION_REQUIRED'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0RoofDuel(id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL,completed INTEGER NOT NULL CHECK(completed IN(0,1)),report TEXT NOT NULL)')<0 or D.DB:exec("INSERT OR IGNORE INTO lsd.Game0RoofDuel VALUES(1,1,0,'{}')")<0 then return nil,'SCHEMA_FAILED'end
 local self=setmetatable({},S);local state,why=self:load();if not state then return nil,why end;return self
end
function S:load()
 local rows=D.DB:query('SELECT schemaVersion,completed,report FROM lsd.Game0RoofDuel WHERE id=1')
 if not rows or not rows[1]then return nil,'READ_FAILED'end
 if rows[1][1]~=1 then return nil,'INCOMPATIBLE_ROOF_DUEL_SAVE'end
 local ok,proof=pcall(D.json.decode,rows[1][3]);if not ok or type(proof)~='table'then return nil,'INVALID_ROOF_DUEL_SAVE'end
 return {completed=rows[1][2]==1,report=proof}
end
function S.operations(p)
 local fresh,why=S.open();if not fresh then return nil,why end;local state,why=fresh:load();if not state then return nil,why end;if state.completed then return {},'ALREADY_WON'end
 local roof,why=require('Story.RoofStore').open();if not roof then return nil,why end;local r=roof:load();if not r or not r.active or r.stage~=2 then return nil,'ACTIVE_ROOF_REQUIRED'end
 if type(p)~='table'or p.encounter~='roof-wuyun'or p.status~='won'or (p.seconds or 0)<=0 or (p.mentorHP or 0)<=0 or p.enemyHP~=0 then return nil,'ROOF_VICTORY_REQUIRED'end
 local ni=p.learner;if not ni or (ni.samples or 0)<=0 or (ni.modelActions or 0)<=0 or (ni.hp or 0)<=0 then return nil,'ADOPTED_LEARNER_REQUIRED'end
 if (p.mentorHits or 0)+(ni.hits or 0)+(p.fireHits or 0)<=0 then return nil,'COMBAT_DAMAGE_REQUIRED'end
 local o=p.opponent;if not o or not o.loseStarted or not o.loseEnded or (o.loseDuration or 0)<=0 or o.loseEnded-o.loseStarted<o.loseDuration-.04 then return nil,'FULL_DEFEAT_REQUIRED'end
 for _,a in ipairs(o.strikes or {})do if not a.completed or not a.releaseAt or a.completed<a.releaseAt or a.completed-a.started<a.duration-.04 or a.releaseAt-a.started<(a.kind=='shot'and .48 or .38)then return nil,'FULL_ATTACK_REQUIRED'end end
 return {{'UPDATE lsd.Game0RoofDuel SET completed=1,report=? WHERE id=1 AND completed=0',{{D.json.encode(p,false,true)}}}}
end
function S:writeAsync(p)
 if self.busy then return false,'BUSY'end
 local ops,why=S.operations(p);if not ops then return false,why end
 if #ops==0 then return true,why end
 self.busy=true;local ok=D.DB:transactionAsync(ops);self.busy=false
 if ok then return true end;return false,'SAVE_FAILED'
end
return S
