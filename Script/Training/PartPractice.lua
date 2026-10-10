-- Player-facing armor practice using the same animated parts, aim and damage
-- executor as the ground encounter. This session never auto-adopts a policy.
local D=require('Dora');local Practice={}
local parts={{'head','头部'},{'head-gem','额前宝石'},{'back-front','前背甲'},{'back-rear','后背甲'},{'front-leg','前腿'},{'rear-leg','后腿'},{'tail','尾部'}}
function Practice.createAsync(characterId)
 local a=require('Training.Arena').createAsync({characterId=characterId,scene='VRTraining',enemyAsset='dataotie',enemyPlayable='dataotie-combat',enemySpeed=0,enemyMaxHP=480,distance=550})
 local self={arena=a,attempt={id='practice-'..math.floor(D.App.runningTime*1000000)},phase='playing',managesPartCleanup=true,roundSerial=0,mentorHP=0,rescueHP=0,mentorHits=0,rescueHits=0,demonstrations={},rounds={},index=0}
 a.externalCombat=true;a.cameraBias=120
 local availableAction=a.available
 function a:available(action)if action=='melee'then return false end;return availableAction(self,action)end
 local function reset()
  if self.partCombat then
   self.partCombat:close('PRACTICE_RESET');self.rounds[#self.rounds+1]=self.partCombat.journal:snapshot()
   if #self.rounds>20 then table.remove(self.rounds,1)end
  end
  self.roundSerial=self.roundSerial+1
  self.partCombat=require('Ground.PartCombat').new(self)
  self.partCombat.view=require('Combat.StatusView').new(self.partCombat.target.damage,'部位护甲靶',{head='头部',['head-gem']='额前宝石',['back-front']='前背甲',['back-rear']='后背甲',['front-leg']='前腿',['rear-leg']='后腿',tail='尾部'})
  if self.hudRoot then self.partCombat.view.node:addTo(self.hudRoot);self:layout()end
  self.index=0;self.selectedName='尚未选择';self.message=nil
 end
 a.resetEncounter=reset
 a.onPartAction=function(step,source)
  if source~='learner' or a.currentActionSource~='demo' or #self.demonstrations>=1500 then return end
  if self.learning or self.replaying then return end
  self.candidate=nil;self.evaluation=nil
  self.demonstrations[#self.demonstrations+1]={state=a.targetSnapshot(),action='laser',intendedPart=step.action.intendedPart,stepId=step.id,round=self.roundSerial,step=step}
 end
 function self:learnAsync()
  if self.saving or self.evaluating or self.learning or self.replaying or self.phase~='playing'then return nil,'BUSY'end
  if a:isAttacking() or #self.partCombat.shots>0 then return nil,'SHOT_PENDING'end
  self.learning=true;a.mode='review';a.student:stop();a.student.velocityX=0
  local ok,candidate,why=pcall(require('Training.TargetPolicy').buildAsync,a.character.id,a.enemyAsset,self.demonstrations)
  self.learning=false
  if self.phase~='playing' or a.closed then return nil,'CLOSED'end
  a.mode='demo'
  if not ok then return nil,candidate end
  self.candidate=candidate
  return candidate,why
 end
 function self:tryCandidate(comparison,policy)
  if self.saving or (self.evaluating and not comparison) or self.learning or self.replaying or self.phase~='playing' or not self.candidate then return false,'NO_TARGET_CANDIDATE'end
  if not a:available('laser')then return false,'ACTION_UNAVAILABLE'end
  -- Match Arena.request's explicit facing prerequisite before predicting.
  a.student.faceRight=a.enemy.x>=a.student.x
  local observed=a.targetSnapshot()
  local part,why,fallback=require('Training.TargetPolicy').resolve(policy or self.candidate,observed,function(id)return require('Training.PartFeatures').reachable(observed,id)end,a.character.id,a.enemyAsset)
  if not part and not fallback then return false,why end
  if not a.selectPart(part)then return false,'PART_UNREACHABLE'end
  if fallback then self.partCombat.targetFallback=why end
  for i,p in ipairs(parts)do if p[1]==part then self.index=i;self.selectedName=p[2]end end
  -- Action create callbacks run synchronously. Exclude the candidate's own
  -- decisions from human demonstrations to avoid self-labelled feedback.
  self.replaying=true;local accepted,reason=a:request('laser','target-model');self.replaying=false
  return accepted,reason
 end
 function self:evaluateAsync()
  if self.phase~='playing' or a.closed or self.saving or self.learning or self.evaluating or not self.candidate or a:isAttacking() or #self.partCombat.shots>0 then return nil,'NOT_READY'end
  self.evaluating=true;local candidate=self.candidate;local groups={}
  local ok,why=xpcall(function()
   local kinds={'baseline','candidate'};if self.adopted then kinds[#kinds+1]='adopted'end
   for _,kind in ipairs(kinds)do
    local rounds={};groups[kind]=rounds
    for index,distance in ipairs({420,620,780})do
     if self.phase~='playing' or a.closed then error('CLOSED')end
     a:beginDemo(distance)
     D.sleep(.1) -- Allow contact flags to refresh after teleporting.
     local settleDeadline=D.App.runningTime+5
     while not a.student.onSurface or not a.enemy.onSurface do
      if self.phase~='playing' or a.closed or D.App.runningTime>settleDeadline then error('SETTLE_TIMEOUT')end
      D.sleep(.02)
     end
     local round={distance=distance,opportunities=6,steps={},emitted=0,hits=0,armor=0,breaks=0,targeted=0,matched=0,fallback=0,unavailable=0};rounds[#rounds+1]=round
     self.message=(kind=='baseline' and '普通射击' or kind=='adopted' and '已采用部位规则' or '部位候选')..' · 第'..index..'/3场对照'
     for shot=1,6 do
      local deadline=D.App.runningTime+5
      while not a:available('laser')do if self.phase~='playing' or a.closed or D.App.runningTime>deadline then error('SHOT_TIMEOUT')end;D.sleep(.02)end
      a.student.faceRight=a.enemy.x>=a.student.x
      local accepted
      if kind~='baseline'then accepted=self:tryCandidate(true,kind=='adopted' and self.adopted or candidate)
      else a.selectPart(nil);accepted=a:request('laser','baseline')end
      if accepted then
       while a:isAttacking() or #self.partCombat.shots>0 do if self.phase~='playing' or a.closed or D.App.runningTime>deadline then error('SHOT_TIMEOUT')end;D.sleep(.02)end
       local step=self.partCombat.journal.steps[#self.partCombat.journal.steps]
       round.steps[#round.steps+1]=step
       local emitted=step.action.emitted or 0;round.emitted=round.emitted+emitted
       if step.action.targetFallback then round.fallback=round.fallback+emitted end
       local targeted=step.action.intendedPart~='unknown';if targeted then round.targeted=round.targeted+emitted end
       for _,hit in ipairs(step.hits)do round.hits=round.hits+1;round.armor=round.armor+hit.armorDamage;if hit.armorBroken then round.breaks=round.breaks+1 end;if targeted and hit.part==step.action.intendedPart then round.matched=round.matched+1 end end
      else round.unavailable=round.unavailable+1;D.sleep(.8)end
     end
    end
   end
  end,debug.traceback)
  self.evaluating=false
  if not ok then self.evaluation=nil;return nil,why end
  self.evaluation={model=candidate,groups=groups};self.message='三场对照完成；请比较削甲和部位命中，再决定是否采用。'
  return self.evaluation
 end
 function self:trainPartQAsync(seed)
  if self.phase~='playing' or a.closed or self.saving or self.learning or self.evaluating or a:isAttacking() or #self.partCombat.shots>0 then return nil,'NOT_READY'end
  self.evaluating=true;self.partQTraining=true;self.cancelQ=false
  seed=seed or (os.time()%2147483646+1);local randomState=seed
  local function random()randomState=(randomState*16807)%2147483647;return (randomState-1)/2147483646 end
  local report,why,partial=require('Training.PartQSession').runAsync(self,{seed=seed,random=random,initialModel=self.adopted and self.adopted.q})
  self.evaluating=false;self.partQTraining=false
  self.qPracticeReport=report or partial
  if report then
   self.candidate={schemaVersion=1,purpose='part-target',partSetVersion=1,weapon='emp',enemyAsset='dataotie',characterId=a.character.id,roundCount=3,
    traceId='part-q-'..os.time()..'-'..math.floor(D.App.runningTime*1000000),q=report.model}
   self.candidateQReport=report;self.evaluation=nil
  end
  if self.phase=='playing' and not a.closed then
   if not report then a:beginDemo(550)end
   self.message=report and ('自主部位练习完成：'..report.updates..' 次更新；尚未采用，原规则保留。') or '自主部位练习已停止，原规则保留。'
  end
  return report,why
 end
 function self:adoptAsync()
  if self.phase~='playing' or a.closed or self.saving or self.evaluating or self.learning or not self.candidate or not self.evaluation or self.evaluation.model~=self.candidate then return false,'EVALUATION_REQUIRED'end
  if not self.store then return false,'NO_GAME_DATABASE'end
  local candidate,old=self.candidate,self.adopted
  local trace,why=require('Training.TargetTrace').create(candidate,self.demonstrations,self.evaluation,self.candidateQReport);if not trace then return false,why end
  self.saving=true
  local ok;ok,why=self.store:saveAsync(candidate,old,trace);self.saving=false
  if ok then self.savedTrace=trace;self.previous=old;self.adopted=candidate;self.candidate=nil;self.evaluation=nil end
  return ok,why
 end
 function self:rollbackAsync()
  if self.phase~='playing' or a.closed or self.saving or self.evaluating or self.learning or not self.previous or not self.store then return false,'NO_PREVIOUS_POLICY'end
  local previous,adopted=self.previous,self.adopted;self.saving=true
  local ok,why=self.store:saveAsync(previous,adopted);self.saving=false
  if ok then self.adopted,self.previous=previous,adopted;self.evaluation=nil;self.savedTrace,self.traceError=self.store:loadTrace(previous) end
  return ok,why
 end
 function self:nextPart()
  if self.saving or self.evaluating or self.learning or a:isAttacking()then return false,'ACTION_BUSY'end
  for offset=1,#parts do
   local index=(self.index+offset-1)%#parts+1;local part=parts[index]
   if a.selectPart(part[1])then self.index=index;self.selectedName=part[2];return true end
  end
  return false,'NO_VISIBLE_PART'
 end
 function self:reset()
  if self.saving or self.evaluating or self.learning then return false end
  a:beginDemo(550)
 end
 function self:close()
  if self.phase~='playing'then return end
  self.phase='closed';a.mode='leaving';self.partCombat:close('PRACTICE_EXIT')
  self.rounds[#self.rounds+1]=self.partCombat.journal:snapshot()
 end
 function self:layout()
  if self.partCombat.view then self.partCombat.view.node.anchor=D.Vec2(0,0);self.partCombat.view.node.position=D.Vec2(self.hudRoot.width-225,self.hudRoot.height-175)end
 end
 reset();a.world:slot('Cleanup',function()self:close()end)
 return self
end
function Practice.openAsync(onReturn,characterId)
 local character=assert(require('Training.Characters')[characterId or 'ninilite'])
 if character.requiresStory then
  local story=require('Story.Service').open();local facts=story and story:summary()
  if not facts or not facts.completed[character.requiresStory]then return nil,'LEARNER_LOCKED'end
 end
 local self=Practice.createAsync(character.id);local a=self.arena
 self.store=require('Training.TargetStore').open(character.id)
 if self.store then local saved=self.store:load();if saved then self.adopted,self.previous=saved.adopted,saved.previous;self.savedTrace,self.traceError=self.store:loadTrace(self.adopted) end end
 require('System.Music').play(a.world,'Music/训练场.mp3')
 local hud=require('UI.HUDControl')({weaponIcon='empgun'});hud.tag='part-practice-hud';hud:addTo(D.Director.ui3D);hud.weapon.visible=true;hud.topControl.visible=false;hud.message.visible=false;D.emit('HUD.DisplayMove',true)
 local ui=D.Node();ui.tag='part-practice';ui.practice=self;ui:addTo(D.Director.ui3D);self.hudRoot=ui
 self.partCombat.view.node:addTo(ui)
 local status=D.Label('SourceHanSansCN-Regular',24);status.anchor=D.Vec2(0,1);status.alignment='Left';status.textWidth=900;status:addTo(ui)
 local report=D.Label('SourceHanSansCN-Regular',20);report.anchor=D.Vec2(0,1);report.alignment='Left';report.textWidth=1100;report:addTo(ui)
 local held={}
 local marker=require('Combat.Aim').createLine(a.student);marker.order=100
 local function stop()
  held.keyLeft=false;held.keyRight=false
  if not a:isAttacking()then a.student:stop();a.student.velocityX=0 end
 end
 local available=require('UI.InputAvailability').bind(hud,stop);a.demoInputAvailable=function()return not self.saving and not self.evaluating and not self.learning and available()end
 hud.move.onMove=function(key,down)
  held[key]=down and available()
  if not held.keyLeft and not held.keyRight then stop()end
 end
 hud:gslot('Skill.Began',function()if available()then a:request('laser','demo')end end)
 local buttons={}
 local function button(text,fn)
  local b=require('UI.InputButton')({text=text,textBG=''});b:slot('Tapped'):clear();b.scaleX=.5;b.scaleY=.5;b.tag=text;b:addTo(ui);b:slot('Tapped',fn);buttons[#buttons+1]=b
 end
 button('下个可达部位',function()local ok=self:nextPart();if not ok then self.message='请调整位置或朝向，露出要瞄准的部位。'else self.message=nil end end)
 button('重置护甲靶',function()self:reset();stop()end)
 button('返回普通对练',function()if self.saving then return end;self:close();require('Training.Level')(onReturn,character.id)end)
 button('返回训练室',function()if self.saving then return end;self:close();D.thread(function()if onReturn then onReturn()else require('Academy.Navigation').returnToTrainingAsync()end end)end)
 button('学习部位选择',function()
  D.thread(function()
   local candidate,why=self:learnAsync()
   if candidate then self.message='已学习 '..candidate.tree.sampleCount..' 次射击选择；点击候选试射观察，尚未采用。'
   elseif why=='SHOT_PENDING'then self.message='请等本次射击结束后再学习。'
   elseif why=='INSUFFICIENT_TARGET_COVERAGE'then self.message='请完成至少6次射击，示范至少两种部位，再学习。'
   else self.message='本次学习未完成，原训练成果保留。'end
  end)
 end)
 button('候选试射',function()
  local ok,why=self:tryCandidate()
  self.message=ok and ('候选选择：'..self.selectedName..'；请观察实际命中。') or why=='NO_TARGET_CANDIDATE' and '请先完成部位示范并学习。' or '候选当前没有可执行的部位选择，请调整位置或继续示范。'
 end)

 button('三场部位对照',function()D.thread(function()local result=self:evaluateAsync();if not result then self.message='请先学习候选并等待射击结束，再开始对照。'end end)end)
 button('采用部位规则',function()D.thread(function()local ok=self:adoptAsync();self.message=ok and '部位规则已保存，原动作策略保留。' or '请先完成部位对照；若保存失败，原成果会保留。'end)end)
 button('回滚部位规则',function()D.thread(function()local ok=self:rollbackAsync();self.message=ok and '已回滚上一版部位规则。' or '当前不能回滚，原成果保留。'end)end)
 button('自主部位练习',function()D.thread(function()self:trainPartQAsync()end)end)
 button('停止自主练习',function()if self.partQTraining then self.cancelQ=true end end)
 local function layout()
  local size=D.App.bufferSize;local scale=math.min(1,size.width/1400)
  ui.scaleX=scale;ui.scaleY=scale;ui.size=D.Size(size.width/scale,size.height/scale)
  status.position=D.Vec2(30,ui.height-30);report.position=D.Vec2(30,ui.height-355)
  for i,b in ipairs(buttons)do b.position=D.Vec2(150+((i-1)%4)*275,ui.height-205-math.floor((i-1)/4)*55)end
  self:layout()
 end
 layout();ui:gslot('AppChange',function(name)if name=='Size'then layout()end end)
 ui:schedule(function()
  if a.closed then return true end
  if self.phase~='playing'then return false end
  if not available()then stop()
  elseif not self.saving and not self.evaluating and not self.learning and not a:isAttacking()then
   local left=held.keyLeft or D.Keyboard:isKeyPressed('A');local right=held.keyRight or D.Keyboard:isKeyPressed('D')
   if left~=right then
    -- In practice the joystick controls facing as well as travel, so walking
    -- around the target exposes its other side without an automatic turn-back.
    a.student.faceRight=not left
    if not a.student:isDoing(a.physical.fmove)then a.student:start(a.physical.fmove)end
   elseif a.student:isDoing(a.physical.fmove)then a.student:stop();a.student.velocityX=0 end
  end
  report.text=''
  local displayed=self.evaluation or self.savedTrace
  if displayed then
   local function sum(rounds)local n={armor=0,breaks=0,targeted=0,matched=0,emitted=0,opportunities=0,fallback=0};for _,r in ipairs(rounds)do for k in pairs(n)do n[k]=n[k]+(r[k] or 0)end end;return n end
   local b=sum(displayed.groups.baseline);local c=sum(displayed.groups.candidate)
   report.text=(self.evaluation and '' or '已采用规则的历史对照 · '..(self.savedTrace.qTraining and (self.savedTrace.qTraining.updates..' 次Q更新') or (#self.savedTrace.demonstrations..' 条示范'))..'\n')..string.format('三场合计 · 普通射击：削甲 %.0f / 破甲 %d / 发射 %d/%d\n部位候选：削甲 %.0f / 破甲 %d / 发射 %d/%d / 指定命中 %d/%d / 普通回退 %d',b.armor,b.breaks,b.emitted,b.opportunities,c.armor,c.breaks,c.emitted,c.opportunities,c.matched,c.targeted,c.fallback)
   if displayed.groups.adopted then local old=sum(displayed.groups.adopted);report.text=report.text..string.format('\n对照时旧规则：削甲 %.0f / 破甲 %d / 发射 %d/%d / 指定命中 %d/%d / 普通回退 %d',old.armor,old.breaks,old.emitted,old.opportunities,old.matched,old.targeted,old.fallback)end
  end
  if not displayed and self.adopted then report.text=self.traceError=='LEGACY_NO_TRACE' and '已采用旧版部位规则；该版本未保存示范与对照记录。' or '已采用规则的历史记录无法读取；规则保留，请重新对照后补练。'end
  marker.visible=false
  if self.partCombat.selectedPart then
   local solution=self.partCombat:aim(a.student,self.partCombat.selectedPart,true)
   if solution then
    local facing=a.student.faceRight and 1 or -1
    marker.scaleX=facing;marker.angle=solution.angle*facing;marker.visible=true
   end
  end
  local events=self.partCombat.events;local last=events[#events]
  status.text=character.name..' · 部位瞄准练习\n摇杆 / A、D 移动，J 射击；切换可达部位，绕到另一侧练习。\n选择：'..(self.selectedName or '尚未选择')..' · 命中 '..#events..' 次 · 射击记录 '..#self.demonstrations..' 条\n'..(self.message or (last and ('实际命中：'..(self.partCombat.view.partNames[last.part]or last.part)) or '命中后显示护甲；练习不会自动采用；请先对照再决定。'))
  return false
 end)
 return self
end
return Practice
