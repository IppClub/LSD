-- Mission facts and one-time unlocks share the game DB; no UI-owned rewards.
local D = require("Dora")
local Model = require("Training.Model")
local Catalog = require("Mission.Catalog")
local Service = {}
-- Keep complete battle reports bounded, including the appended economy result.
local maxReportBytes = 1048576
Service.__index = Service
local checkpoints={['c0-roof']={'Story.RoofDuelStore','operations'},['c0-patrol']={'Story.InfiltrationStore','patrolOperations'},['c0-researcher']={'Story.ResearcherStore','operations'},['c0-patrol-second']={'Story.SecondPatrolStore','operations'}}
local legal={laser=true,fmove=true,bmove=true,idle=true}
local function exec(sql) return D.DB:exec(sql)>=0 end
local function query(sql,args) return D.DB:query(sql,args) end
function Service.open()
	if not D.DB:existDB("lsd") then return nil,"NO_GAME_DATABASE" end
	for _,sql in ipairs({
		"CREATE TABLE IF NOT EXISTS lsd.Game0MissionMeta (id INTEGER PRIMARY KEY, schemaVersion INTEGER NOT NULL, serial INTEGER NOT NULL)",
		"CREATE TABLE IF NOT EXISTS lsd.Game0MissionAttempts (id INTEGER PRIMARY KEY, mission TEXT NOT NULL, status TEXT NOT NULL, model TEXT NOT NULL, report TEXT)",
		"CREATE UNIQUE INDEX IF NOT EXISTS lsd.Game0MissionOneActive ON Game0MissionAttempts(status) WHERE status='active'",
		"CREATE TABLE IF NOT EXISTS lsd.Game0CombatEpisodes (attempt INTEGER PRIMARY KEY, payload TEXT NOT NULL)",
		"CREATE TABLE IF NOT EXISTS lsd.Game0MissionUnlocks (id TEXT PRIMARY KEY, mission TEXT NOT NULL, attempt INTEGER NOT NULL)"
	}) do if not exec(sql) then return nil,"SCHEMA_FAILED" end end
	if not exec("INSERT OR IGNORE INTO lsd.Game0MissionMeta VALUES (1,1,0)") then return nil,"SCHEMA_FAILED" end
	local rows=query("SELECT schemaVersion FROM lsd.Game0MissionMeta WHERE id=1")
	if not rows or not rows[1] or rows[1][1]~=1 then return nil,"INCOMPATIBLE_MISSION_SAVE" end
	if not exec("CREATE TABLE IF NOT EXISTS lsd.Game0MissionFormation (id INTEGER PRIMARY KEY CHECK(id=1), included INTEGER NOT NULL CHECK(included IN (0,1)))") then return nil,"SCHEMA_FAILED" end
 if not exec("CREATE TABLE IF NOT EXISTS lsd.Game0MissionSecondLearner (id INTEGER PRIMARY KEY CHECK(id=1), included INTEGER NOT NULL CHECK(included IN (0,1)))") then return nil,"SCHEMA_FAILED" end
 if not exec("CREATE TABLE IF NOT EXISTS lsd.Game0MissionRewards (id TEXT PRIMARY KEY,mission TEXT NOT NULL,attempt INTEGER NOT NULL,amount INTEGER NOT NULL CHECK(amount IN (1,2)))") then return nil,"SCHEMA_FAILED" end
 if not exec("INSERT OR IGNORE INTO lsd.Game0MissionRewards SELECT id,mission,attempt,1 FROM lsd.Game0MissionUnlocks WHERE mission='c0-m03'") then return nil,"SCHEMA_FAILED" end
	return setmetatable({},Service)
end
function Service:formation()
 local rows=query("SELECT included FROM lsd.Game0MissionFormation WHERE id=1")
 if not rows then return nil,"READ_FAILED" end
 local second=query("SELECT included FROM lsd.Game0MissionSecondLearner WHERE id=1")
 if not second then return nil,"READ_FAILED" end
 return {mentor=true,learner=(not rows[1] or rows[1][1]==1) and "ninilite" or nil,wuyun=second[1] and second[1][1]==1 and require("Story.Availability").canDeploy("wuyun") or nil}
