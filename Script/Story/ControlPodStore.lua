local D=require('Dora');local G=require('Factory.ControlPodGeometry');local S={};S.__index=S
function S.open()
 local second,why=require('Story.SecondPatrolStore').open();if not second then return nil,why end
 local won,err=second:load();if not won then return nil,err end;if not won.completed then return nil,'SECOND_PATROL_REQUIRED'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0ControlPod (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL,active INTEGER NOT NULL,floor INTEGER NOT NULL CHECK(floor BETWEEN 1 AND 7),doorOpen INTEGER NOT NULL,report TEXT NOT NULL)')<0 or D.DB:exec("INSERT OR IGNORE INTO lsd.Game0ControlPod VALUES(1,1,0,1,0,'{\"floors\":[]}')")<0 then return nil,'SCHEMA_FAILED'end
 local self=setmetatable({},S);local state,why=self:load();if not state then return nil,why end;return self
end
function S:load()
 local rows=D.DB:query('SELECT schemaVersion,active,floor,doorOpen,report FROM lsd.Game0ControlPod WHERE id=1')
 if not rows or not rows[1]then return nil,'READ_FAILED'end
 local r=rows[1];if r[1]~=1 then return nil,'INCOMPATIBLE_CONTROL_POD_SAVE'end
 return {active=r[2]==1,floor=r[3],doorOpen=r[4]==1,report=D.json.decode(r[5])}
end
function S:writeAsync(kind,proof)
 if self.busy then return false,'BUSY'end
 local current,why=S.open();if not current then return false,why end
 local state,err=current:load();if not state then return false,err end
 local query
 if kind=='enter'then
  local main=assert(require('Story.InfiltrationStore').open());if not assert(main:load()).active then return false,'INACTIVE_INFILTRATION'end
  query={'UPDATE lsd.Game0ControlPod SET active=1 WHERE id=1'}
 elseif kind=='leave'then query={'UPDATE lsd.Game0ControlPod SET active=0 WHERE id=1'}
 elseif kind=='floor'then
  if not state.active or type(proof)~='table' or proof.from~=state.floor or type(proof.to)~='number' or proof.to<1 or proof.to>7 or math.abs(proof.to-proof.from)~=1 or (proof.seconds or 0)<G.duration or (proof.samples or 0)<60 or (proof.maxX or 0)-(proof.minX or 0)<G.radius*1.9 or math.abs((proof.endY or 0)-G.floorY(proof.to))>1 then return false,'STAIR_TRAVERSAL_REQUIRED'end
  state.report.floors[#state.report.floors+1]=proof
  query={{'UPDATE lsd.Game0ControlPod SET floor=?,report=? WHERE id=1',{{proof.to,D.json.encode(state.report,false,true)}}}}
 elseif kind=='door'then
  if state.doorOpen then return true,'ALREADY_OPEN'end
  if not state.active or state.floor~=7 or type(proof)~='table' or (proof.seconds or 0)<2.75 or (proof.angle or 0)<100 or (proof.soundHandle or 0)<=0 or not proof.barrierRemoved or math.abs((proof.playerX or 0)-(G.doorX-340))>210 then return false,'DOOR_ACTION_REQUIRED'end
  state.report.door=proof
  query={{'UPDATE lsd.Game0ControlPod SET doorOpen=1,report=? WHERE id=1',{{D.json.encode(state.report,false,true)}}}}
 else return false,'INVALID_OPERATION'end
 self.busy=true;local ok=D.DB:transactionAsync(query);self.busy=false;if ok then return true end;return false,'SAVE_FAILED'
end
return S
