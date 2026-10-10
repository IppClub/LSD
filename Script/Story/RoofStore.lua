local D=require('Dora');local G=require('Factory.RoofGeometry');local S={};S.__index=S
function S.open()
 local pod,why=require('Story.ControlPodStore').open();if not pod then return nil,why end
 local state,err=pod:load();if not state then return nil,err end
 local story=require('Story.Service').open()
 if not state.doorOpen or not story or not story:summary().completed['control-pod-researchers']then return nil,'CONTROL_POD_DIALOGUE_REQUIRED'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0Roof (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL,active INTEGER NOT NULL,stage INTEGER NOT NULL CHECK(stage BETWEEN 0 AND 2),report TEXT NOT NULL)')<0 or D.DB:exec("INSERT OR IGNORE INTO lsd.Game0Roof VALUES(1,1,0,0,'{}')")<0 then return nil,'SCHEMA_FAILED'end
 local self=setmetatable({},S);local loaded,e=self:load();if not loaded then return nil,e end;return self
end
function S:load()
 local rows=D.DB:query('SELECT schemaVersion,active,stage,report FROM lsd.Game0Roof WHERE id=1');if not rows or not rows[1]then return nil,'READ_FAILED'end
 local r=rows[1];if r[1]~=1 then return nil,'INCOMPATIBLE_ROOF_SAVE'end
 local report=D.json.decode(r[4]);if type(report)~='table'then return nil,'INVALID_ROOF_SAVE'end
 return {active=r[2]==1,stage=r[3],report=report}
end
function S:writeAsync(kind,proof)
 if self.busy then return false,'BUSY'end
 local current,why=S.open();if not current then return false,why end
 local state,err=current:load();if not state then return false,err end;local query
 if kind=='enter'then
  local main=assert(require('Story.InfiltrationStore').open());if not assert(main:load()).active then return false,'INACTIVE_INFILTRATION'end
  query={'UPDATE lsd.Game0Roof SET active=1 WHERE id=1','UPDATE lsd.Game0ControlPod SET active=0 WHERE id=1'}
 elseif kind=='leave'then query={'UPDATE lsd.Game0Roof SET active=0 WHERE id=1','UPDATE lsd.Game0ControlPod SET active=1 WHERE id=1'}
 elseif kind=='stairs'then
  if not state.active or state.stage~=0 or type(proof)~='table' or (proof.seconds or 0)<G.stairsSeconds or (proof.samples or 0)<120 or type(proof.actors)~='table' or #proof.actors~=2 then return false,'ROOF_STAIRS_REQUIRED'end
  for _,a in ipairs(proof.actors)do if math.abs((a.endX or 0)-G.stairEnd)>1 or math.abs((a.endY or 0)-G.stairY)>1 or not a.landingCollision then return false,'ROOF_STAIRS_REQUIRED'end end
  state.report.stairs=proof;query={{'UPDATE lsd.Game0Roof SET stage=1,report=? WHERE id=1',{{D.json.encode(state.report,false,true)}}}}
 elseif kind=='climb'then
  if not state.active or state.stage~=1 or type(proof)~='table' or type(proof.actors)~='table' or #proof.actors~=2 then return false,'ROOF_CLIMB_REQUIRED'end
  for _,a in ipairs(proof.actors)do
   if a.phase~='complete' or (a.contactSamples or 0)<120 or (a.flightSamples or 0)<30 or (a.maxSupportError or 999)>1 or (a.maxFrameDisplacement or 999)>30 or (a.minCrossingClearance or -999)<-5 or math.abs((a.endY or 0)-G.top)>1 or math.abs((a.endX or 0)-G.landingX)>1 or not a.landingCollision then return false,'ROOF_CLIMB_REQUIRED'end
  end
  state.report.climb=proof;query={{'UPDATE lsd.Game0Roof SET stage=2,report=? WHERE id=1',{{D.json.encode(state.report,false,true)}}}}
 else return false,'INVALID_OPERATION'end
 self.busy=true;local ok=D.DB:transactionAsync(query);self.busy=false;if ok then return true end;return false,'SAVE_FAILED'
end
return S