end
function Service:saveFormationAsync(formation)
 if type(formation)~="table" or formation.mentor~=true or (formation.learner~=nil and formation.learner~="ninilite") or (formation.wuyun~=nil and formation.wuyun~=true) then return false,"INVALID_FORMATION" end
 if formation.wuyun then local allowed,why=require("Story.Availability").canDeploy("wuyun");if not allowed then return false,why end end
 return D.DB:transactionAsync({{"INSERT OR REPLACE INTO lsd.Game0MissionFormation VALUES (1,?)",{{formation.learner and 1 or 0}}},{"INSERT OR REPLACE INTO lsd.Game0MissionSecondLearner VALUES (1,?)",{{formation.wuyun and 1 or 0}}}})
end
function Service:summary()
	local rows=query("SELECT id,mission,status,report FROM lsd.Game0MissionAttempts ORDER BY id DESC LIMIT 1")
	local unlocks=query("SELECT id FROM lsd.Game0MissionUnlocks")
	if not rows or not unlocks then return nil,"READ_FAILED" end
	local rewards=query("SELECT id,amount FROM lsd.Game0MissionRewards")
 if not rewards then return nil,"READ_FAILED" end
 local result={unlocks={},rewards={}}
 for _,row in ipairs(rewards) do result.rewards[row[1]]=row[2] end
	for _,row in ipairs(unlocks) do result.unlocks[row[1]]=true end
	if rows[1] then result.last={id=rows[1][1],mission=rows[1][2],status=rows[1][3],report=rows[1][4]} end
	return result
end
function Service:recoverAsync()
	-- Restart resumes at a safe briefing; active physics/coroutines aren't saved.
	local rows=query("SELECT id,mission FROM lsd.Game0MissionAttempts WHERE status='active'")
 if not rows then return false,'READ_FAILED'end
 for _,row in ipairs(rows)do
  local ok,why=self:finishAsync({id=row[1],mission=row[2]},'aborted',{reason='Interrupted at safe restart'})
  if not ok then return false,why end
 end
 return true
