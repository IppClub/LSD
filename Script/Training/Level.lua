local D = require("Dora")
local Arena = require("Training.Arena")
local Progress = require("Training.Progress")
local InputButton = require("UI.InputButton")

local function open(onReturn,characterId)
 characterId=characterId or "ninilite"
 local character=assert(require("Training.Characters")[characterId])
 local Progress=Progress.forCharacter(characterId)
	D.thread(function()
		local errors = {INCOMPATIBLE_SAVE_READ_ONLY="记录来自其他版本，已保留原文，请用相应版本继续。",CORRUPT_TRAINING_SAVE="记录与备份均不可用，原文已保留。",READ_FAILED="读取未成功，请重试。",WRITE_FAILED="写入未成功，请重试。",NO_GAME_DATABASE="游戏存档尚未打开。",EVALUATION_REQUIRED="先观看候选的三场试战。",NO_ADOPTED_MODEL="当前学员尚无已采用成果。",NO_PREVIOUS_MODEL="还没有可回滚的上一版本。",NO_REVIEWED_CANDIDATE="先完成示范并生成候选。"}
		local function explain(code) return errors[code] or "当前记录不可用，请重试或重新示范。" end
		if character.requiresStory then
   local service=require("Story.Service").open(); local facts=service and service:summary()
   if not (facts and facts.completed[character.requiresStory]) then return nil,"LEARNER_LOCKED" end
  end
  local loaded, loadStatus = Progress.load()
		local arena = Arena.createAsync({adopted = Progress.adopted, previous = Progress.previous, scene="VRTraining",characterId=characterId})
  require('System.Music').play(arena.world,'Music/训练场.mp3')
		if loadStatus=="RECOVERED_BACKUP" then arena.message = "训练记录损坏，已恢复上一份有效备份。"
		elseif not loaded then arena.message = explain(loadStatus) end
		local hud = require("UI.HUDControl")({weaponIcon="empgun"})
		hud.tag="trainingHUD"
		hud:addTo(D.Director.ui3D)
		hud.weapon.visible = true
		hud.topControl.visible=false; hud.message.visible=false
		D.emit("HUD.DisplayMove",true)
		local ui = D.Node(); ui.tag="training-controls"
		ui.arena=arena; ui:addTo(D.Director.ui3D)
		local title = D.Label("SourceHanSansCN-Regular", 25)
		title.tag="training-status"
		title.alignment = "Left"; title.anchor = D.Vec2(0, 1); title.textWidth = 1200
		title:addTo(ui)
		local report = D.Label("SourceHanSansCN-Regular", 23)
		report.tag="training-comparison"; report.alignment="Left"; report.anchor=D.Vec2(0,1); report.textWidth=1100
		report:addTo(ui)
  local reportBackground=D.DrawNode();reportBackground.order=-1;reportBackground:addTo(ui)
		local menu = D.Menu(); menu.tag="training-menu"; menu:addTo(ui)
		local buttons = {}
  local categoryNames={'基础训练','场景对练','部位战术','缴械战术'}
  local primary={['结束示范']=true,['三场试战']=true,['采用']=true,['放弃']=true,['重新示范']=true,['回滚']=true}
  local categoryByName={}
  for _,name in ipairs({'护甲靶练习','花妖实战','英招演练'})do categoryByName[name]='场景对练'end
  for _,name in ipairs({'大英招示范','学习部位','学习最近示范','部位自主训练','新建自主训练','部位试战','自主试战','部位对照','自主对照','部位记录','部位成果'})do categoryByName[name]='部位战术'end
  for _,name in ipairs({'缴械演练','缴械示范','学习缴械','缴械试战','缴械对照','缴械成果','缴械补练','对照记录','缴械复盘'})do categoryByName[name]='缴械战术'end
  local selectedCategory='基础训练';local categoryButtons={};local layout
  ui.trainingCategory=selectedCategory
		local function button(text, callback, release)
			local b = InputButton({text = text, textBG = ""})
			-- The legacy button's absolute Scale animation resets to 1.0;
			-- these compact controls keep their explicit 0.5 scale.
			b:slot("Tapped"):clear()
			b.scaleX = 0.5; b.scaleY = 0.5
			b:slot(release and "TapBegan" or "Tapped", callback)
			if release then b:slot("TapEnded", release) end
			b.tag=text
			b:addTo(menu); buttons[#buttons + 1] = b
			return b
		end
		local function stopMove()
			if arena.mode == "demo" and not arena.qTraining and not arena:isAttacking() then arena.student:stop(); arena.student.velocityX = 0 end
		end
		local function request(action) return function() if arena.mode == "demo" then arena:request(action,"demo") end end end
		local held = {keyLeft=false,keyRight=false}
  local function clearDemoInput() held.keyLeft=false;held.keyRight=false;stopMove() end
  local inputAvailable=require("UI.InputAvailability").bind(hud,clearDemoInput)
  arena.demoInputAvailable=inputAvailable
		hud.move.onMove = function(key,down)
			held[key]=down and inputAvailable()
			if held[key] and arena.mode=="demo" and held.keyLeft~=held.keyRight then
				local toward=held.keyRight==(arena.enemy.x>=arena.student.x)
				arena:request(toward and "fmove" or "bmove","demo")
			end
			if not held.keyLeft and not held.keyRight then stopMove() end
		end
		hud:gslot("Skill.Began",request("laser"))
		local wait = require("UI.Skill")({visible=true,text="等待 K"})
		wait.tag="training-wait"
		wait.position=hud.weapon.position-D.Vec2(296,0); wait:addTo(hud.skillArea)
		wait:slot("TapBegan",request("idle"))
  if character.legal.melee then
   local blade=require("UI.Skill")({visible=true,text="刀击 E"}); blade.tag="training-melee"; blade.position=hud.weapon.position-D.Vec2(592,0); blade:addTo(hud.skillArea); blade:slot("TapBegan",request("melee"))
  end
  local switch=InputButton({text=characterId=="ninilite" and "训练乌云" or "训练妮妮莉特",textBG=""}); switch.tag="training-switch"; switch.scaleX=0.5; switch.scaleY=0.5; switch:slot("Tapped"):clear(); switch:addTo(ui)
  switch:slot("Tapped",function()
   if arena.evaluating or (arena.mode~="demo" and arena.mode~="review") then return end
   if arena.candidate or (arena.mode=="demo" and #arena.recorder.samples>0) then arena.message="先结束示范并采用或放弃本轮成果，再切换学员。"; return end
   local target=characterId=="ninilite" and "wuyun" or "ninilite"
   local profile=require("Training.Characters")[target]; local service=require("Story.Service").open(); local facts=service and service:summary()
   if profile.requiresStory and not (facts and facts.completed[profile.requiresStory]) then arena.message="先在休息室与乌云讨论地面计划，再分别训练。"; return end
   arena.mode="switching"; open(onReturn,target)
  end)
		button("结束示范",function()
			if arena.mode == "demo" then D.thread(function() arena:finishDemoAsync() end) end
		end)
		button("三场试战",function()
			if arena.mode == "review" and arena.candidate then D.thread(function() arena:evaluateAsync() end) end
		end)
		local function persistChange(change)
			if arena.mode~="review" or arena.evaluating then return end
			local oldAdopted, oldPrevious, candidate = arena.adopted,arena.previous,arena.candidate
			local ok, err = change()
			if not ok then arena.message = explain(err); return end
			arena.mode = "saving"
			D.thread(function()
				local saved, saveError = Progress.saveAsync(arena.adopted,arena.previous,arena.qTrainingReport)
				if not saved then
					arena.adopted,arena.previous,arena.candidate = oldAdopted,oldPrevious,candidate
					arena.message = "保存未成功，原训练成果保留。"..explain(saveError)
				else arena.message = "训练成果已保存，可退出后继续。" end
				if not arena.closed then arena.mode = "review" end
			end)
		end
		button("采用",function() persistChange(function() return arena:adopt() end) end)
		button("放弃",function() if arena.mode == "review" then arena:discard() end end)
		button("重新示范",function() if arena.mode == "review" and not arena.evaluating then arena:beginDemo() end end)
		button("回滚",function()
			persistChange(function() return arena:rollback() end)
		end)
		button("返回训练室",function()
			if (arena.mode=="demo" or arena.mode=="review") and not arena.evaluating then
				arena.mode = "leaving"
				D.thread(function()
					if onReturn then onReturn() else require("Academy.Navigation").returnToTrainingAsync() end
				end)
			end
		end)
  button("近处对练",function() if arena.mode=="demo" or arena.mode=="review" then arena:continueDemo(180) end end)
  button("中距对练",function() if arena.mode=="demo" or arena.mode=="review" then arena:continueDemo(460) end end)
  button("远处对练",function() if arena.mode=="demo" or arena.mode=="review" then arena:continueDemo(800) end end)
  button("基础 AI 对照",function() if not arena.evaluating and (arena.mode=="demo" or arena.mode=="review") then D.thread(function() arena:evaluateBaselineAsync() end) end end)

  button("成果复战",function()
   if not arena.evaluating and (arena.mode=="demo" or arena.mode=="review") then
    if arena.candidate or (arena.mode=="demo" and #arena.recorder.samples>0) then arena.message="先处理本轮示范成果，再复战已采用模型。"; return end
    D.thread(function() local result,err=arena:evaluateAdoptedAsync(); if not result then arena.message=explain(err) end end)
   end
  end)

  button("自主训练",function()
   if arena.qTraining or arena.evaluating then return end
   if arena.candidate or (arena.mode=='demo' and #arena.recorder.samples>0)then arena.message='先完成并处理本轮示范或候选，再开始自主训练。';return end
   D.thread(function()local candidate,why=arena:trainQAsync();if not candidate and why~='CANCELLED' and not arena.closed then arena.message='自主训练未完成，原成果保留。'end end)
  end)
  button("停止训练",function()arena:cancelQTraining()end)

  button("护甲靶练习",function()
   if arena.evaluating or (arena.mode~='demo' and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo' and #arena.recorder.samples>0)then arena.message='先处理本轮示范或候选，再进入护甲靶练习。';return end
   arena.mode='leaving';D.thread(function()require('Training.PartPractice').openAsync(onReturn,characterId)end)
  end)

  button("花妖实战",function()
   if arena.evaluating or (arena.mode~='demo' and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo' and #arena.recorder.samples>0)then arena.message='先处理本轮示范或候选，再进入花妖对练。';return end
   local models,why=require('Training.FlowerPractice').models()
   if not models then arena.message=why=='BOTH_LEARNERS_REQUIRED' and '先分别完成妮妮莉特与乌云的基础训练并采用成果。' or explain(why);return end
   arena.mode='leaving';D.thread(function()require('Training.FlowerPractice').openAsync(onReturn,characterId,nil,models)end)
  end)

  button("英招演练",function()
   if arena.evaluating or (arena.mode~='demo' and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo' and #arena.recorder.samples>0)then arena.message='先处理本轮示范或候选，再进入英招演练。';return end
   local models,why=require('Training.FlowerPractice').models()
   if not models then arena.message=why=='BOTH_LEARNERS_REQUIRED' and '先分别完成妮妮莉特与乌云的基础训练并采用成果。' or explain(why);return end
   arena.mode='leaving';D.thread(function()require('Training.YingzhaoPractice').openAsync(onReturn,characterId,models)end)
  end)

  button("大英招示范",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮示范或候选，再进入大英招示范。';return end
   local models=require('Training.FlowerPractice').models()
   if not models then arena.message='先完成两名学员的基础训练并采用成果。';return end
   clearDemoInput();arena.mode='leaving';D.thread(function()require('Training.BigYingzhaoPractice').openAsync(onReturn,characterId,models)end)
  end)
  button("部位成果",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')or arena:isAttacking()then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再审查部位成果。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='review';hud.visible=false;ui.visible=false
   D.thread(function()
    require('Training.YingzhaoAdoptionPanel').openAsync(characterId,require('Training.FlowerPractice').models(),function()
     if not arena.closed then arena.mode=previousMode;hud.visible=true;ui.visible=true end
    end)
   end)
  end)
  local function learnBoss(selection)
   if arena.evaluating or arena.qTraining or arena:isAttacking()or (arena.mode~='demo'and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再学习部位战术。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate,why=require('Training.YingzhaoPolicyStore').learnAsync(characterId,selection)
    if arena.closed then return end;arena.mode=previousMode
    if candidate then
     local source=selection=='latest'and string.format('仅使用最近完整示范 #%d，旧记录保留。',candidate.sourceId)or'使用历史完整示范。'
     arena.message=string.format('大英招候选 #%d 已保存：%d条示范，拟合率%.0f%%。%s尚未采用，需继续试战验证。',candidate.id,candidate.model.sampleCount,candidate.model.trainingAccuracy*100,source)
    else
     local message=({TOO_FEW_SAMPLES='完整示范不足6条，请继续大英招示范。',ACTION_VARIETY_REQUIRED='至少示范两种动作，再学习部位战术。',NO_VARIABLE_FEATURES='这些示范的战斗状态相同，请补充不同距离、敌人动作或护甲状态下的示范。',WRITE_FAILED='候选保存失败，旧成果保留。'})[why]or'部位学习未完成，请检查示范记录。'
     arena.message=selection=='latest'and('仅检查最近一次完整示范；未合并旧记录。'..message)or message
    end
   end)
  end
  button("学习部位",function()learnBoss('all')end)
  button("学习最近示范",function()learnBoss('latest')end)

  local function openBossQ(fresh)
   if arena.evaluating or arena.qTraining or arena:isAttacking()or (arena.mode~='demo'and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再进入自主训练。';return end
   local models=require('Training.FlowerPractice').models()
   if not models then arena.message='先完成两名学员的基础训练并采用成果。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate,why
    if not fresh then candidate,why=require('Training.YingzhaoQStore').loadLatestAsync(characterId)else why='NO_CANDIDATE'end
    if arena.closed then return end
    if not candidate and why~='NO_CANDIDATE'then arena.mode=previousMode;arena.message='旧训练成果未通过核验，已保留记录，请检查后再继续。';return end
    arena.mode='leaving';require('Training.YingzhaoQEntry').openAsync(onReturn,characterId,models,candidate)
   end)
  end
  button("部位自主训练",function()openBossQ(false)end)
  button("新建自主训练",function()openBossQ(true)end)

  button("部位试战",function()
   if arena.evaluating or arena.qTraining or arena:isAttacking()or (arena.mode~='demo'and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再进入部位试战。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate=require('Training.YingzhaoPolicyStore').loadLatestAsync(characterId)
    if arena.closed then return end
    local models=require('Training.FlowerPractice').models()
    if not candidate or not models then arena.mode=previousMode;arena.message='先完成两名学员基础训练，并学习可核对的大英招候选。';return end
    arena.mode='leaving';require('Training.YingzhaoTrialEntry').openAsync(onReturn,characterId,models,candidate)
   end)
  end)

  button("自主试战",function()
   if arena.evaluating or arena.qTraining or arena:isAttacking()or (arena.mode~='demo'and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再进入自主试战。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate=require('Training.YingzhaoQStore').loadLatestAsync(characterId)
    if arena.closed then return end
    local models=require('Training.FlowerPractice').models()
    if not candidate or not models then arena.mode=previousMode;arena.message='先完成两名学员基础训练，并完成可核对的大英招自主训练。';return end
    arena.mode='leaving';require('Training.YingzhaoTrialEntry').openAsync(onReturn,characterId,models,candidate)
   end)
  end)

  button("部位对照",function()
   if arena.evaluating or arena.qTraining or arena:isAttacking()or (arena.mode~='demo'and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再进入部位对照。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate=require('Training.YingzhaoPolicyStore').loadLatestAsync(characterId)
    if arena.closed then return end
    local models=require('Training.FlowerPractice').models()
    if not candidate or not models then arena.mode=previousMode;arena.message='先完成两名学员基础训练，并学习可核对的大英招候选。';return end
    arena.mode='leaving';require('Training.YingzhaoComparisonEntry').openAsync(onReturn,characterId,models,candidate)
   end)
  end)

  button("自主对照",function()
   if arena.evaluating or arena.qTraining or arena:isAttacking()or (arena.mode~='demo'and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再进入自主对照。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate=require('Training.YingzhaoQStore').loadLatestAsync(characterId)
    if arena.closed then return end
    local models=require('Training.FlowerPractice').models()
    if not candidate or not models then arena.mode=previousMode;arena.message='先完成两名学员基础训练，并完成可核对的大英招自主训练。';return end
    arena.mode='leaving';require('Training.YingzhaoComparisonEntry').openAsync(onReturn,characterId,models,candidate)
   end)
  end)

  button("部位记录",function()
   if arena.evaluating or arena.qTraining or arena:isAttacking()or (arena.mode~='demo'and arena.mode~='review')then return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='review';hud.visible=false;ui.visible=false
   local panel
   panel=require('Training.YingzhaoHistory').open(function()panel:removeFromParent();if not arena.closed then arena.mode=previousMode;hud.visible=true;ui.visible=true end end)
  end)

  button("缴械演练",function()
   if arena.evaluating or (arena.mode~='demo' and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo' and #arena.recorder.samples>0)then arena.message='先处理本轮示范或候选，再进入缴械演练。';return end
   local models,why=require('Training.FlowerPractice').models()
   if not models then arena.message=why=='BOTH_LEARNERS_REQUIRED' and '先分别完成妮妮莉特与乌云的基础训练并采用成果。' or explain(why);return end
   arena.mode='leaving';D.thread(function()require('Training.DisarmPractice').openAsync(onReturn,characterId,models)end)
  end)

  button("缴械示范",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo' and arena.mode~='review')then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮示范或候选，再开始缴械示范。';return end
   local models,why=require('Training.FlowerPractice').models()
   if not models then arena.message='先分别完成两名学员的基础训练并采用成果。';return end
   arena.mode='leaving';D.thread(function()require('Training.DisarmPractice').openAsync(onReturn,characterId,models,nil,characterId)end)
  end)
  button("学习缴械",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')or arena:isAttacking()then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再学习缴械。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate,why=require('Training.DisarmPolicyStore').learnAsync(characterId)
    if arena.closed then return end;arena.mode=previousMode
    if candidate then arena.message=string.format('缴械候选 #%d 已保存：%d条示范，拟合率%.0f%%；尚未对照试战或采用。',candidate.id,candidate.model.sampleCount,candidate.model.trainingAccuracy*100)
     local attack=false;for _,rule in ipairs(candidate.model.rules)do if rule.action=='laser'or rule.action=='melee'then attack=true end end;if not attack then arena.message=arena.message..'未学到攻击，请补充示范。'end
    else arena.message=({TOO_FEW_SAMPLES='完整示范不足6条，请继续缴械示范。',ACTION_VARIETY_REQUIRED='至少示范两种动作，再学习缴械。',WRITE_FAILED='候选保存失败，原候选与已采用成果保留。'})[why]or '本次缴械学习未完成，原成果保留。'end
   end)
  end)
  button("缴械试战",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')or arena:isAttacking()then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再试战缴械候选。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate,why=require('Training.DisarmPolicyStore').loadLatestAsync(characterId)
    if arena.closed then return end
    if not candidate then arena.mode=previousMode;arena.message=why=='NO_CANDIDATE'and '先亲自示范并学习缴械，再试战候选。'or '缴械候选未通过来源核对，原成果保留。';return end
    local models=require('Training.FlowerPractice').models()
    if not models then arena.mode=previousMode;arena.message='先完成两名学员的基础训练并采用。';return end
    arena.mode='leaving';require('Training.DisarmPractice').openAsync(onReturn,characterId,models,nil,nil,candidate)
   end)
  end)
  button("缴械对照",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')or arena:isAttacking()then return end
   if arena.candidate or (arena.mode=='demo'and #arena.recorder.samples>0)then arena.message='先处理本轮基础示范或候选，再运行缴械对照。';return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='building'
   D.thread(function()
    local candidate,why=require('Training.DisarmPolicyStore').loadLatestAsync(characterId)
    local models=require('Training.FlowerPractice').models()
    if arena.closed then return end
    if not candidate or not models then arena.mode=previousMode;arena.message='先完成基础训练并生成可核对的缴械候选。';return end
    arena.mode='leaving';require('Training.DisarmComparisonEntry').openAsync(onReturn,characterId,models,candidate)
   end)
  end)
  button("缴械成果",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')or arena:isAttacking()then return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='review';hud.visible=false;ui.visible=false
   D.thread(function()
    require('Training.DisarmAdoptionPanel').openAsync(characterId,require('Training.FlowerPractice').models(),function()
     if not arena.closed then arena.mode=previousMode;hud.visible=true;ui.visible=true end
    end)
   end)
  end)
  button("缴械补练",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')or arena:isAttacking()then return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='review';hud.visible=false;ui.visible=false
   local Coaching=require('Training.DisarmCoaching');local report,why=Coaching.load(characterId);local panel
   panel=require('UI.DisarmComparison')({title='缴械补练 · 亲自示范覆盖',summary=Coaching.text(report),closed=function()panel:removeFromParent();if not arena.closed then arena.mode=previousMode;hud.visible=true;ui.visible=true end end})
   panel.coaching=report;panel.tag='disarm-coaching';panel:addTo(D.Director.ui3D);panel:alignLayout()
  end)
  button("对照记录",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo'and arena.mode~='review')or arena:isAttacking()then return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='review';hud.visible=false;ui.visible=false
   local panel
   panel=require('UI.DisarmComparison')({history=true,closed=function()panel:removeFromParent();if not arena.closed then arena.mode=previousMode;hud.visible=true;ui.visible=true end end})
   panel.tag='disarm-comparison-history';panel:addTo(D.Director.ui3D);panel:alignLayout()
  end)
  button("缴械复盘",function()
   if arena.evaluating or arena.qTraining or (arena.mode~='demo' and arena.mode~='review') or arena:isAttacking()then return end
   clearDemoInput();local previousMode=arena.mode;arena.mode='review';hud.visible=false;ui.visible=false
   local panel=require('UI.DisarmReview')({closed=function()if not arena.closed then arena.mode=previousMode;hud.visible=true;ui.visible=true end end})
   panel.tag='disarm-review';panel:addTo(D.Director.ui3D);panel:alignLayout()
  end)

  for i,name in ipairs(categoryNames)do
   local tab=InputButton({text=name,textBG=''})
   tab.tag='training-category-'..name;tab.scaleX=.5;tab.scaleY=.5;tab:slot('Tapped'):clear();tab:addTo(menu)
   tab:slot('Tapped',function()
    clearDemoInput();selectedCategory=name;ui.trainingCategory=name;layout()
   end)
   categoryButtons[i]=tab
  end
  local categoryMarker=D.DrawNode();categoryMarker.order=1;categoryMarker:addTo(ui)
  layout=function()
   local size=D.App.bufferSize
   local scale=math.min(1,size.width/1400,size.height/900)
   ui.scaleX=scale;ui.scaleY=scale;ui.size=D.Size(size.width/scale,size.height/scale)
   menu.size=ui.size;menu.position=D.Vec2(ui.width/2,ui.height/2)
   switch.position=D.Vec2(ui.width-230,ui.height-60)
   title.position=D.Vec2(35,ui.height-35);title.textWidth=math.min(1200,ui.width-280)
   local primaryCount,groupCount=0,0
   for _,b in ipairs(buttons)do
    local pinned=primary[b.tag]
    local returning=b.tag=='返回训练室'
    local visible=pinned or returning or (categoryByName[b.tag]or '基础训练')==selectedCategory
    b.visible=visible;b.touchEnabled=visible
    if returning then b.position=D.Vec2(ui.width-230,ui.height-125)
    elseif pinned then
     b.position=D.Vec2(100+(primaryCount%6)*190,ui.height-235);primaryCount=primaryCount+1
    elseif visible then
     b.position=D.Vec2(100+(groupCount%6)*190,ui.height-345-math.floor(groupCount/6)*55);groupCount=groupCount+1
    end
   end
   categoryMarker:clear()
   for i,tab in ipairs(categoryButtons)do
    tab.position=D.Vec2(100+(i-1)*190,ui.height-290)
    if categoryNames[i]==selectedCategory then
     categoryMarker:drawSegment(D.Vec2(30+(i-1)*190,ui.height-310),D.Vec2(175+(i-1)*190,ui.height-310),4,D.Color(0xff7ec0f8))
    end
   end
   local reportTop=345+math.ceil(groupCount/6)*55
   report.position=D.Vec2(35,ui.height-reportTop-15)
   reportBackground:clear();reportBackground:drawPolygon({D.Vec2(20,ui.height-reportTop),D.Vec2(1160,ui.height-reportTop),D.Vec2(1160,ui.height-reportTop-125),D.Vec2(20,ui.height-reportTop-125)},D.Color(0xd9101b2a))
  end
		layout(); ui:gslot("AppChange",function(name) if name == "Size" then layout() end end)
		ui:schedule(function()
			if arena.closed then return true end
			local descriptions = {demo="亲自示范",building="正在学习",trial="模型试战",review="查看结果",saving="正在保存",leaving="返回训练室"}
			local actionNames = {melee="刀击",laser="射击",fmove="接近",bmove="后退",idle="等待",ACTION_UNAVAILABLE="等待动作就绪",NO_MATCH="没有学过该情境"}
			local counts = arena.recorder.counts
			report.visible=arena.mode=="review" and arena.evaluation~=nil
   reportBackground.visible=report.visible
			if report.visible then
				local s=arena.evaluation.summary; local c,b=s.candidate,s.baseline
				local reportText=string.format("三场对照 · 你的成果：胜利 %d/3，平均生命 %.0f，用时 %.1f 秒\n基础 AI：胜利 %d/3，平均生命 %.0f，用时 %.1f 秒\n%s",c.wins,c.health,c.seconds,b.wins,b.health,b.seconds,require("Training.ComparisonText").verdict(c,b))
    if report.text~=reportText then report.text=reportText end
			end
			local text = character.name.." · " .. (arena.qTraining and "自主训练" or descriptions[arena.mode] or arena.mode) .. "    学员 "..arena.studentHP.." / 对手 "..arena.enemyHP
				.." · 小饕餮："..(arena.enemyPhase=="attack" and require("Training.EnemyCombat").specs[arena.enemyStrike.kind].label or (arena.enemyPhase=="recover" and "收招恢复" or "待机观察"))
				.."\n摇杆 / A、D 移动示范，J 射击，K 等待。"..(character.legal.melee and "刀击 E：近距离出手。" or "").."近/中/远对练保留样本。"
				.."\n样本 "..#arena.recorder.samples.." · 拒绝 "..arena.recorder.rejected.." · "..(arena.message or "本轮未采用，旧训练成果保留")
				.."\n"..(character.legal.melee and ("刀击 "..(counts.melee or 0).." / ") or "").."射击 "..(counts.laser or 0).." / 接近 "..(counts.fmove or 0).." / 后退 "..(counts.bmove or 0).." / 等待 "..(counts.idle or 0)
				.." · 已采用成果："..(Progress.adopted and (require("Training.Summary").short(Progress.adopted).."，已保存") or "尚无")
			if arena.mode == "trial" then
				text = text .. " · "..(arena.comparison or "候选").." "..(arena.trialIndex or 1).."/3 · 当前选择："..(actionNames[arena.lastDecision] or "观察")
			end
			if title.text~=text then title.text=text end
			if not inputAvailable() then clearDemoInput() end
			if arena.mode == "demo" and not arena.qTraining and inputAvailable() then
				if character.legal.melee and D.Keyboard:isKeyDown("E") then arena:request("melee","demo") end
				if D.Keyboard:isKeyDown("K") then arena:request("idle","demo") end
				if held.keyLeft ~= held.keyRight then
					local toward = held.keyRight == (arena.enemy.x >= arena.student.x)
					local action = toward and "fmove" or "bmove"
					if arena:available(action) then arena:request(action,"demo") end
				end
			end
			return false
		end)
	end)
end

return open
