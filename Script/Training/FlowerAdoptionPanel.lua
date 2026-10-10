-- Explicit review of frozen evidence. Opening/navigation never changes adoption.
local D=require('Dora');local P={}
local ids={'near','far','reproduction','field'}
local errors={Q_ADOPTION_ACTIVE='当前使用自主训练策略，请先在“采用与回滚”中退回基础策略。',TEAM_ADOPTION_ACTIVE='当前使用双人联合成果，请在联合成果审查中成组回滚。',NOT_ADOPTED='当前使用基础成果。',ENCOUNTER_CHANGED='已采用记录来自旧战斗规则，当前使用基础成果；可回滚。',PARTNER_DEPLOYMENT_UNTESTED='另一学员已有专项成果；两人共同部署尚未验证。',BASIC_MODELS_CHANGED='基础或伙伴成果已改变，需要重新评价。',MISSING_PROFILE_PAIR='尚缺近距、远距或繁殖期配对评价。',FIELD_EVALUATION_REQUIRED='尚缺默认补给完整阵型评价。',MISSING_EVIDENCE='候选缺少可重建的示范来源。',NOT_RECORDED='尚无候选来源记录。',WRITE_FAILED='保存未成功，原成果保留，可重试。',REVIEW_STALE='候选或试战记录已变化，请关闭后重新审查。',ADOPTION_STATE_CHANGED='当前成果已变化，请关闭后重新审查。',EVALUATION_BLOCKED='候选仍有未胜利的评价，暂不能采用。',BUSY='另一项保存尚未完成。',ADOPTED='已采用花妖专项成果。',ALREADY_ADOPTED='此成果已经采用。',RESTORED_BASIC='已恢复基础成果。',ROLLED_BACK='已恢复上一版专项成果。'}
local function explain(code)return errors[code] or '记录暂不可用，请重新进入审查。'end
function P.open(actor,models,onClose)
 local Store=require('Training.FlowerAdoptionStore');local Review=require('Training.FlowerAdoptionReview')
 local self={page=0,seen={},busy=false,closed=false};local equal=require('Training.FlowerIdentity').equal
 local source,sourceError=require('Training.FlowerPolicyStore').evidence(actor)
 local rows,rowsError=require('Training.FlowerTrialStore').history(actor)
 self.source=source;self.pairs={};self.ruleCurrent={};self.profileErrors={}
 local function current(trial)return trial and require('Factory.Rules').current(trial.setup) end
 if source and rows then
  self.bundle,self.review=Review.make(source,models,rows)
  if not self.bundle then self.error=self.review;self.review=nil end
  for _,id in ipairs(ids)do
   local basic,candidate
   for _,r in ipairs(rows)do
    if r.status~='aborted' and r.setup.profile and r.setup.profile.id==id and equal(r.setup.models,models)then
     if r.controller=='basic' and not basic then basic=r
     elseif r.controller=='candidate' and not candidate and equal(r.policy,source.policy)then candidate=r end
    end
   end
   self.ruleCurrent[id]=current(basic) and current(candidate)
   if basic and candidate then self.pairs[id],self.profileErrors[id]=require('Training.FlowerComparison').build(basic,candidate)
   else self.profileErrors[id]='MISSING_PAIR' end
  end
 else self.error=sourceError or rowsError end
 local function refreshCurrent()
  self.current,self.currentError=Store.inspect(actor)
  local deployed,why=Store.load(actor,models);self.deploymentError=why;self.deployed=deployed
  if not self.current then self.rollbackPending=false end
  self.partner,self.partnerError=Store.inspect(actor=='ninilite' and 'wuyun' or 'ninilite')
 end
 refreshCurrent()
 self.ready=self.bundle~=nil and self.bundle.fieldTrials~=nil and self.review.readyForDecision and not self.partner and self.partnerError=='NOT_ADOPTED' and (self.current~=nil or self.currentError=='NOT_ADOPTED')
 for _,id in ipairs(ids)do if not self.ruleCurrent[id]then self.ready=false end end
 if self.deploymentError=='TEAM_ADOPTION_ACTIVE'then self.ready=false end
 local node=D.Node();self.node=node;node.order=100;node:addTo(D.Director.ui3D)
 local bg=D.DrawNode();bg.order=-1;bg:addTo(node)
 local label=D.Label('SourceHanSansCN-Regular',24);label.anchor=D.Vec2(0,1);label.alignment='Left';label:addTo(node);self.label=label
 local function button(text,fn)
  local b=require('UI.InputButton')({text=text,textBG=''});b.scaleX=.52;b.scaleY=.52;b:addTo(node);b:slot('Tapped'):clear();b:slot('Tapped',function()if not self.closed and not self.busy then fn()end end);return b
 end
 local function reviewed()for page=1,4 do if not self.seen[page]then return false end end;return true end
 function self:render()
  if self.closed then return end
  local lines={(actor=='ninilite' and '妮妮莉特' or '乌云')..' · 花妖成果审查（'..(self.page+1)..'/5）'}
  if self.page==0 then
   if self.source then
    lines[#lines+1]=string.format('候选：%d个示范 / %d轮来源；拟合率%.0f%%不代表战斗胜率。',source.policy.sampleCount,#source.policy.sourceEpisodes,source.policy.trainingAccuracy*100)
    lines[#lines+1]=require('Training.FlowerPolicy').learnedActionsText(source.policy)
   else lines[#lines+1]=explain(sourceError)end
   lines[#lines+1]=self.current and ('当前存档：专项 #'..self.current.id..'；上一版：'..(self.current.parent==0 and '基础成果' or '#'..self.current.parent)) or explain(self.currentError)
   lines[#lines+1]=self.deployed and '当前专项可以部署。' or explain(self.deploymentError)
   for _,id in ipairs(ids)do
    local pair=self.pairs[id];local name=require('Training.FlowerScenarios').get(id).name
    lines[#lines+1]=name..'：'..(not pair and '缺少同配置配对评价' or not self.ruleCurrent[id] and '旧战斗规则，请重新评价' or pair.candidate.won and '候选胜利（仍需审查取舍）' or '候选失败，不能采用')
   end
   if self.partner or self.partnerError~='NOT_ADOPTED'then lines[#lines+1]=explain(self.partner and 'PARTNER_DEPLOYMENT_UNTESTED' or self.partnerError)end
   lines[#lines+1]=self.ready and '请逐项查看四种配置的收益与退步，再明确选择是否采用。' or '评价未满足采用条件，现有成果保留。'
   lines[#lines+1]='回滚只恢复已保存的上一版；不会删除示范、试战或历史成果。'
  else
   local id=ids[self.page];local pair=self.pairs[id]
   lines[#lines+1]=require('Training.FlowerScenarios').get(id).name
   if not pair then lines[#lines+1]='尚无配置一致的基础 / 当前候选完整对照。'
   else
    lines[#lines+1]='基础：'..(pair.basic.won and '胜利' or '失败')..'；候选：'..(pair.candidate.won and '胜利' or '失败')
    if not self.ruleCurrent[id]then lines[#lines+1]='此评价来自旧战斗规则，不能用于当前采用。'end
    local metrics={{'armor','有效削甲'},{'health','有效生命伤害'},{'assistedHealth','破甲协作'},{'teamDamage','队伍承伤'},{'friendlyDamage','误伤'},{'teamFinalHP','剩余队伍生命'},{'seconds','用时（秒）'}}
    lines[#lines+1]='指标：基础 → 候选（差值）'
    for _,m in ipairs(metrics)do lines[#lines+1]=string.format('%s：%.1f → %.1f（%+.1f）',m[2],pair.basic[m[1]],pair.candidate[m[1]],pair.delta[m[1]])end
    if not pair.basic.won or not pair.candidate.won then lines[#lines+1]='失败回合的较短用时不代表提速。'end
    lines[#lines+1]='单组实战不能证明稳定提升；承伤、误伤和用时增加均需留意。'
   end
  end
  if self.rollbackPending then lines[#lines+1]='将恢复 '..(self.current.parent==0 and '基础成果' or '专项 #'..self.current.parent)..'，请点“确认回滚”。'end
  if self.message then lines[#lines+1]=self.message end
  if self.busy then lines[#lines+1]='正在验证并保存，请稍候…'end
  label.text=table.concat(lines,'\n')
  self.previous.visible=self.page>0;self.next.visible=self.page<4
  self.adopt.visible=self.ready and reviewed() and not self.rollbackPending and not self.saved
  self.rollback.visible=self.current~=nil and not self.rollbackPending
  self.confirmRollback.visible=self.current~=nil and self.rollbackPending==true
 end
 function self:close()
  if self.busy or self.closed then return false end
  self.closed=true;node:removeFromParent();onClose();return true
 end
 self.previous=button('上一项',function()self.page=math.max(0,self.page-1);self:render()end)
 self.next=button('下一项',function()self.page=math.min(4,self.page+1);self.seen[self.page]=true;self:render()end)
 self.back=button('返回对练',function()self:close()end)
 self.adopt=button('确认采用',function()
  if not self.ready or not reviewed() or self.saved then return end
  self.busy=true;self:render()
  D.thread(function()
   local ok,why=Store.adoptAsync(self.bundle,{accepted=true,review=self.review})
   self.busy=false;self.saved=ok;self.error=not ok and why or nil;self.message=explain(why);refreshCurrent();self:render()
  end)
 end)
 self.rollback=button('恢复上一版',function()self.page=0;self.rollbackPending=true;self:render()end)
 self.confirmRollback=button('确认回滚',function()
  if not self.current or not self.rollbackPending then return end
  local expected=self.current.id;self.busy=true;self:render()
  D.thread(function()
   local ok,why=Store.rollbackAsync(actor,expected)
   self.busy=false;self.error=not ok and why or nil;self.message=explain(why);if ok then self.rollbackPending=false end
   refreshCurrent();self:render()
  end)
 end)
 local function layout()
  local size=D.App.bufferSize;local scale=math.min(1,size.height/750,size.width/1000)
  node.scaleX=scale;node.scaleY=scale;size=D.Size(size.width/scale,size.height/scale);node.size=size;label.position=D.Vec2(35,size.height-30);label.textWidth=size.width-70
  bg:clear();bg:drawPolygon({D.Vec2.zero,D.Vec2(size.width,0),D.Vec2(size.width,size.height),D.Vec2(0,size.height)},D.Color(0xff101b28))
  self.previous.position=D.Vec2(size.width*.16,45);self.next.position=D.Vec2(size.width*.43,45);self.back.position=D.Vec2(size.width*.73,45)
  self.adopt.position=D.Vec2(size.width*.43,115);self.rollback.position=D.Vec2(size.width*.16,115);self.confirmRollback.position=self.rollback.position
 end
 layout();node:gslot('AppChange',function(name)if name=='Size'then layout()end end);self:render();return self
end
return P