end
function Service:beginAsync(missionId,model,formation,supplies)
	local mission=Catalog[missionId]
 if supplies~=nil and type(supplies)~='table'then return nil,'INVALID_SUPPLIES'end
	if not mission then return nil,"UNKNOWN_MISSION" end
 if mission.singleRun then
  local saved=query('SELECT id FROM lsd.Game0MissionUnlocks WHERE id=?',{mission.reward})
  if not saved then return nil,'READ_FAILED'end;if saved[1]then return nil,'ALREADY_WON'end
 end
	if mission.requiresStory then
		local rows=query("SELECT id FROM lsd.Game0StoryNodes WHERE id=?",{mission.requiresStory})
		if not rows or not rows[1] then return nil,"STORY_LOCKED" end
	end
 if mission.requiresMission then local rows=query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id=?",{mission.requiresMission}); if not rows or not rows[1] then return nil,"MISSION_LOCKED" end end
	if type(formation)~="table" or formation.mentor~=true or formation.learner~=mission.learner then return nil,"INVALID_FORMATION" end
 if formation.wuyun then local allowed,why=require("Story.Availability").canDeploy("wuyun");if not allowed then return nil,why end end
 local payloadModel=model
 if mission.noModel then
  if model~=nil or formation.wuyun then return nil,"INVALID_FORMATION" end
  payloadModel={schemaVersion=1,control="mentor",partner=mission.partner or "liyena"}
 elseif mission.learners then
  if not formation.wuyun then return nil,"INVALID_FORMATION" end
  if type(model)~="table" then return nil,"TRAINING_REQUIRED" end
  for _,id in ipairs(mission.learners) do
   if not Model.validate(model[id],id,require("Training.Characters")[id].legal) then return nil,"TRAINING_REQUIRED_"..id end
  end
 else
  if not Model.validate(model,mission.learner,legal) then return nil,"TRAINING_REQUIRED" end
 end
 if mission.auxiliary then
  local selection,why=require('Ground.AuxiliarySelection').open();if not selection then return nil,why end
  local selected,why=selection:load();if not selected then return nil,why end
  if not selected.recorded then return nil,'AUXILIARY_CONFIRMATION_REQUIRED'end
  payloadModel={ninilite=model,auxiliaryVariant=selected.variant}
 end
	local active=query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")
	if not active then return nil,"READ_FAILED" end
	if #active>0 or self.busy then return nil,"MISSION_ALREADY_ACTIVE" end
	self.busy=true
	local payload=D.json.encode(payloadModel,false,true)
	local operations={
		"UPDATE lsd.Game0MissionMeta SET serial=serial+1 WHERE id=1 AND schemaVersion=1",
		{"INSERT INTO lsd.Game0MissionAttempts(id,mission,status,model) SELECT serial,?,'active',? FROM lsd.Game0MissionMeta WHERE id=1",{{missionId,payload}}}
 }
 local ok,why
 if supplies then
  local economy=require('Economy.Store')
  ok,why=economy.open()
  if ok then
   local serial=query('SELECT serial FROM lsd.Game0MissionMeta WHERE id=1')
   if serial and serial[1]then
    local id=serial[1][1]+1
    -- Explicit ID conflicts roll back reservation if another service wins the race.
    operations[2]={"INSERT INTO lsd.Game0MissionAttempts(id,mission,status,model) VALUES(?,?,'active',?)",{{id,missionId,payload}}}
    ok,why=economy.beginAsync('mission:'..id,supplies.loadout,supplies.reward,operations)
   else ok=false;why='READ_FAILED'end
  end
 else ok=D.DB:transactionAsync(operations) end
	self.busy=false
	if not ok then return nil,why or "WRITE_FAILED" end
	local rows=query("SELECT id,model FROM lsd.Game0MissionAttempts WHERE status='active' ORDER BY id DESC LIMIT 1")
	if not rows or not rows[1] then return nil,"READ_FAILED" end
 local saved=D.json.decode(rows[1][2],32)
 return {id=rows[1][1],mission=missionId,supplyAttempt=supplies and ('mission:'..rows[1][1]) or nil,model=(mission.learners or mission.auxiliary)and saved.ninilite or saved,auxiliaryVariant=mission.auxiliary and saved.auxiliaryVariant or nil,models=mission.learners and saved or nil}
