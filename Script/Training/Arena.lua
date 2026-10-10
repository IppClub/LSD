-- Real UnitAction demonstrations and learned decisions share one executor.
-- Tutorial-specific HP/AP observers and hand-written NPC AI are not installed.
local D = require("Dora")
local P = D.Platformer
local Recorder = require("Training.Recorder")
local Model = require("Training.Model")
local Animation = require("CombatAnimation")
local EnemyCombat = require("Training.EnemyCombat")
local partyLayers={charM=-1,charF=-1,ninilite=0,wuyun=1}
local Arena = {}
Arena.__index = Arena
local CombatFeatures=require("Training.CombatFeatures")
local Characters=require("Training.Characters")
local physical = {melee="trainingMelee", laser = "trainingLaser", fmove = "trainingForward", bmove = "trainingBack", idle = "trainingWait"}

function Arena:snapshot()
	local u, enemy = self.student, self.enemy
	local state={distance = math.abs(u.x - enemy.x), facing = ((enemy.x >= u.x) == u.faceRight) and "yes" or "no",
		enemyAction = self.enemyPhase, attackReady = D.App.runningTime >= self.nextShot and "yes" or "no"}
 state.enemyKind=CombatFeatures.enemyKind(self.enemyAsset)
 state.healthBand=self.studentHP<=25 and 'low' or 'healthy'
 state.energyReady=self.studentEnergy==nil and 'unlimited' or self.studentEnergy>=self.shotEnergyCost and 'yes' or 'no'
 state.armorState='unarmored';state.observedPart='whole'
 if self.partObservation then local part,armor=self.partObservation();state.observedPart=CombatFeatures.part(part);state.armorState=armor end
 return state
end

function Arena:isAttacking() return self.student:isDoing(self.physical.laser) or self.student:isDoing(self.physical.melee) end

function Arena:available(action)
 if action=='laser' and self.student.data.weaponDisarmed then return false,'WEAPON_DISARMED'end
 if self.supplies and (action=='laser' or action=='melee')then
  local ok,why=self.supplies:canSpend(self.character.id,action=='laser' and 'emp' or 'blade');if not ok then return false,why end
 end
 if require('Combat.Displacement').blocked(self.student)then return false end
 if self.studentEffects and self.studentEffects:blocked(self.student,action) then return false end
	if not self.character.legal[action] or not self.physical[action] or self.studentHP <= 0 or self.enemyHP <= 0 or D.App.runningTime < (self.studentStaggerUntil or 0) then return false end
	if action == "melee" then return not self:isAttacking() and D.App.runningTime>=self.nextShot and self.student.onSurface end
	if action == "laser" then return not self:isAttacking() and (not self.studentEnergy or self.studentEnergy>=self.shotEnergyCost) and D.App.runningTime >= self.nextShot and self.student.onSurface end
	return self.student.onSurface and not self:isAttacking()
end

function Arena:request(action, source, movementFace)
 if source=='demo' and self.qSession and not self.qSession.closed then return false,'Q_TRAINING_ACTIVE'end
 if source=="demo" and self.demoInputAvailable and not self.demoInputAvailable() then return false,"INPUT_SUSPENDED" end
	if self.mode ~= "demo" and self.mode ~= "trial" then return false, "NOT_PLAYING" end
	local state = self:snapshot()
	local available,unavailableReason=self:available(action)
	if not available then
		if source == "demo" then self.recorder:record(state, action, false) end
		return false, unavailableReason or "ACTION_UNAVAILABLE"
	end
	-- Turning is an explicit execution prerequisite, never a learned label.
	local face
 if (action=='fmove'or action=='bmove')and type(movementFace)=='boolean'then face=movementFace
 else face=self.targetFacingForAction and self.targetFacingForAction(action)end
 if face==nil then face=self.enemy.x>=self.student.x end
 if self.student.faceRight~=face then
		self.student.faceRight = face
		self.metrics.turns = self.metrics.turns + 1
		state = self:snapshot()
	end
 if action=='laser' and source=='model' and self.selectTargetForAction then
  local selected,why=self.selectTargetForAction(state)
  if not selected then self.metrics.targetUnavailable=(self.metrics.targetUnavailable or 0)+1;return false,why end
 end
	if self.student:isDoing(self.physical[action]) then
  if self.continuousDecisions and (action=='idle' or action=='fmove' or action=='bmove') and self.beginMovementAction and self.finishMovementAction then
   self.finishMovementAction(self.movementStep,self.student,action)
   self.movementStep=self.beginMovementAction(self.student,action,source or 'scripted')
   self.metrics.modelActions=self.metrics.modelActions+1;self.metrics.actions[action]=(self.metrics.actions[action]or 0)+1;self.lastAcceptedState=state
   return true,'CONTINUED'
  end
  return false,"ALREADY_RUNNING"
 end
	local previousSource=self.currentActionSource;self.currentActionSource=source
	local succeeded = self.student:start(self.physical[action])
 self.currentActionSource=previousSource
	if source == "demo" then
		self.recorder:record(state, action, succeeded)
	elseif succeeded then
  if source=="baseline" then self.metrics.baselineActions=self.metrics.baselineActions+1
  else self.metrics.modelActions=self.metrics.modelActions+1 end
 end
 if succeeded then self.metrics.actions[action]=(self.metrics.actions[action] or 0)+1 end
	if succeeded then self.lastAcceptedState=state end
	return succeeded, succeeded and "STARTED" or "ACTION_REJECTED"
