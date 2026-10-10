-- Player-facing Q draft training. Evaluation does not update the candidate.
local D=require('Dora');local P={};local ids={'near','far','reproduction','field'}
local equal=require('Training.FlowerIdentity').equal
local messages={NOT_RECORDED='尚无自主训练候选，可以开始第一轮。',WRITE_FAILED='保存失败，本轮成果仍保留，请重试。',Q_DRAFT_CHANGED='候选或来源已变化，请返回后重新读取。',Q_CHAIN_LIMIT='来源链已达上限，本轮仍保留；请勿覆盖原来源。',Q_REBUILD_MISMATCH='候选来源重建不一致，原记录保留。',BASE_MODELS_CHANGED='基础成果已变化，不能直接续接这份候选。'}
function P.openAsync(onReturn,models)
 local self={profile='near',resourceProfile='field',models=D.json.decode(D.json.encode(models,false,true),32),busy=true,closed=false,message='正在重建候选来源…'}
 local Store=require('Training.FlowerQStore')
 function self:render()
  if self.closed or not self.label then return end
  local lines={'花妖自主训练 · '..require('Training.FlowerScenarios').get(self.profile).name}
  if self.saved then lines[#lines+1]=string.format('已保存%d轮来源；妮妮莉特%d次更新，乌云%d次更新。',self.saved.depth,self.saved.models.ninilite.updates,self.saved.models.wuyun.updates)
  else lines[#lines+1]='两名学员分别学习；自主候选不会自动替换正式成果。'end
  lines[#lines+1]='探索会尝试不同动作；候选试战只推理，未覆盖状态回退基础模型。'
  if self.battle and self.running then
   lines[#lines+1]=string.format('训练进行中 · %.1f秒 · 导师%.0f / 妮妮莉特%.0f / 乌云%.0f',D.App.runningTime-self.battle.started,self.battle.mentorHP,self.battle.arena.studentHP,self.battle.wuyun.studentHP)
  elseif self.last then
   lines[#lines+1]='本轮：'..(self.last.virtualSupplies and (self.last.mode=='evaluate' and '资源候选试战'or self.last.mode=='explore' and '资源探索练习'or '资源基础练习/对照')or ({basic='基础对照',evaluate='候选试战',explore='探索训练'})[self.last.mode])..' · '..({won='胜利',failed='失败',aborted='已停止'})[self.last.status]..string.format(' · %.1f秒',self.last.report.seconds)
   if not self.last.virtualSupplies then for _,id in ipairs({'ninilite','wuyun'})do local a=self.last.decisions[id]
    lines[#lines+1]=string.format('%s：自主选择%d · 随机探索%d · 基础回退%d',id=='ninilite' and '妮妮莉特' or '乌云',a.q,a.explored,a.fallback)
   end end
  end
  if self.last and self.last.virtualSupplies then lines[#lines+1]=string.format('虚拟资源练习 · 模拟成本%d；正式物资不变。',self.last.episode.resources.spent)end
  lines[#lines+1]='资源探索优先尝试未覆盖动作，试战不探索。'
  lines[#lines+1]='资源训练目标：全队存活并清场；剧情条件单独记录。'
  if self.resourceCandidate and self.resourceCandidate.bundle.trainingGoal~='resource-clear-v1'then lines[#lines+1]='旧资源候选已保留；新目标从新模型开始探索，再学习对应来源。'end
  lines[#lines+1]='资源场景：'..require('Training.FlowerScenarios').get(self.resourceProfile).name
  if self.resourceSaved then lines[#lines+1]='最近资源练习记录 #'..self.resourceSaved.id..'（独立保存，未采用新策略）'end
  if self.resourceCandidate then lines[#lines+1]=string.format('资源Q候选 #%d：%d轮来源，更新%d / %d；尚未采用。',self.resourceCandidate.id,self.resourceCandidate.depth,self.resourceCandidate.models.ninilite.updates,self.resourceCandidate.models.wuyun.updates)end
  if self.resourceCandidate then local C=require('Training.ResourceSourceCoverage');lines[#lines+1]=C.text(C.build(self.resourceCandidate.records),self.resourceProfile)end
  if self.resourceTrialError then lines[#lines+1]='资源试战记录读取未通过，原记录保留。'end
  if self.resourceCandidate and not self.resourceTrialError then lines[#lines+1]='资源候选已有 '..#(self.resourceTrials or {})..' 场独立试战；预算不同不能直接比较。'end
  if self.resourceCandidateError and self.resourceCandidateError~='NOT_RECORDED'then lines[#lines+1]='资源Q来源重建未通过，原候选保留。'end
  if self.resourceReadError and self.resourceReadError~='NOT_RECORDED'then lines[#lines+1]='资源练习记录暂未通过读取校验；原记录保留。'end
  if self.pending then lines[#lines+1]='本轮尚未保存；请重试，或明确放弃本轮后离开。'end
  lines[#lines+1]=self.message or ''
  lines[#lines+1]=string.format('原花妖候选已保存%d场评价；“采用与回滚”仍管理原策略。',#(self.trials or {}))
  if self.reviewing then lines={'花妖评价对照 · '..require('Training.FlowerScenarios').get(self.profile).name,require('Training.FlowerQReview').text(self.review,self.profile),require('Training.FlowerQAssessment').text(self.assessment,self.profile)}end
  self.label.text=table.concat(lines,'\n')
  local ready=not self.busy and not self.pending and not self.loadError;local training=ready and not self.reviewing
  self.resourceScenario.visible=training
  self.resourceExplore.visible=training
  self.resourceButton.visible=training
  self.resourceTrainButton.visible=training and self.resourceSaved~=nil
  self.resourceReviewButton.visible=training and self.resourceCandidate~=nil
  self.resourceEvaluate.visible=training and self.resourceCandidate~=nil and self.resourceCandidate.bundle.trainingGoal=='resource-clear-v1'
  self.resourceCompare.visible=training and self.resourceCandidate~=nil and self.resourceCandidate.bundle.trainingGoal=='resource-clear-v1'
  self.explore.visible=training;self.evaluate.visible=training and self.saved~=nil;self.basic.visible=training and self.saved~=nil;self.scenario.visible=ready
  self.retry.visible=not self.busy and self.pending~=nil;self.reload.visible=not self.busy and self.loadError~=nil and not self.pending
  self.discard.visible=not self.busy and self.pending~=nil
  self.adoptionButton.visible=training or (not self.busy and not self.pending and self.loadError~=nil and not self.reviewing)
  self.reviewButton.visible=training and self.saved~=nil;self.reviewBack.visible=ready and self.reviewing==true
  self.stop.visible=self.running==true;self.back.visible=not self.busy and not self.pending and not self.reviewing
  self:layout()
 end
 function self:layout()
  local size=D.App.bufferSize;local scale=math.min(1,size.width/1200,size.height/800)
  self.node.scaleX=scale;self.node.scaleY=scale;local w,h=size.width/scale,size.height/scale;self.node.size=D.Size(w,h)
  self.label.position=D.Vec2(25,h-20);self.label.textWidth=w-320
  self.bg:clear();local panel=math.min(h,self.reviewing and math.max(650,self.label.height+40) or math.max(360,self.label.height+40))
  self.bg:drawPolygon({D.Vec2(0,h-panel),D.Vec2(w,h-panel),D.Vec2(w,h),D.Vec2(0,h)},D.Color(0xf0101b28))
  local n=0;for _,b in ipairs(self.buttons)do if b.visible then b.position=D.Vec2(w-145,h-45-n*48);n=n+1 end end
  if self.battle then self.battle.cameraTopInset=D.View.size.height*panel/h;self.battle.cameraBottomInset=D.View.size.height*.06 end
 end
 function self:mount()
  if self.node then self.node:removeFromParent()end
  local node=D.Node();node.tag='flower-q-controls';node.panel=self;node.order=100;node:addTo(D.Director.ui3D);self.node=node
  self.bg=D.DrawNode();self.bg.order=-1;self.bg:addTo(node)
  self.label=D.Label('SourceHanSansCN-Regular',23);self.label.anchor=D.Vec2(0,1);self.label.alignment='Left';self.label:addTo(node)
  self.buttons={}
  local function button(text,fn)
   local b=require('UI.InputButton')({text=text,textBG=''});b.scaleX=.5;b.scaleY=.5;b:addTo(node);b:slot('Tapped'):clear()
   b:slot('Tapped',function()if not self.closed and b.visible then fn()end end);self.buttons[#self.buttons+1]=b;return b
  end
  local function resourceBudget(mode)
   if self.busy or self.pending then return end
   self.busy=true;self.node.visible=false
   local config=require('UI.SupplyLoadout')({virtual=true,virtualMode=mode=='resource-evaluate' and 'evaluate' or mode=='resource-compare' and 'compare' or mode=='resource-explore' and 'explore' or 'practice',values=self.resourceValues or require('Economy.Loadout').defaults(),formation={mentor=true,learner='ninilite',wuyun=true},closed=function(confirmed,result)
    self.resourceConfig=nil;self.node.visible=true;self.busy=false
    if confirmed then self.resourceValues=result.values;self.resourceLoadout=result.loadout;self:start(mode)else self:render()end
   end});self.resourceConfig=config;config:addTo(D.Director.ui3D);config:alignLayout()
  end
  self.resourceButton=button('资源预算练习',function()resourceBudget('resources')end)
  self.resourceExplore=button('资源探索练习',function()resourceBudget('resource-explore')end)
  self.resourceScenario=button('切换资源场景',function()local choices=require('Training.FlowerScenarios').resourceIds;for i,id in ipairs(choices)do if id==self.resourceProfile then self.resourceProfile=choices[i%#choices+1];break end end;self:render()end)
  self.resourceEvaluate=button('资源候选试战',function()resourceBudget('resource-evaluate')end)
  self.resourceCompare=button('资源基础对照',function()resourceBudget('resource-compare')end)
  self.resourceReviewButton=button('资源收支对照',function()
   if self.busy or self.pending then return end
   self.busy=true;self:render()
   D.thread(function()
    local records,why=require('Training.ResourceQTrials').loadAsync(self.resourceCandidate.id)
    if not records then self.busy=false;self.message='资源试战记录未通过校验，原记录保留。';self:render();return end
    self.node.visible=false
    local view=require('UI.ResourceQReview')({records=records,closed=function()self.resourceReviewView=nil;self.node.visible=true;self.busy=false;self:render()end})
    self.resourceReviewView=view;view:addTo(D.Director.ui3D);view:alignLayout()
   end)
  end)
  self.resourceTrainButton=button('训练资源Q候选',function()
   if self.busy or self.pending then return end
   self.busy=true;self.message='正在按记录顺序重建资源学习…';self:render()
   D.thread(function()
    local candidate,why=require('Training.ResourceQStore').trainAsync()
    if candidate then self.resourceCandidate=candidate;self.resourceCandidateError=nil;self.message='资源Q候选已保存；重复训练相同记录不会重复更新，仍需试战评价。'
    else self.resourceCandidateError=why;self.message=why=='BASE_MODELS_CHANGED'and '练习记录的基础模型不同，不能混合训练；原记录保留。'or '资源Q训练或保存未通过，请重试；原记录保留。'end
    self.busy=false;self:render()
   end)
  end)
  self.explore=button('继续探索训练',function()self:start('explore')end)
  self.evaluate=button('候选试战',function()self:start('evaluate')end)
  self.basic=button('基础对照',function()self:start('basic')end)
  self.scenario=button('切换场景',function()for i,id in ipairs(ids)do if id==self.profile then self.profile=ids[i%#ids+1];break end end;self:render()end)
  self.reviewButton=button('查看评价对照',function()self.review=require('Training.FlowerQReview').build(self.saved.id,self.trials,require('Factory.Rules').hitReaction,7);self.assessment=require('Training.FlowerQAssessment').describe(self.saved,self.review);self.reviewing=true;self:render()end)
  self.adoptionButton=button('采用与回滚',function()
   self.busy=true;self.node.visible=false
   D.thread(function()
    local ok,view=xpcall(function()return require('Training.FlowerQAdoptionPanel').openAsync(self.models,function()self.adoptionView=nil;self.node.visible=true;self:load();self.busy=false;self:render()end)end,debug.traceback)
    if ok then self.adoptionView=view else self.diagnostic=view;self.node.visible=true;self.busy=false;self.message='成果页面未能打开，请重新进入。';self:render()end
   end)
  end)
  self.reviewBack=button('返回自主训练',function()self.reviewing=false;self:render()end)
  self.retry=button('重试保存',function()self.busy=true;self:render();D.thread(function()self:savePending();self.busy=false;self:render()end)end)
  self.discard=button('放弃未保存本轮',function()self.pending=nil;self.pendingKind=nil;self.saveError=nil;self.busy=true;self:render();D.thread(function()self:load();self.busy=false;self.message='已放弃未保存的本轮。'..(self.loadError and self.message or '已保存候选仍保留。');self:render()end)end)
  self.reload=button('重新读取',function()self.busy=true;self:render();D.thread(function()self:load();self.busy=false;self:render()end)end)
  self.stop=button('停止本轮',function()self.cancel=true;self.message='正在结束本轮，未完成的探索不会更新候选。';self:render()end)
  self.back=button('返回花妖对练',function()self.closed=true;node:removeFromParent();D.thread(onReturn)end)
  node:gslot('AppChange',function(name)if name=='Size'then self:layout()end end);self:render()
 end
 function self:load()
  self.resourceCandidate,self.resourceCandidateError=require('Training.ResourceQStore').loadLatestAsync()
  self.resourceTrials={};self.resourceTrialError=nil
  if self.resourceCandidate then self.resourceTrials,self.resourceTrialError=require('Training.ResourceQTrials').loadAsync(self.resourceCandidate.id)end
  self.resourceSaved,self.resourceReadError=require('Training.ResourcePracticeStore').loadLatestAsync()
  local saved,why=Store.loadAsync();self.saved=saved;self.loadError=not saved and why~='NOT_RECORDED' and why or nil
  if saved and not equal(saved.source.baseModels,self.models)then self.loadError='BASE_MODELS_CHANGED'end
  self.trials={}
  if saved and not self.loadError then local records,why=require('Training.FlowerQTrials').loadAsync(saved.id);if records then self.trials=records else self.loadError=why end end
  self.message=self.loadError and (messages[self.loadError] or '来源读取失败，原候选保留，请重试。') or saved and (saved.models.ninilite.featureSchemaVersion==6 and '当前为旧版Q候选；继续训练将创建距离状态新版，旧表与来源保留，新版需重新评价。' or '候选已从完整来源重建，可继续训练或试战。') or messages.NOT_RECORDED
 end
 function self:savePending()
  local ok,why
  if self.pendingKind=='resource-trial'then ok,why=require('Training.ResourceQTrials').saveAsync(self.pending,self.expectedResourceCandidate)
  elseif self.pendingKind=='resource'then ok,why=require('Training.ResourcePracticeStore').saveRunAsync(self.pending)
  elseif self.pendingKind=='trial'then ok,why=require('Training.FlowerQTrials').saveAsync(self.pending,self.expectedParent)
  else ok,why=Store.saveRunAsync(self.pending,self.expectedParent)end
  if not ok then self.message=messages[why] or '保存未成功，本轮成果保留，请重试。';self.saveError=why;return false end
  local resourceTrial=self.pendingKind=='resource-trial';local resource=self.pendingKind=='resource';local trial=self.pendingKind=='trial';self.pending=nil;self.pendingKind=nil;self.saveError=nil;self:load();self.message=self.loadError and self.message or (resourceTrial and '资源试战已独立保存，候选未更新；需同预算多次对照。'or resource and '练习记录已保存，可用“训练资源Q候选”汇总学习；正式策略未改变。'or trial and '本场评价已保存，候选没有更新；单次结果不代表稳定提升。' or '本轮候选与完整来源已保存，正式成果未改变。');return true
 end
 function self:start(mode)
  if self.reviewing or self.busy or self.pending or self.loadError or (mode~='explore' and not mode:match('^resource') and not self.saved)then return end
  local resourceTrial=mode=='resource-evaluate' or mode=='resource-compare'
  local compatible=self.resourceCandidate and self.resourceCandidate.bundle.trainingGoal=='resource-clear-v1'
  if resourceTrial and not compatible then self.message='请先完成新目标的资源练习并训练候选；旧候选保留供复盘。';self:render();return end
  if (resourceTrial or mode=='resource-explore' and compatible) and (not self.resourceCandidate or not equal(self.resourceCandidate.bundle.baseModels,self.models))then self.message='资源候选的基础模型已变化，请重新整理来源。';self:render();return end
  self.expectedResourceCandidate=resourceTrial and self.resourceCandidate.id or nil
  self.busy=true;self.cancel=false;self.message='正在准备训练场…';self.expectedParent=self.saved and self.saved.id or 0;self:render()
  D.thread(function()
   local ok,result=xpcall(function()
    return require('Training.FlowerQSession').runAsync({mode=mode=='resource-evaluate' and 'evaluate' or mode=='resource-explore' and 'explore' or mode:match('^resource') and 'basic' or mode,virtualSupplies=mode:match('^resource') and self.resourceLoadout or nil,models=self.models,initial=(mode=='resource-evaluate' or mode=='resource-explore') and compatible and self.resourceCandidate and self.resourceCandidate.models or not mode:match('^resource') and mode~='basic' and self.saved and self.saved.models or nil,profile=mode:match('^resource') and self.resourceProfile or self.profile,seed=(mode=='explore' or mode=='resource-explore') and (os.time()%2147483646+1) or nil,keepScene=true,
     cancelled=function()return self.cancel end,onStart=function(b)self.battle=b;self.running=true;self.message='';self:mount();require('System.Music').play(b.arena.world,'Music/训练场.mp3')end,
     onProgress=function()self:render()end,onFinish=function()self.running=false end})
   end,debug.traceback)
   self.running=false
   if ok then
    self.last=result
    if resourceTrial and result.status~='aborted'then self.pending=result;self.pendingKind='resource-trial';self:savePending()
    elseif (mode=='resources' or mode=='resource-explore') and result.status~='aborted'then self.pending=result;self.pendingKind='resource';self:savePending()
    elseif mode=='explore' and result.models then self.pending=result;self.pendingKind='explore';self:savePending()
    elseif result.status=='aborted'then self.message='本轮已停止，原候选保持不变。'
    elseif result.learningError then self.message='本轮轨迹未通过学习校验，原候选保留。';self.diagnostic=result.learningError
    else self.pending=result;self.pendingKind='trial';self:savePending()end
   else
    if self.battle and self.battle.phase=='playing'then pcall(function()self.battle:finish('aborted','训练执行中断')end)end
    self.message='训练未完成，原候选保留。';self.diagnostic=result
   end
   self.busy=false;self:render()
  end)
 end
 self:mount();self:load();self.busy=false;self:render();return self
end
return P
