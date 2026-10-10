-- Virtual encounter practice. Uses the production flower encounter and records
-- human demonstrations separately; explicit adoption lives in the review panel.
local D=require('Dora');local P={}
function P.models()
 local models={}
 for _,id in ipairs({'ninilite','wuyun'})do
  local progress=require('Training.Progress').forCharacter(id)
  local ok,why=progress.load();if not ok then return nil,why end
  if not progress.adopted then return nil,'BOTH_LEARNERS_REQUIRED'end
  models[id]=progress.adopted
 end
 return models
end
function P.teamSources()
 local sources={}
 for _,id in ipairs({'ninilite','wuyun'})do
  local source,why=require('Training.FlowerPolicyStore').evidence(id)
  if not source then return nil,why end;sources[id]=source
 end
 return sources
end
function P.createAsync(characterId,models,context,scenario,teamSources,resourceLoadout)
 assert(characterId=='ninilite' or characterId=='wuyun')
 assert(not resourceLoadout or not teamSources,'Resource team evaluation is not supported')
 context=context or {rounds={}};local self={context=context,characterId=characterId,scenario=scenario,resourceLoadout=resourceLoadout}
 local demoStore=require(resourceLoadout and 'Training.ResourceDemoStore' or 'Training.FlowerPracticeStore')
 local policy=require(resourceLoadout and 'Training.ResourcePolicy' or 'Training.FlowerPolicy')
 local candidateStore=require(resourceLoadout and 'Training.ResourcePolicyStore' or 'Training.FlowerPolicyStore')
 if teamSources then
  assert(characterId=='ninilite' and require('Training.FlowerScenarios').get(scenario),'Joint evaluation requires a registered profile')
  for _,id in ipairs({'ninilite','wuyun'})do assert(require('Training.FlowerEvidence').validate(teamSources[id],id))end
  self.teamSources=D.json.decode(D.json.encode(teamSources,false,true),32)
 end
 local trialStore=require(resourceLoadout and 'Training.ResourceC45Trials' or self.teamSources and 'Training.FlowerTeamTrials' or 'Training.FlowerTrialStore')
 function self:refreshDemonstrations()
  local history,why=demoStore.history(characterId)
  if not history then self.coverage=nil;self.coverageError=why;return end
  local data,why=policy.inspect(history,characterId)
  self.coverage=data and data.coverage;self.coverageError=why
 end
 function self:refreshReviews()
  if resourceLoadout then
   local rows,why=trialStore.history(characterId);self.resourceTrials=rows;self.lastTrial=rows and rows[1];self.lastTrialError=why;self.resourceComparison=rows and require('Training.ResourceC45Comparison').latest(self.candidate,models,rows);self.resourceBudgetReview=rows and require('Training.ResourceBudgetReview').build(self.candidate,models,rows);return
  end
  local rows,why=trialStore.history(characterId)
  if not rows then
   self.lastTrial=nil;self.lastTrialError=why;self.comparison=nil;self.review=nil;self.generalization=nil;self.teamReview=nil;self.teamReviewError=why;return
  end
  self.lastTrial=rows[1];self.lastTrialError=not rows[1] and 'NOT_RECORDED' or nil
  if self.teamSources then self.teamReview,self.teamReviewError=trialStore.review(self.teamSources,models,rows);return end
  self.comparison,self.comparisonError=require('Training.FlowerComparison').latest(characterId,self.candidate,models,rows)
  self.review,self.reviewError=require('Training.FlowerReview').latest(characterId,self.candidate,models,rows)
  self.generalization,self.generalizationError=require('Training.FlowerGeneralization').latest(characterId,self.candidate,models,rows)
 end
 local service={finishAsync=function(_,attempt,status,report,episode)
  episode.context=resourceLoadout and ((self.mode=='candidate' or self.mode=='basic') and 'flower-resource-c45-trial' or 'flower-resource-demo') or self.teamSources and 'flower-team-practice' or 'flower-practice';episode.practiceProfile=self.scenario or 'standard'
  local demonstrations=0;for _,step in ipairs(episode.steps)do if step.action.actor==characterId and step.action.origin=='demo'then demonstrations=demonstrations+1 end end
  if resourceLoadout then local data,why=policy.inspect({episode},characterId);if not data then return false,why end;demonstrations=data.coverage.total end
  local trialSaved=false
  if self.mode=='candidate' or self.mode=='basic'then
   if not self.trialRecord then
    local record={schemaVersion=1,controller=self.mode,learner=characterId,status=status,policy=self.runCandidate,resourceSource=self.runResourceSource,teamSources=self.teamSources,setup=self.runSetup,initialHP={mentor=100,ninilite=100,wuyun=100},finalHP={mentor=self.battle.mentorHP,ninilite=self.battle.arena.studentHP,wuyun=self.battle.wuyun.studentHP},seconds=D.App.totalTime-self.runStarted,episode=episode}
    local evaluation,evalWhy=require('Training.FlowerEvaluation').build(episode)
    -- An assert here would kill the caller's save thread silently; report the failure instead.
    if not evaluation then return false,evalWhy or 'EVALUATION_FAILED' end
    record.evaluation=evaluation
    self.trialRecord=record
   end
   local ok,why=trialStore.saveAsync(self.trialRecord);if not ok then return false,why end
   self.lastTrial=self.trialRecord;self.lastTrialError=nil;trialSaved=true
   self:refreshReviews()
  end
  if self.teamSources and demonstrations>0 then return false,'HUMAN_ACTION_IN_TEAM_TRIAL'end
  if demonstrations>0 then local ok,why=demoStore.saveAsync(characterId,status,episode);if not ok then return false,why end;self:refreshDemonstrations()end
  context.rounds[#context.rounds+1]={status=status,report=report,episode=episode,saved=demonstrations>0,trialSaved=trialSaved}
  if #context.rounds>20 then table.remove(context.rounds,1)end
  self.result=context.rounds[#context.rounds];return true
 end}
 local initialProfile=scenario and require('Training.FlowerScenarios').get(scenario)
 self.initialSupportGold=initialProfile and initialProfile.supportGold or 90
 local support=require('Ground.LifeSupport').new(self.initialSupportGold,'defence');support.hp={100,100,100}
 self.battle=require('Factory.Battle').createAsync(service,{mission='c0-m05',id='practice-'..os.time()..'-'..math.floor(D.App.totalTime*1000000),models=models},support,{training=true,virtualSupplies=resourceLoadout,trainingGoal=resourceLoadout and 'resource-clear-v1' or nil})
 self.candidate,self.candidateError=(resourceLoadout and candidateStore.loadAsync or candidateStore.load)(characterId)
 if self.teamSources then self.candidate=self.teamSources.ninilite.policy;self.candidateError=nil end
 self:refreshReviews();self:refreshDemonstrations()
 self.arena=characterId=='ninilite' and self.battle.arena or self.battle.wuyun
 if scenario then self.profile=require('Training.FlowerScenarios').apply(self.battle,self.arena,scenario)end
 if self.teamSources and not self.profile.preserveFormation then self.battle.wuyun.student.x=self.arena.student.x-120;self.battle.wuyun.student.velocityX=0 end
 function self:start(candidate)
  if self.battle.phase~='ready'then return false,'NOT_READY'end
  if self.adoptionView then return false,'REVIEW_OPEN'end
  if self.learning or self.learningQueued then return false,'LEARNING'end
  if resourceLoadout and candidate then
   local row,why=candidateStore.evidenceAsync(characterId);if not row then return false,why end
   if not require('Training.FlowerIdentity').equal(row.model,self.candidate)then return false,'RESOURCE_CANDIDATE_CHANGED'end
   self.runResourceSource=row.evidence
  end
  local mode=candidate=='basic' and 'basic' or candidate and 'candidate' or 'demo'
  if mode=='demo' and self.profile then return false,'EVALUATION_ONLY'end
  if mode=='candidate' and not self.candidate then return false,'NO_CANDIDATE'end
  if candidate then
   self.runCandidate=D.json.decode(D.json.encode(mode=='basic' and models[characterId] or self.candidate,false,true),32)
   self.runSetup={trainingGoal=self.battle.trainingGoal,hitReaction=require('Factory.Rules').hitReaction,aimPolicy=require('Factory.PartCombat').aimPolicy,bossScale=self.battle.roots[3].enemy.playable.scaleX,scenario='flower-practice-v2',mentor='auto-nearest-kinetic-v1',chant='on-confusion-v1',initialDecisionSeconds=.2,decisionSeconds=.25,supportVariant='defence',supportGold=self.initialSupportGold,models=D.json.decode(D.json.encode(models,false,true),32)}
   if self.profile then self.runSetup.scenario='flower-practice-v3';self.runSetup.profile=require('Training.FlowerScenarios').get(self.scenario)end
   if self.teamSources then self.runSetup.teamVersion=1;self.runSetup.teamFormation='ni-left-wu120-v1';self.runSetup.teamPolicies={ninilite=self.teamSources.ninilite.policy,wuyun=self.teamSources.wuyun.policy}end
   self.runStarted=D.App.totalTime
  end
  if not self.battle:start()then return false end
  self.mode=mode;self.nextDecision=D.App.totalTime+.2
  self.arena.mode=mode=='basic' and 'trial' or 'demo'
  if self.teamSources then for _,a in ipairs(self.battle.learners)do a.mode=mode=='basic' and 'trial' or 'demo'end end
  return true
 end
 function self:request(action)
  if self.mode=='candidate' or self.mode=='basic'then return false,'CANDIDATE_RUNNING'end
  if self.battle.phase~='playing' then return false,'NOT_PLAYING'end
  return self.arena:request(action,'demo')
 end
 function self:stopMove()
  local unit=self.arena.student;local actions=self.arena.physical
  -- Neutral joystick events end walking, not a deliberate waiting demonstration.
  if self.mode~='candidate' and self.mode~='basic' and self.battle.phase=='playing' and (unit:isDoing(actions.fmove) or unit:isDoing(actions.bmove))then unit:stop();unit.velocityX=0 end
 end
 function self:learnAsync(scope)
  if self.teamSources then return false,'EVALUATION_ONLY'end
  if scope~=nil and scope~='all' and scope~='latest' then return false,'INVALID_LEARNING_SCOPE'end
  local phase=self.battle.phase
  if self.adoptionView or self.learning or phase=='playing' or phase=='saving' or phase=='save-error' or self.arena.closed then return false,'NOT_AVAILABLE'end
  self.learningQueued=false;self.learning=true;self.learningError=nil;self:refreshDemonstrations()
  local ok,model,why=xpcall(function()
   local history,err=demoStore.history(characterId);if not history then return nil,err end
   -- Practice history is chronological, unlike newest-first trial history.
   if scope=='latest' then history=history[#history] and {history[#history]} or {}end
   local candidate,err=policy.buildAsync(history,characterId);if not candidate then return nil,err end
   local saved,err,persisted=candidateStore.saveAsync(candidate,history);if not saved then return nil,err end
   return persisted
  end,debug.traceback)
  self.learning=false
  if not ok then self.learningError='BUILD_FAILED';self.learningDiagnostic=model;return false,self.learningError end
  if not model then self.learningError=why;return false,why end
  self.candidate=model;self.candidateError=nil
  self:refreshReviews();return true
 end
 function self:finish()
  if self.battle.phase=='playing' or self.battle.phase=='ready'then self.battle:finish('aborted','花妖对练已结束，正式任务和采用模型未改动。')end
 end
 local auto=D.Node();auto:addTo(self.arena.world)
 auto:schedule(function()
  if self.arena.closed then return true end
  if self.battle.phase=='playing' then
   -- Mentor provides kinetic support while the selected learner is controlled
   -- by the human. These shots are labelled scripted, never demonstrations.
   self.battle:command('shoot')
   if self.mode=='candidate' or self.mode=='basic'then
    for _,state in pairs(self.battle.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then self.battle:command('song');break end end
   end
   if self.mode=='candidate' and D.App.totalTime>=self.nextDecision then
    self.nextDecision=D.App.totalTime+.25
    if self.teamSources then
     local decisions={};for _,a in ipairs(self.battle.learners)do require('Training.FlowerController').step(self.battle,a,self.runSetup.teamPolicies[a.character.id]);decisions[#decisions+1]=a.character.name..'：'..require('Training.FlowerPolicy').actionText(a.lastDecision)end
     self.teamDecision=table.concat(decisions,' · ')
    else
     local a=self.arena;require('Training.FlowerController').step(self.battle,a,self.runCandidate);self.lastDecision=a.lastDecision
    end
   end
  end
  return false
 end)
 return self
end
function P.openAsync(onReturn,characterId,context,models,trial,scenario,teamSources,resourceLoadout)
 models=models or assert(P.models())
 local self=P.createAsync(characterId,models,context,scenario,teamSources,resourceLoadout);local b=self.battle;local a=self.arena
 require('System.Music').play(a.world,'Music/训练场.mp3')
 local hud=require('UI.HUDControl')({weaponIcon='empgun'});hud.tag='flower-practice-hud';hud.weapon.visible=true;hud.topControl.visible=false;hud.message.visible=false;hud:addTo(D.Director.ui3D);D.emit('HUD.DisplayMove',true)
 local held={keyLeft=false,keyRight=false}
 local function clear()held.keyLeft=false;held.keyRight=false;self:stopMove();if self.aim then self.aim:cancel()end end
 local inputAvailable=require('UI.InputAvailability').bind(hud,clear);a.demoInputAvailable=inputAvailable
 hud.move.onMove=function(key,down)held[key]=down and inputAvailable();if not held.keyLeft and not held.keyRight then self:stopMove()end end
 self.aim=require('Combat.Aim').new(a.student,function()
  return inputAvailable() and b.phase=='playing' and self.mode~='candidate' and self.mode~='basic' and not self.profile and a:available('laser')
 end,function()return self:request('laser')end,a.physical.laser)
 b.partCombat.manualAim[characterId]=self.aim
 hud:gslot('Skill.Began',function()self.aim:begin()end)
 hud:gslot('Skill.Ended',function(cancelled)if cancelled then self.aim:cancel()else self.aim:release()end end)
 hud:slot('Cleanup',function()self.aim:cancel()end)
 local function skill(text,offset,fn)
  local button=require('UI.Skill')({text=text,visible=true});button.position=hud.weapon.position-D.Vec2(offset,0);button:addTo(hud.skillArea);button:slot('TapBegan',function()if inputAvailable()then fn()end end);return button
 end
 self.wait=skill('等待 K',296,function()self:request('idle')end)
 if a.character.legal.melee then self.melee=skill('刀击 E',592,function()self:request('melee')end)end
 self.song=skill('歌谣 R',a.character.legal.melee and 888 or 592,function()if self.mode~='candidate' and self.mode~='basic'then b:command('song')end end)
 local ui=D.Node();ui.tag='flower-practice-controls';ui.practice=self;ui:addTo(D.Director.ui3D)
 local label=D.Label('SourceHanSansCN-Regular',21);label.anchor=D.Vec2(0,1);label.alignment='Left';label:addTo(ui);self.label=label
 local bg=D.DrawNode();bg.order=-1;bg:addTo(ui)
 local parts={['flower-head']='头部',['flower-core']='躯干',['petal-left']='左花瓣',['petal-right']='右花瓣',roots='根部'}
 local partView=require('Combat.StatusView').new(b.partCombat.target.damage,'花妖部位护甲',parts);partView.node.anchor=D.Vec2.zero;partView.node:addTo(ui);b.partCombat.view=partView
 local function button(text,fn)
  local node=require('UI.InputButton')({text=text,textBG=''});node.scaleX=.5;node.scaleY=.5;node:slot('Tapped'):clear();node:slot('Tapped',fn);node:addTo(ui);return node
 end
 self.startButton=button('开始对练',function()self:start()end)
 self.finishButton=button('结束对练',function()self:finish()end)
 local leaving=false
 self.backButton=button('返回基础训练',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued then return end;leaving=true;self:finish()
  D.thread(function()while b.phase=='saving'do D.sleep(.02)end;if b.phase=='save-error'then leaving=false;return end;require('Training.Level')(onReturn,self.context.returnCharacter or characterId)end)
 end)
 self.restartButton=button('再来一轮',function()
  if b.phase=='playing' or b.phase=='saving' or b.phase=='save-error' or leaving or self.learning or self.learningQueued then return end
  leaving=true;D.thread(function()P.openAsync(onReturn,characterId,self.context,models,nil,scenario,self.teamSources,resourceLoadout)end)
 end)
 self.resourceButton=button('资源示范配置',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued or self.resourceConfig or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  clear();hud.visible=false;ui.visible=false;self.resourceConfigOpening=true
  local config=require('UI.SupplyLoadout')({virtual=true,virtualMode='demo',values=require('Economy.Loadout').defaults(),formation={mentor=true,learner='ninilite',wuyun=true},closed=function(confirmed,result)
   self.resourceConfig=nil;self.resourceConfigOpening=false
   if not confirmed then ui.visible=true;return end
   leaving=true;self.qOpening=true
   D.thread(function()self.resourcePractice=P.openAsync(onReturn,characterId,{rounds={}},models,nil,nil,nil,result.loadout)end)
  end});self.resourceConfig=config;config:addTo(D.Director.ui3D);config:alignLayout()
 end)
 self.retryButton=button('重试保存',function()if b.phase=='save-error'then b:saveResult()end end)
 self.learnButton=button('学习全部示范',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued then return end
  if b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  self.learningQueued=true;self.learningError=nil
  D.thread(function()self:learnAsync();self.learningQueued=false end)
 end)
 self.learnLatestButton=button('仅学最近一轮',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued then return end
  if b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  self.learningQueued=true;self.learningError=nil
  D.thread(function()self:learnAsync('latest');self.learningQueued=false end)
 end)
 self.trialButton=button('候选试战',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued or not self.candidate or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  if b.phase=='ready'then self:start(true)
  else leaving=true;D.thread(function()P.openAsync(onReturn,characterId,self.context,models,true,scenario,self.teamSources,resourceLoadout)end)end
 end)
 self.basicButton=button('基础试战',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  if b.phase=='ready'then self:start('basic')
  else leaving=true;D.thread(function()P.openAsync(onReturn,characterId,self.context,models,'basic',scenario,self.teamSources,resourceLoadout)end)end
 end)
 self.scenarioButton=button('切换评价场景',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  local nextScenario=({standard='near',near='far',far='reproduction',reproduction='field'})[scenario or 'standard']
  if resourceLoadout and scenario=='field'then nextScenario='exposed'end
  if self.teamSources and not nextScenario then nextScenario='near'end
  leaving=true;D.thread(function()P.openAsync(onReturn,characterId,self.context,models,nil,nextScenario,self.teamSources,resourceLoadout)end)
 end)
 self.teamButton=button('双人联合试战',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  if self.teamSources then return end
  local sources,why=P.teamSources();if not sources then self.teamError='请先分别完成两名学员的花妖示范与建模。';return end
  leaving=true;D.thread(function()P.openAsync(onReturn,'ninilite',{rounds={},returnCharacter=characterId},models,nil,'field',sources)end)
 end)
 self.teamReviewButton=button('联合成果审查',function()
  if leaving or self.adoptionView or not self.teamSources or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  clear();hud.visible=false;ui.visible=false
  self.adoptionView=require('Training.FlowerTeamReviewPanel').open(self.teamSources,models,function()
   self.adoptionView=nil;ui.visible=true;self:refreshReviews()
  end)
 end)
 self.qButton=button('花妖自主训练',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  leaving=true;self.qOpening=true;clear();hud.visible=false;ui.visible=false
  local returnCharacter=self.context.returnCharacter or characterId
  D.thread(function()self.qView=require('Training.FlowerQPanel').openAsync(function()P.openAsync(onReturn,returnCharacter)end,models)end)
 end)
 self.adoptionButton=button('成果审查',function()
  if leaving or self.adoptionView or self.learning or self.learningQueued or b.phase=='playing' or b.phase=='saving' or b.phase=='save-error'then return end
  clear();hud.visible=false;ui.visible=false
  self.adoptionView=require('Training.FlowerAdoptionPanel').open(characterId,models,function()
   self.adoptionView=nil;ui.visible=true;self:refreshReviews()
  end)
 end)
 ui:slot('Cleanup',function()if self.adoptionView then self.adoptionView.closed=true;self.adoptionView.node:removeFromParent();self.adoptionView=nil end end)
 local panelHeight,buttonLayout
 local buttons={self.resourceButton,self.startButton,self.finishButton,self.retryButton,self.restartButton,self.learnButton,self.learnLatestButton,self.trialButton,self.basicButton,self.scenarioButton,self.teamButton,self.teamReviewButton,self.qButton,self.adoptionButton,self.backButton}
 local counted,demos=0,0
 local function layout()
  panelHeight=nil;buttonLayout=nil
  local size=D.App.bufferSize;ui.size=size;partView.node.position=D.Vec2(size.width/2,size.height-240);label.position=D.Vec2(25,size.height-20);label.textWidth=size.width-340
  self.retryButton.position=D.Vec2(size.width-155,size.height-123)
 end
 layout();ui:gslot('AppChange',function(name)if name=='Size'then layout()end end)
 ui:schedule(function()
  if a.closed then return true end
  -- Hidden nodes still tick: never restore the practice HUD behind Q screens.
  if self.resourceConfigOpening or self.qOpening or self.qView then hud.visible=false;clear();return false end
  if self.adoptionView then hud.visible=false;return false end
  if not inputAvailable()then clear()end
  if b.phase=='playing' and self.mode~='candidate' and self.mode~='basic' and inputAvailable()then
   if held.keyLeft~=held.keyRight then local toward=held.keyRight==(a.enemy.x>=a.student.x);self:request(toward and 'fmove' or 'bmove')end
   if D.Keyboard:isKeyDown('K')then self:request('idle')end
   if a.character.legal.melee and D.Keyboard:isKeyDown('E')then self:request('melee')end
   if D.Keyboard:isKeyDown('R')then b:command('song')end
  end
  local steps=b.partCombat.journal.steps
  for i=counted+1,#steps do local action=steps[i].action;if action.actor==characterId and action.origin=='demo'then demos=demos+1 end end;counted=#steps
  local candidate=self.mode=='candidate' or self.mode=='basic';hud.visible=not candidate and not self.profile
  local text=(self.teamSources and '双学员联合试战' or a.character.name)..' · '..(self.profile and self.profile.name..'（仅评价）' or '花妖虚拟对练')..' · '..(b.phase=='ready' and '准备' or b.phase=='playing' and (self.mode=='candidate' and '候选试战' or self.mode=='basic' and '基础试战' or '亲自示范') or '本轮结束')
   ..'\n'..(candidate and ('当前决策：'..(self.teamDecision or require('Training.FlowerPolicy').actionText(self.lastDecision))) or self.profile and '评价由模型操作；请选择基础或候选试战。' or '按住射击扫动瞄准，松开发射；轻点直射。')
   ..string.format('\n生命 %.0f · 花妖 %.0f · 已记录示范 %d',a.studentHP,b.roots[3].enemyHP,demos)
   ..'\n'..((candidate or self.profile) and '模型自主行动，导师与歌谣自动支援；结束对练可查看记录。' or '摇杆移动，J射击，K等待，R歌谣。导师自动火力支援。')
   ..'\n'..(b.phase=='save-error' and '保存未成功，请重试后再返回。' or self.result and (self.result.trialSaved and '试战记录已保存，可与相同配置回合对照。' or self.result.saved and (resourceLoadout and '资源示范已独立保存，正式成果未改变。' or '本轮示范已保存，可学习生成独立候选。') or '本轮没有新增示范。') or candidate and '试战行动单独标记，候选仍未采用。' or self.profile and '这是评价场景，试战记录独立保存。' or '结束时保存示范；候选不会自动采用。')
  if self.result then text=text..'\n'..self.result.report.reason..'\n'..require('Factory.Outcome').text(self.result.report.outcome) end
  if resourceLoadout then text=text..'\n资源对练目标：全队存活并清场；剧情条件单独记录。'end
  if resourceLoadout then local stock=b.supplies:observation(characterId);text=text..string.format('\n资源人工示范 · 预算%d / 已耗%d / 剩余%d；正式物资不变。',stock.reserved,stock.spent,stock.budgetLeft)end
  local errors={SPATIAL_DEMONSTRATIONS_REQUIRED='旧示范已保留；新版距离学习需要至少6个新示范，请补充不同站位与动作。',TOO_FEW_SAMPLES='至少需要6个完整示范动作。',ACTION_VARIETY_REQUIRED='请示范至少两种动作。',WRITE_FAILED='候选保存失败，可重试；原候选保留。',SAMPLE_LIMIT='示范超过本次学习上限。',EVIDENCE_TOO_LARGE='示范记录过大，原候选保留。',MISSING_SOURCE_EPISODE='示范来源不完整，原候选保留。',REBUILD_MISMATCH='示范重建结果不一致，原候选保留。'}
  text=text..'\n'..((self.learning or self.learningQueued) and '正在学习示范…' or self.learningError and (errors[self.learningError] or '学习失败：'..self.learningError) or self.teamSources and '联合候选：两人的独立成果；示范拟合率不代表联合胜率。' or self.candidate and string.format('候选：%d个示范 / %d轮来源 · 拟合率%.0f%%（不代表战斗胜率）',self.candidate.sampleCount,#self.candidate.sourceEpisodes,self.candidate.trainingAccuracy*100) or (self.candidateError and self.candidateError~='NOT_RECORDED') and '候选读取失败：'..self.candidateError or (resourceLoadout and '尝试示范不同弹药余量下的移动、射击和等待。' or '尚无花妖候选。'))
  if resourceLoadout and self.candidate then text=text..'\n资源候选独立保存，尚未采用；请继续补充攻击与弹药变化下的示范。'end
  if self.teamSources then
   text=text..'\n妮妮莉特：'..self.teamSources.ninilite.policy.sampleCount..'样本；乌云：'..self.teamSources.wuyun.policy.sampleCount..'样本。两份来源均独立保存。'
   text=text..'\n两人同时运行候选，基础对照使用两人的基础成果；本页不采用成果。'
   if self.teamReview then text=text..'\n'..require('Training.FlowerTeamTrials').text(self.teamReview,scenario)end
  elseif self.candidate then text=text..'\n'..require('Training.FlowerPolicy').learnedActionsText(self.candidate)end
  if self.teamError then text=text..'\n'..self.teamError end
  text=text..'\n'..(self.teamSources and '联合试战不收集人工示范，不改变单人成果。' or self.coverageError and '示范读取失败：'..self.coverageError or require('Training.FlowerPolicy').coverageText(self.coverage))
  if b.phase~='playing'then
  if resourceLoadout then text=text..'\n'..require('Training.ResourceBudgetReview').text(self.resourceBudgetReview)end
  if self.lastTrial then
   if resourceLoadout then text=text..string.format('\n上场试战模拟成本%d / 预算%d；中止记录不计为通关结果。',self.lastTrial.episode.resources.spent,self.lastTrial.episode.resources.quote.total)end
   local last=self.lastTrial;local stats=last.evaluation.actors[characterId]
   if self.teamSources then local other=last.evaluation.actors.wuyun;stats={actions=stats.actions+other.actions,armor=stats.armor+other.armor,damageTaken=stats.damageTaken+other.damageTaken}end
   text=text..string.format('\n上次%s试战：%s · 行动%d · 削甲%.0f · 承伤%.0f',last.controller=='basic' and '基础' or '候选',({won='胜利',failed='失败',aborted='主动结束'})[last.status],stats.actions,stats.armor,stats.damageTaken)
  elseif self.lastTrialError and self.lastTrialError~='NOT_RECORDED'then text=text..'\n试战记录读取失败：'..self.lastTrialError end
  if self.comparison then text=text..'\n'..require('Training.FlowerComparison').text(self.comparison)end
  if self.review then text=text..'\n'..require('Training.FlowerReview').text(self.review)end
  if self.generalization then text=text..'\n'..require('Training.FlowerGeneralization').text(self.generalization)end
  if self.result then text=text..'\n'..require('Training.FlowerEvaluation').text(self.result.report.evaluation)end
  end
  if label.text~=text then label.text=text end
  local controlsAvailable=not self.learning and not self.learningQueued and b.phase~='playing' and b.phase~='saving' and b.phase~='save-error'
  self.resourceButton.visible=controlsAvailable and not self.teamSources
  self.learnButton.visible=controlsAvailable and not self.teamSources
  self.learnLatestButton.visible=self.learnButton.visible and self.coverage~=nil and self.coverage.total>0
  self.adoptionButton.visible=self.learnButton.visible and not resourceLoadout
  self.qButton.visible=controlsAvailable and not self.teamSources
  self.teamReviewButton.visible=controlsAvailable and self.teamSources~=nil
  self.teamButton.visible=controlsAvailable and not self.teamSources and not resourceLoadout
  self.scenarioButton.visible=controlsAvailable and (not resourceLoadout or self.candidate~=nil)
  self.basicButton.visible=controlsAvailable and (not resourceLoadout or self.candidate~=nil)
  self.trialButton.visible=controlsAvailable and self.candidate~=nil
  self.retryButton.visible=b.phase=='save-error'
  self.startButton.visible=b.phase=='ready' and not self.profile;self.finishButton.visible=b.phase=='playing';self.restartButton.visible=b.phase~='playing' and b.phase~='saving' and b.phase~='ready' and b.phase~='save-error'
  local visible,key={},''
  for _,node in ipairs(buttons)do key=key..(node.visible and '1' or '0');if node.visible then visible[#visible+1]=node end end
  if buttonLayout~=key then buttonLayout=key;for i,node in ipairs(visible)do node.position=D.Vec2(ui.width-155,ui.height-65-(i-1)*54)end end
  local height=math.max(95+(#visible-1)*54,label.height+150)
  b.cameraTopInset=(height+20)*D.View.size.height/ui.height
  b.cameraBottomInset=D.View.size.height*((candidate or self.profile) and .08 or .26)
  if panelHeight~=height then panelHeight=height;partView.node.position=D.Vec2(ui.width/2,ui.height-label.height-130);bg:clear();bg:drawPolygon({D.Vec2(0,ui.height),D.Vec2(ui.width,ui.height),D.Vec2(ui.width,ui.height-height),D.Vec2(0,ui.height-height)},D.Color(0xdd101b28))end
  return false
 end)
 self.hud=hud;self.ui=ui;if trial then self:start(trial)end;return self
end
return P