end
function Service:finishAsync(attempt,status,report,episode)
 if episode and episode.resources and episode.resources.mode=='virtual'then return false,'VIRTUAL_RESOURCES_NOT_MISSION'end
	if type(attempt)~="table" or not Catalog[attempt.mission] or type(attempt.id)~="number" or attempt.id%1~=0 then return false,"INVALID_ATTEMPT" end
	if status~="won" and status~="failed" and status~="aborted" then return false,"INVALID_RESULT" end
	local rows=query("SELECT mission,status,model FROM lsd.Game0MissionAttempts WHERE id=?",{attempt.id})
	if not rows or not rows[1] then return false,"UNKNOWN_ATTEMPT" end
	if rows[1][1]~=attempt.mission then return false,"INVALID_ATTEMPT" end
	if rows[1][2]~="active" then return rows[1][2]==status,rows[1][2]==status and "ALREADY_COMMITTED" or "RESULT_CONFLICT" end
 if attempt.mission=='c0-yingzhao'then
  if not episode or not require('Enemy.BigYingzhaoEvidence').validate(episode)or episode.boss.status~=status or episode.episode~='mission:'..attempt.id then return false,'BOSS_EVIDENCE_REQUIRED'end
 end
 if attempt.mission=='c0-disarm'and status=='won'then
  if not episode or not require('Training.DisarmMissionEvidence').validate(episode)or episode.disarm.status~='won'or episode.episode~='mission:'..attempt.id then return false,'DISARM_EVIDENCE_REQUIRED'end
 end
 if attempt.mission=='c0-m09'and status=='won'then
  local saved=D.json.decode(rows[1][3],32)
  local valid,why=require('Final.Proof').validate(report,saved.ninilite,saved.auxiliaryVariant);if not valid then return false,why end
 end
 if attempt.mission=='c0-m08'and status=='won'then
  local model=D.json.decode(rows[1][3],32)
  local valid,why=require('Rescue.Proof').validate(report,model);if not valid then return false,why end
 end
 if attempt.mission=='c0-m07'and status=='won'then
  local model=D.json.decode(rows[1][3],32)
  local valid,why=require('Academy.DefenseProof').validate(report,model);if not valid then return false,why end
 end
	local payload=D.json.encode(report or {},false,true)
	if not payload or #payload>maxReportBytes then return false,"INVALID_REPORT" end
	local episodePayload
 if episode then
  local why;episodePayload,why=require('Training.CombatStore').encode(episode)
  if not episodePayload then return false,why end
 end
 if checkpoints[attempt.mission]and status=='won'then
  local entry=checkpoints[attempt.mission];local sqls,why=require(entry[1])[entry[2]](report);if not sqls then return false,why end
 end
 local mission=Catalog[attempt.mission]
 local function operations(economyResult)
 if economyResult then
  local savedReport=D.json.decode(payload,32);savedReport.economy=economyResult;payload=D.json.encode(savedReport,false,true)
  if not payload or #payload>maxReportBytes then return nil,'INVALID_REPORT'end
 end
 local sqls={{"UPDATE lsd.Game0MissionAttempts SET status=?,report=? WHERE id=? AND mission=? AND status='active'",{{status,payload,attempt.id,attempt.mission}}}}
 if episodePayload then sqls[#sqls+1]={"INSERT INTO lsd.Game0CombatEpisodes(attempt,payload) VALUES (?,?)",{{attempt.id,episodePayload}}}end
 if status=='won'and checkpoints[attempt.mission]then
  local entry=checkpoints[attempt.mission];local changes=assert(require(entry[1])[entry[2]](D.json.decode(payload,32)))
  for _,change in ipairs(changes)do sqls[#sqls+1]=change end
 end
	if status=="won" then
		sqls[#sqls+1]={"INSERT OR IGNORE INTO lsd.Game0MissionUnlocks(id,mission,attempt) SELECT ?,mission,id FROM lsd.Game0MissionAttempts WHERE id=? AND mission=? AND status='won'",{{mission.reward,attempt.id,attempt.mission}}}
  if attempt.mission=="c0-m03" then
   local amount=require("Ground.Tactics").rewardMultiplier(report)
   sqls[#sqls+1]={"INSERT OR IGNORE INTO lsd.Game0MissionRewards SELECT ?,mission,id,? FROM lsd.Game0MissionAttempts WHERE id=? AND mission=? AND status='won'",{{mission.reward,amount,attempt.id,attempt.mission}}}
  end
	end
	return sqls
 end
 local economy=require('Economy.Store')
 local ledger,why=economy.find('mission:'..attempt.id)
 if ledger then
  if episode then
   local e=episode.resources
   if not e or e.attempt~=ledger.attempt or not require('Training.FlowerIdentity').equal(e.events,ledger.events) or not require('Training.FlowerIdentity').equal(e.quote,ledger.quote) or e.spent~=ledger.spent then return false,'RESOURCE_LEDGER_MISMATCH'end
  end
  local result,why=economy.settleAsync(ledger.attempt,status,operations)
  if not result then return false,why end
  if type(report)=='table'then report.economy=result end
 elseif why~='NOT_RECORDED'then return false,why
 elseif not D.DB:transactionAsync(operations())then return false,'WRITE_FAILED'end
	return true,"COMMITTED"
end
return Service