end

function Arena:beginQRound(options)
 if (self.evaluating and not self.qTraining) or self.closed then return nil,'NOT_AVAILABLE'end
 local session,why=require('Training.QSession').new(self,options)
 if not session then return nil,why end
 self:resetRound(options and options.distance)
 self.qSession=session;self.mode='demo';self.recorder:stop()
 self.message='强化训练进行中；训练结果尚未采用。'
 return session
end

-- Candidate training never mutates the currently adopted policy.
function Arena:trainQAsync(seed)
 if self.evaluating or self.closed or (self.mode~='demo' and self.mode~='review')then return nil,'NOT_AVAILABLE'end
 if self.candidate or (self.mode=='demo' and #self.recorder.samples>0)then return nil,'UNREVIEWED_WORK'end
 local Q=require('Training.QModel')
 local model,why
 if self.adopted and self.adopted.algorithm=='qlearning'then model,why=Q.restore(self.adopted,self.character.id)
 else model=Q.new({characterId=self.character.id})end
 if not model then return nil,why end
 seed=seed or os.time()%2147483646+1
 if type(seed)~='number' or seed%1~=0 or seed<1 or seed>=2147483647 then return nil,'INVALID_SEED'end
 local randomState=seed
 local function random()randomState=(randomState*16807)%2147483647;return (randomState-1)/2147483646 end
 self.qTraining=true;self.qCancelled=false;self.evaluating=true;self.evaluation=nil
 local rounds={};local before=model.updates
 local initialModel=before>0 and model:snapshot() or nil
 local runId="q-"..self.character.id.."-"..seed.."-"..math.floor(D.App.runningTime*1000000)
 local ok,result=xpcall(function()
  for index,distance in ipairs({180,460,800})do
   if self.closed or self.qCancelled then return nil end
   local session,err=self:beginQRound({distance=distance,model=model,epsilon=.35,random=random})
   if not session then error(err)end
   self.message='自主训练 '..index..'/3；完成后请先观看三场试战，再决定是否采用。'
   while not session.closed and not self.closed and not self.qCancelled do D.sleep(.05)end
   if self.closed or self.qCancelled then return nil end
   if session.reason~='VICTORY' and session.reason~='DEFEAT' and session.reason~='TIMEOUT'then error(session.reason)end
   rounds[#rounds+1]={distance=distance,reason=session.reason,steps=session.steps}
  end
  if model.updates==before then error('NO_TRANSITIONS')end
  local candidate=model:snapshot();local valid,err=Q.validate(candidate,self.character.id);if not valid then error(err)end
  return candidate
 end,debug.traceback)
 self.qTraining=false;self.evaluating=false
 if self.closed then return nil,'CLOSED'end
 self.mode='review'
 if not ok or not result then
  if self.qSession then self.qSession:abort(self.qCancelled and 'CANCELLED' or 'TRAINING_FAILED')end
  for _,bullet in ipairs(self.projectiles)do bullet:removeFromParent()end;self.projectiles={}
  self.message=self.qCancelled and '自主训练已停止，原成果保留。' or '本轮自主训练未完成，原成果保留。'
  return nil,self.qCancelled and 'CANCELLED' or result
 end
 result.trainingRunId=runId
 self.candidate=result;self.qTrainingReport={schemaVersion=1,id=runId,characterId=self.character.id,seed=seed,epsilon=.35,enemyAsset=self.enemyAsset,roundLimit=self.roundLimit or 35,rewardPolicy=result.rewardPolicy,featureSchemaVersion=3,actionSetVersion=1,initialModel=initialModel,rounds=rounds,newUpdates=model.updates-before}
 self.message='自主训练完成，新增 '..(model.updates-before)..' 步；请观看三场对照后决定是否采用。'
 return result
end
function Arena:cancelQTraining()
 if not self.qTraining then return false end
 self.qCancelled=true
 if self.qSession then self.qSession:abort('CANCELLED')end
 return true
end

function Arena:resetRound(distance)
 require('Combat.Displacement').clear(self.student)
	if self.qSession then self.qSession:abort('ROUND_RESET');self.qSession=nil end
	self.qProjectileUntil=0;self.lastAcceptedState=nil
	for _, bullet in ipairs(self.projectiles or {}) do bullet:removeFromParent() end
	self.projectiles = {}
	self.result = nil; self.lastDecision = nil
	self.student:stop(); self.enemy:stop()
	self.student.position = D.Vec2(self.origin, self.world.offset + 155)
	self.enemy.position = D.Vec2(self.origin + (distance or 400), self.world.offset + (self.enemyAsset=="dataotie" and 195 or self.enemyAsset=="dahuayao" and 220 or 155))
	self.student.velocity = D.Vec2.zero; self.enemy.velocity = D.Vec2.zero
	self.student.faceRight = true; self.enemy.faceRight = false
	self.studentHP, self.enemyHP = 100, self.enemyMaxHP
	self.studentEnergy=self.initialEnergy
	self.nextShot, self.nextEnemy = 0, D.App.runningTime + 1.5
	self.enemyPhase = "idle"
	self.enemyStrike = nil
	self.enemyAttacks = {}
	if self.enemyCombat then self.enemyCombat:reset() end
	self.roundStarted = D.App.runningTime
	self.metrics = {modelActions = 0, baselineActions=0, actions={}, fallback = 0, unavailable = 0, turns = 0, hits = 0, damageTaken = 0}
	Animation.rest(self.student)
	Animation.rest(self.enemy)
 if self.resetEncounter then self.resetEncounter()end
end

function Arena:beginDemo(distance)
	self.recorder = Recorder.new({characterId = self.character.id, actions = self.character.actions})
	self.candidate = nil
	self.evaluation = nil
	self.message = nil
	self:resetRound(distance)
	self.mode = "demo"
end

function Arena:continueDemo(distance)
 if (self.mode~="demo" and self.mode~="review") or self.evaluating then return false,"NOT_DEMONSTRATING" end
 self.mode="demo"; self.recorder.active=true; self.candidate=nil; self.evaluation=nil
 self:resetRound(distance)
 -- A new explicit opponent is a new episode, not one held movement command.
 self.recorder.lastKey=nil
 self.message="对练已重置，保留 "..#self.recorder.samples.." 条示范；可继续补充。"
 return true
end

function Arena:finishDemoAsync()
 if self.qSession and not self.qSession.closed then return nil,'Q_TRAINING_ACTIVE'end
	if self.mode ~= "demo" then return nil, "NOT_DEMONSTRATING" end
	self.mode = "building"
	self.student:stop(); self.student.velocityX = 0
	self.recorder:stop()
	local distinct = 0
	for _ in pairs(self.recorder.counts) do distinct = distinct + 1 end
	if #self.recorder.samples < 6 or distinct < 2 then
		self.mode = "review"
		self.message = "示范还不够：至少 6 条有效样本和两种动作。请补充远处接近、近处射击或等待。"
		return nil, "INSUFFICIENT_COVERAGE"
	end
	local candidate, err = Model.buildAsync(self.recorder)
	if self.closed then return nil, "CLOSED" end
	self.candidate = candidate
	self.evaluation = nil
	self.mode = "review"
	local learned={}; if candidate then for _,rule in ipairs(candidate.rules) do learned[rule.action]=true end end
 local variety=0; for _ in pairs(learned) do variety=variety+1 end
 self.message = candidate and ("候选模型：" .. candidate.sampleCount .. " 条示范，学会 "..variety.." 种动作，示范准确率 "..math.floor(candidate.trainingAccuracy*100+0.5).."%。"..(variety==1 and "可补充不同距离的示范，再观察对照。" or "可观看试战后采用。")) or ("无法学习：" .. tostring(err) .. "，请重新示范")
	return candidate, err
end

function Arena:beginTrial(distance, model, baseline)
	if not baseline then model = model or self.candidate end
	if not model and not baseline then return false, "NO_CANDIDATE" end
 if not baseline then local ok,err=Model.validate(model,self.character.id,self.character.legal); if not ok then return false,err end end
	self:resetRound(distance or 530)
	self.trialModel = model; self.trialBaseline=baseline or false
	self.mode = "trial"
	self.message = (self.comparison or "候选") .. "第 " .. (self.trialIndex or 1) .. "/3 场试战进行中"
	self.nextDecision = 0
	return true
end

function Arena:adopt()
	if self.evaluating then return false, "EVALUATION_RUNNING" end
	if self.mode ~= "review" or not self.candidate then return false, "NO_REVIEWED_CANDIDATE" end
	if not self.evaluation or self.evaluation.model ~= self.candidate then return false, "EVALUATION_REQUIRED" end
	self.previous, self.adopted = self.adopted, self.candidate
	self.candidate = nil
	self.message = "已采用"..self.character.name.."的训练成果"
	return true
end

-- All controllers use the same reset, physics, attacks, placements and action cadence.
Arena.trialDistances={220,420,680}
function Arena:runComparisonAsync(model,label,baseline)
 local rounds={}
 for index,distance in ipairs(Arena.trialDistances) do
  self.trialIndex=index; self.comparison=label
  if self.closed then return nil,"CLOSED" end
  local started,why=self:beginTrial(distance,model,baseline)
  if not started then return nil,why end
  while self.mode=="trial" and not self.closed do D.sleep(0.1) end
  if self.closed then return nil,"CLOSED" end
  rounds[#rounds+1]=self.result
 end
 return rounds
end
function Arena.summarize(rounds)
 local result={wins=0,health=0,seconds=0,hits=0,fallback=0,modelActions=0,baselineActions=0,actions={}}
 for _,round in ipairs(rounds) do
  if round.won then result.wins=result.wins+1 end
  result.health=result.health+round.studentHP; result.seconds=result.seconds+round.seconds
  for _,key in ipairs({"hits","fallback","modelActions","baselineActions"}) do result[key]=result[key]+(round.metrics[key] or 0) end
  for action,count in pairs(round.metrics.actions or {}) do result.actions[action]=(result.actions[action] or 0)+count end
 end
 result.health=result.health/#rounds; result.seconds=result.seconds/#rounds
 return result
end
function Arena:evaluateAdoptedAsync()
 if self.evaluating or (self.mode~="demo" and self.mode~="review") then return nil,"EVALUATION_RUNNING" end
 if not self.adopted then return nil,"NO_ADOPTED_MODEL" end
 self.recorder:stop(); self.mode="review"; self.evaluating=true
 local basic,err=self:runComparisonAsync(nil,"基础射击 AI",true)
 if not basic then self.evaluating=false; return nil,err end
 local rounds; rounds,err=self:runComparisonAsync(self.adopted,"已采用成果",false)
 if not rounds then self.evaluating=false; return nil,err end
 self.evaluation={model=self.adopted,adoptedReplay=true,candidate=rounds,baseline=basic,summary={candidate=Arena.summarize(rounds),baseline=Arena.summarize(basic)}}
 self.evaluating=false; self.mode="review"; self.message="已采用成果复战完成；没有重新训练或改写存档。"
 return self.evaluation
end

function Arena:evaluateBaselineAsync()
 if self.evaluating or (self.mode~="demo" and self.mode~="review") then return nil,"EVALUATION_RUNNING" end
 self.recorder:stop(); self.mode="review"; self.evaluating=true
 local rounds,err=self:runComparisonAsync(nil,"基础射击 AI",true)
 self.evaluating=false
 if not rounds then return nil,err end
 self.baselineEvaluation=rounds
 local summary=Arena.summarize(rounds)
 self.message=string.format("基础 AI 三场胜利 %d/3，平均生命 %.0f，用时 %.1f 秒。原地射击，不闪避；这不是你的训练成果。",summary.wins,summary.health,summary.seconds)
 return rounds
end
function Arena:evaluateAsync()
 if self.evaluating or not self.candidate or self.mode~="review" then return nil,"NO_CANDIDATE" end
 self.evaluating=true
 local candidate=self.candidate
 local basic,err=self:runComparisonAsync(nil,"基础射击 AI",true)
 if not basic then self.evaluating=false; return nil,err end
 local rounds; rounds,err=self:runComparisonAsync(candidate,"候选",false)
 if not rounds then self.evaluating=false; return nil,err end
 local old
 if self.adopted then old,err=self:runComparisonAsync(self.adopted,"原版本",false); if not old then self.evaluating=false; return nil,err end end
 self.evaluation={model=candidate,candidate=rounds,previous=old,baseline=basic,
  summary={candidate=Arena.summarize(rounds),baseline=Arena.summarize(basic),previous=old and Arena.summarize(old) or nil}}
 self.evaluating=false
 local c,b=self.evaluation.summary.candidate,self.evaluation.summary.baseline
 self.message=string.format("候选三场胜利 %d/3，平均生命 %.0f / %.1f秒；基础 AI %d/3，%.0f / %.1f秒",c.wins,c.health,c.seconds,b.wins,b.health,b.seconds)
 if old then
  local p=self.evaluation.summary.previous
  self.message=self.message..string.format("；原版本 %d/3，%.0f / %.1f秒",p.wins,p.health,p.seconds)
 end
 self.message=self.message.."。"..require("Training.ComparisonText").verdict(c,b)
 return self.evaluation
end

function Arena:discard()
	if self.evaluating then return false end
	self.candidate = nil
	self.mode = "review"
	self.evaluation = nil
	self.message = "候选已放弃，原采用模型保留"
end

function Arena:rollback()
	if self.evaluating then return false, "EVALUATION_RUNNING" end
	if not self.previous then return false, "NO_PREVIOUS_MODEL" end
	self.adopted, self.previous = self.previous, self.adopted
	self.message = "已回滚到上一采用模型"
	return true
end

function Arena:update()
	if self.closed then return true end
	if self.mode ~= "demo" and self.mode ~= "trial" then return false end
	-- Prune spent bullets so a long round does not retain removed projectiles.
	if self.projectiles and #self.projectiles > 32 then
		local live = 0
		for _, bullet in ipairs(self.projectiles) do
			if bullet.parent then live = live + 1; self.projectiles[live] = bullet end
		end
		for i = live + 1, #self.projectiles do self.projectiles[i] = nil end
	end
	local now = D.App.runningTime
	if not self.externalCombat then self.enemyCombat:update(now) end
	if self.qSession and not self.qSession.closed then self.qSession:update(now) end
	if self.mode == "trial" and now >= self.nextDecision then
		self.nextDecision = now + 0.25
		local action,why
  if self.trialBaseline then
   if self:available("laser") then action="laser" else why="ACTION_UNAVAILABLE" end
  elseif self.resourceTrialPredict then action,why=self.resourceTrialPredict(self:snapshot(),function(a)return self:available(a)end)
  else action,why=Model.predict(self.trialModel,self:snapshot(),function(a) return self:available(a) end) end
		self.lastDecision = action or why
		if action then
			self:request(action, self.trialBaseline and "baseline" or "model")
		elseif why == "ACTION_UNAVAILABLE" then
			self.metrics.unavailable = self.metrics.unavailable + 1
   -- A rejected next decision cannot renew the preceding locomotion.
   -- Stop only walking; authored attacks and displacement keep their lifetime.
   if self.student:isDoing(self.physical.fmove) or self.student:isDoing(self.physical.bmove) then
    self.student:stop(); self.student.velocityX = 0
   end
		else
			self.metrics.fallback = self.metrics.fallback + 1
   if self.trialModel and self.trialModel.algorithm=='qlearning' and (why=='UNSEEN_STATE' or why=='UNSEEN_ACTIONS') then
    -- Explicit baseline fallback, never exploration or an online Q update.
    if self:available('laser')then self:request('laser','baseline')
    elseif self:available('idle')then self:request('idle','baseline')end
   elseif not self:isAttacking() then self.student:stop(); self.student.velocityX = 0 end
		end
	end
	if self.student.x < self.minX or self.student.x > self.maxX then
  local x,vx=self.student.x,self.student.velocityX
		self.student.x = math.max(self.minX, math.min(self.maxX, x))
  -- A float-rounded clamp can remain just outside the boundary. Preserve
  -- inward motion so the next physics step can actually leave that boundary.
  if (x<self.minX and vx<0)or(x>self.maxX and vx>0)then self.student.velocityX=0 end
	end
	self.enemy.x = math.max(self.minX, math.min(self.maxX, self.enemy.x))
	self.world.camera.position = D.Vec2((self.student.x + self.enemy.x) / 2 + (self.cameraBias or 0), 300)
	if self.mode == "demo" and (self.enemyHP <= 0 or self.studentHP <= 0) then
		self.message = "本次对练结束，请结束示范查看成果。"
	end
	if not self.externalRound and self.mode == "trial" and ((self.enemyHP <= 0 and not self:isAttacking()) or self.studentHP <= 0 or now - self.roundStarted >= (self.roundLimit or 35)) then
		self.result = {controller=self.trialBaseline and "basic-shot" or "learned", won = self.enemyHP <= 0, studentHP = self.studentHP, enemyHP = self.enemyHP,
			seconds = now - self.roundStarted, metrics = self.metrics}
		self.mode = "review"
		self.student:stop(); self.student.velocityX = 0
		if self.enemyHP <= 0 then self.enemy.playable:play("lose") end
		if self.studentHP <= 0 then self.student.playable:play("lose") end
		self.message = (self.result.won and "试战胜利" or "试战未胜") .. "，模型动作 " .. self.metrics.modelActions .. " / 保底 " .. self.metrics.fallback
	end
	return false
end

function Arena.createAsync(options)
	options = options or {}
	local self = setmetatable({mode = "loading", nextShot = 0, closed = false,
		adopted = options.adopted, previous = options.previous, enemySpeed=options.enemySpeed, roundLimit=options.roundLimit}, Arena)
	self.character=assert(Characters[options.characterId or "ninilite"],"Unknown training character")
 self.physical={}
 for key,name in pairs(physical) do self.physical[key]=(options.actionPrefix or "")..name end
 local physical=self.physical
 self.enemyBud=options.enemyBud
 self.enemyPlayable=options.enemyPlayable
 self.enemyAsset=options.enemyAsset or "xiaotaotie"; self.enemyMaxHP=options.enemyMaxHP or 100
	self.origin=options.origin or 700; self.minX=options.minX or 350; self.maxX=options.maxX or 1500
	self.initialEnergy=options.studentEnergy; self.shotEnergyCost=options.shotEnergyCost or 12
	D.Cache:loadAsync("spine:"..self.character.id)
 if self.enemyPlayable then D.Cache:loadAsync("spine:"..self.enemyPlayable)end
 if self.character.id=="wuyun" then D.Cache:loadAsync("spine:coldweapon") end
 if not options.enemyFactory then D.Cache:loadAsync("spine:"..self.enemyAsset) end
 if self.enemyAsset=="xiaohuayao" or self.enemyAsset=="dahuayao" then D.Cache:loadAsync("spine:hualei.skel|xiaohuayao.atlas") end
 if options.world then
  assert(options.manualUpdate and options.actionPrefix,"Shared arena requires manual updates and unique actions")
  self.world=options.world
 else
  local Scene=require("Scene."..(options.scene or "LoopTowerA")); Scene:loadAsync()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  D.Entity:clear(); P.Data.store:clear(); P.Data:setRelation(1,2,"Enemy")
  self.world=Scene(); self.world:addTo(D.Director.entry); P.Data.store.world=self.world
 end
 -- Action definitions outlive their units in the global registry. Keep the
 -- arena weak here; active actions retain it only for their own lifetime.
 local arenaRef=setmetatable({self},{__mode="v"})
	local function move(name, animation, speed, action)
		P.UnitAction:add(name, {priority = 1, reaction = 0, recovery = 0.1,
			available = function(owner) return owner.onSurface end,
			create = function(owner)
    local arena=arenaRef[1]
    if arena and arena.beginMovementAction then arena.movementStep=arena.beginMovementAction(owner,action,arena.currentActionSource or 'scripted')end
				Animation.play(owner, animation, true)
				return function(unit)
					unit.velocityX = speed * (unit.faceRight and 1 or -1)
					return not unit.onSurface
				end
			end, stop = function(owner) local arena=arenaRef[1];if arena and arena.finishMovementAction then arena.finishMovementAction(arena.movementStep,owner,action);arena.movementStep=nil end; owner.velocityX = 0; if arena and not arena.closed and arena.studentHP > 0 then Animation.rest(owner) end end})
	end
	move(physical.fmove, "fmove", 240, "fmove")
	move(physical.bmove, "bmove", -120, "bmove")
	move(physical.idle, "idle", 0, "idle")
 local laserClosures=setmetatable({},{__mode='k'})
 local meleeClosures=setmetatable({},{__mode='k'})
	P.UnitAction:add(physical.laser, {priority = 3, reaction = 0, recovery = 0.15,
		available = function(owner) local arena=arenaRef[1]; return arena~=nil and not arena.closed and not owner.data.weaponDisarmed and owner.onSurface and D.App.runningTime >= arena.nextShot end,
		create = function(owner)
			local self=arenaRef[1]; if not self or self.closed then return function() return true end end
			local weaponRevision=owner.data.weaponRevision or 0
   local combatStep=self.beginCombatAction and self.beginCombatAction(owner,"learner")
   laserClosures[owner]=function(status)
    laserClosures[owner]=nil
    if self.finishCombatAction then self.finishCombatAction(combatStep,owner,"learner",status)end
   end
   self.nextShot = D.App.runningTime + 0.8
			owner.velocityX = 0
			owner.playable:slot("attack"):set(function()
				if owner.data.weaponDisarmed or (owner.data.weaponRevision or 0)~=weaponRevision or self.closed or self.enemyHP <= 0 then return end
    local shot
    if self.prepareStudentShot then shot=self.prepareStudentShot(owner,combatStep);if not shot then return end end
				if self.studentEnergy and self.studentEnergy<self.shotEnergyCost then return end
    if self.supplies then
     local ok,why=self.supplies:emit(self.character.id,'emp',1,self.character.id,combatStep)
     if not ok then self.supplyFailure=why;return end
    end
    if self.studentEnergy then
					self.studentEnergy=self.studentEnergy-self.shotEnergyCost
     if self.recordEnergySpent then self.recordEnergySpent(combatStep,self.shotEnergyCost)end
				end
				local def = P.BulletDef()
				def.lifeTime = require('Combat.FirearmRules').lifeTime; def.highSpeedFix = true; def.gravity = D.Vec2.zero
				def:setAsCircle(10); def:setVelocity(shot and -shot.angle or 0, require('Combat.FirearmRules').speed)
				def.face = P.Face(function()
					local dot = D.DrawNode(); dot:drawDot(D.Vec2.zero, 8, D.Color(0xff8dbef3)); return dot
				end)
				local redirected=self.studentEffects and self.studentEffects:redirect(owner)
    if redirected then owner.faceRight=redirected.unit.x>=owner.x end
    local bullet = P.Bullet(def, owner)
    local allow = P.TargetAllow(); allow:allow("Enemy", true); if redirected then allow:allow("Friend",true) end; allow.terrainAllowed = true
				bullet.targetAllow = allow:toValue()
				bullet:slot("HitTarget", function(projectile, target)
					if redirected and target==redirected.unit and not self.closed then
      redirected.damage(20,{kind="virus-friendly-fire"}); self.metrics.friendlyHits=(self.metrics.friendlyHits or 0)+1
					elseif self.damageOpponent then
      if self.damageOpponent(target,20,combatStep)>0 then self.metrics.hits=self.metrics.hits+1 end
     elseif target == self.enemy then
      self.enemyHP = math.max(0, self.enemyHP - 20)
      self.metrics.hits = self.metrics.hits + 1
					end
					projectile.hitStop = true
				end)
				local muzzle=redirected and require('Combat.Muzzle').actual(self.world,owner)or shot and shot.origin or require('Combat.Muzzle').actual(self.world,owner)
    bullet.position=D.Vec2(muzzle.x,muzzle.y)
				bullet:addTo(self.world)
    require('Tutorial.LightStrip').LightStrip(bullet.position,bullet,3431841523)
				if self.qSession and not self.qSession.closed then self.qProjectileUntil=math.max(self.qProjectileUntil or 0,D.App.runningTime+def.lifeTime+0.05)end
				self.projectiles[#self.projectiles + 1] = bullet
    if redirected and self.observeRedirectedProjectile then self.observeRedirectedProjectile(bullet,"learner",combatStep)end
    if self.observeProjectile and not redirected then self.observeProjectile(bullet,"learner",combatStep)end
			end)
			return D.once(function()
				local _,completed=Animation.playOnceAsync(owner, "pistol")
    if laserClosures[owner]then laserClosures[owner](completed and 'completed' or 'interrupted')end
				if not self.closed and self.studentHP > 0 then Animation.rest(owner) end
				return true
			end)
		end,stop=function(owner)
   owner.playable:slot('attack'):clear()
   if laserClosures[owner]then laserClosures[owner]('interrupted')end
  end})
	P.UnitAction:add(physical.melee,{priority=3,reaction=0,recovery=0.15,
  available=function(owner) local arena=arenaRef[1]; return arena~=nil and not arena.closed and arena.character.legal.melee and owner.onSurface and D.App.runningTime>=arena.nextShot end,
  create=function(owner)
   local self=arenaRef[1]; if not self or self.closed then return function() return true end end
   self.nextShot=D.App.runningTime+0.8; owner.velocityX=0; local fired=false
   local meleeStep=self.beginMeleeAction and self.beginMeleeAction(owner)
   meleeClosures[owner]=function(status)
    meleeClosures[owner]=nil
    if self.finishMeleeAction then self.finishMeleeAction(meleeStep,owner,status)end
   end
   owner.playable:slot("attack"):set(function()
    if fired or self.closed or self.enemyHP<=0 or (self.allowMeleeImpact and not self.allowMeleeImpact()) then return end; fired=true
    if self.supplies then
     local ok,why=self.supplies:emit(self.character.id,'blade',1,self.character.id,meleeStep)
     if not ok then self.supplyFailure=why;return end
    end
    -- Regional hosts resolve the actual 300-unit blade segment against bodies
    -- and terrain. A large Boss center cannot veto its nearer visible limbs.
    if self.meleeContact or (math.abs(owner.x-self.enemy.x)<=300 and ((self.enemy.x>=owner.x)==owner.faceRight)) then
     local dealt=self.meleeContact and self.meleeContact(owner,meleeStep) or (self.damageOpponent and self.damageOpponent(self.enemy,20,meleeStep))
     if not self.damageOpponent and not self.meleeContact then self.enemyHP=math.max(0,self.enemyHP-20); dealt=20 end
     if dealt>0 and not self.meleeContact then self.metrics.hits=self.metrics.hits+1 end
     self.meleeEventAt=D.App.runningTime
     local slash=D.DrawNode(); slash:drawSegment(D.Vec2(0,0),D.Vec2(owner.faceRight and 200 or -200,90),5,D.Color(0xffb8f1ff)); slash.position=owner.position; slash:addTo(self.world)
     slash:perform(D.Sequence(D.Opacity(0.2,1,0),D.Event("Finished"))); slash:slot("Finished",function() slash:removeFromParent() end)
    end
   end)
   return D.once(function() local _,completed=Animation.playOnceAsync(owner,"melee"); if meleeClosures[owner]then meleeClosures[owner](completed and 'completed' or 'interrupted')end; if not self.closed and self.studentHP>0 then Animation.rest(owner) end; return true end)
  end,stop=function(owner)
   owner.playable:slot('attack'):clear()
   if meleeClosures[owner]then meleeClosures[owner]('interrupted')end
  end})
 local function unit(name, group, x, unitActions, playable, look)
		local def = D.Dictionary()
		def.playable = "spine:" .. (playable or (name==self.enemyAsset and self.enemyPlayable or name)); def.bodyType = "Dynamic"; def.size = D.Size(100, 300)
		if name=="dataotie" then def.size=D.Size(420,380); def.defaultFaceRight=false end
		def.linearAcceleration = D.Vec2(0, -15); def.density = 1; def.friction = 1
		if name~="dataotie" then def.defaultFaceRight = name~="xiaohuayao" and name~="dahuayao" end;
  if name=="dahuayao" then def.size=D.Size(230,430) end; def.scale = 1 -- Match Test/SpineTest.yue authored model size.
  def.detectDistance = 1200
		local availableActions={}; for _,action in ipairs(self.character.actions) do availableActions[#availableActions+1]=physical[action] end
		def.actions = D.Array(unitActions or availableActions)
		-- Entity(table) is fire-and-forget in this runtime; retrieve the
		-- created entity from its group rather than using its nil return value.
		local groupEntities = D.Group({"training", "name"})
		local marker=D.Node()
		D.Entity({training = true, name = name, spawnMarker=marker})
		local entity = assert(groupEntities:find(function(e) return e.spawnMarker == marker end), "Training entity missing")
		local result = P.Unit(def, self.world, entity, D.Vec2(x, self.world.offset + def.size.height/2+5))
		result.group = group; result.playable.y = -def.size.height/2
  -- The default flower skin omits the dress; both authored color skins are complete.
  if name=="xiaohuayao" then
   look=look or options.flowerLook or "white"
   assert(look=="white" or look=="normal", "Unknown small flower look")
   result.playable.look=look
  elseif look then result.playable.look=look end
  local lane=group==1 and partyLayers[name]or 0
  if group==1 and partyLayers[name]~=nil then
   -- Use the scene's vertical roads only. Their old diagonal X offset would
   -- change the apparent firing distance and crowding without physical movement.
   local offset=self.world:getLayerOffset(lane)
   self.world:setLayerOffset(lane,D.Vec2(0,offset.y))
  end
  result:addTo(self.world,lane)
		Animation.configure(result, name)
		entity.unit = result
		self.world:addShadowTo(result)
		return result
	end
	self.spawnUnit = unit
	self.student = unit(self.character.id, 1, 700)
 if self.character.id=="wuyun" then local blade=D.Spine("coldweapon"); blade.look="sword"; blade.scaleX=0.2; blade.scaleY=0.2; self.student.playable:setSlot("melee",blade) end
	self.enemy = options.enemyFactory and options.enemyFactory(self.world,self.origin+400) or unit(self.enemyAsset, 2, self.origin+400)
	self.externalCombat=not not options.enemyFactory
	self.enemyCombat = not options.enemyFactory and (self.enemyAsset=="dataotie" and require("Ground.BossCombat") or (self.enemyAsset=="xiaohuayao" or self.enemyAsset=="dahuayao") and require("Factory.FlowerCombat") or EnemyCombat).new(self, options.enemySkills)
	local gun = D.Spine("empgun"); gun.look = "PT"; gun.scaleX = 0.2; gun.scaleY = 0.2
	self.student.playable:setSlot("pistol", gun)
 self.student.data.supplyActorId=self.character.id
 self.student.data.combatWeaponAsset="empgun";self.student.data.combatWeaponLook="PT"
	self.world.camera.position = D.Vec2(900, 300)
	self:beginDemo(options.distance)
	if not options.manualUpdate then self.world:schedule(function() return self:update() end) end
	self.world:slot("Cleanup", function() self.closed = true; if self.qSession then self.qSession:abort('CLOSED')end end)
	return self
end

return Arena
