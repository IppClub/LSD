local D=require('Dora');local S=require('Training.DisarmAdoptionStore');local C=require('Training.DisarmComparisonStore');local P={}
local equal=require('Training.FlowerIdentity').equal
local messages={ENCOUNTER_CHANGED='战斗规则已变化，请重新对照；旧记录仍可查看。',BASE_MODELS_CHANGED='基础成果已变化，请重新对照。',REVIEW_CHANGED='来源或对照已变化，请刷新审查。',ADOPTION_CHANGED='采用状态已变化，请刷新后再确认。',WRITE_FAILED='保存失败，原采用状态已保留，可以重试。',READ_FAILED='读取失败，请刷新重试。'}
function P.openAsync(actor,models,onReturn)
 local name=assert(require('Training.Characters')[actor]).name
 local self={busy=true,index=1,ids={},actor=actor,models=models,buttons={}}
 local view=require('UI.DisarmComparison')({title='缴械成果 · '..name,summary='正在核对来源与对照…'});self.view=view
 view.tag='disarm-adoption';view.state=self;view.backButton.visible=false;view:addTo(D.Director.ui3D);view:alignLayout()
 local function button(text,x,fn)
  local b;b=view.makeButton(text,x,function()if not self.closed and not self.busy and b.visible then fn()end end);return b
 end
 function self:render()
  local lines={self.current and string.format('当前采用 #%d · 候选 #%d',self.current.id,self.current.proof.candidate.id)or self.expected and self.expected.current>0 and '当前采用档案未通过核对，可尝试回滚。'or '当前使用基础策略。'}
  lines[#lines+1]='采用选择用于缴械演练与中英招清障任务；对照中的基准始终为基础模型。'
  if self.record then
   lines[#lines+1]=string.format('记录 #%d · %d/%d',self.ids[self.index],self.index,#self.ids)
   lines[#lines+1]=require('Training.DisarmCompare').text(self.record.record)
  else lines[#lines+1]=#self.ids==0 and '尚无该学员的完整对照。先示范、学习并完成六场对照。'or '本条记录未通过核对，可切换或重新对照。'end
  if self.confirming=='adopt'then table.insert(lines,2,'确认将这份候选用于缴械演练及正式中英招清障？请综合成本、承伤和耗时作出选择；采用后仍可回滚。')
  elseif self.confirming=='rollback'then table.insert(lines,2,self.current and self.current.parent>0 and '确认恢复上一版采用？历史记录保留。'or '确认恢复基础策略？历史记录保留。')end
  if self.message then table.insert(lines,2,self.message)end;view:setText(table.concat(lines,'\n\n'))
  local ready=not self.busy and not self.confirming
  self.previous.visible=ready and #self.ids>1;self.next.visible=self.previous.visible
  self.adopt.visible=ready and self.bundle~=nil and not self.currentError and not self.already
  self.rollback.visible=ready and self.expected~=nil and self.expected.current>0
  self.refresh.visible=ready;self.back.visible=ready
  self.confirm.visible=not self.busy and self.confirming~=nil;self.cancel.visible=self.confirm.visible
 end
 function self:reload(refreshIds)
  self.confirming=nil;self.bundle=nil;self.proof=nil;self.record=nil;self.message=nil
  if refreshIds then
   self.ids={};local ids,why=C.list();self.message=why and messages[why]
   for _,id in ipairs(ids or {})do local record=C.load(id);if record and record.record.setup.candidate.model.characterId==actor then self.ids[#self.ids+1]=id end end
   self.index=math.min(self.index,math.max(1,#self.ids))
  end
  self.expected=S.state(actor);self.current,self.currentError=S.inspectAsync(actor)
  if self.currentError=='NOT_ADOPTED'then self.currentError=nil end
  if not equal(self.expected,S.state(actor))then self.currentError='ADOPTION_CHANGED'end
  local id=self.ids[self.index]
  if id then
   self.record=C.load(id);local why;self.bundle,why=S.captureAsync(id,self.models)
   if self.bundle then self.proof=why else self.message=messages[why]or '候选来源未通过核对，请重新学习或对照。'end
  end
  self.already=self.current and self.current.scope=='practice-and-mission'and self.bundle and equal(self.current.bundle,self.bundle)
  if self.currentError then self.message=messages[self.currentError]or '当前采用档案未通过核对，请检查或回滚。'end
  if self.already then self.message='此记录对应的候选已经采用。'end
 end
 local function reload(refreshIds)
  self.busy=true;self:render();D.thread(function()self:reload(refreshIds);self.busy=false;self:render()end)
 end
 self.previous=button('上一记录',-510,function()self.index=(self.index-2)%#self.ids+1;reload(false)end)
 self.next=button('下一记录',-310,function()self.index=self.index%#self.ids+1;reload(false)end)
 self.adopt=button('采用候选',-110,function()self.confirming='adopt';self:render()end)
 self.rollback=button('回滚成果',90,function()self.confirming='rollback';self:render()end)
 self.refresh=button('刷新审查',290,function()reload(true)end)
 self.back=button('返回训练',490,function()self.closed=true;view:removeFromParent();onReturn()end)
 self.cancel=button('取消',250,function()self.confirming=nil;self:render()end)
 self.confirm=button('确认',-150,function()
  local kind=self.confirming;self.busy=true;self:render()
  D.thread(function()
   local yes,why
   if kind=='adopt'then
    local fresh=require('Training.FlowerPractice').models()
    yes,why=S.adoptAsync(self.bundle,{accepted=true,scope='practice-and-mission',comparisonId=self.bundle.comparison.id,review=self.proof.review},fresh,self.expected)
   else yes,why=S.rollbackAsync(actor,self.expected)end
   self.confirming=nil
   if yes then self:reload(false);self.message=kind=='adopt'and '已保存采用选择，下次缴械演练或中英招清障生效。'or '已回滚，下次出战按恢复档案的适用范围行动。'
   else self.message=messages[why]or '操作未完成，请刷新后重试。'end
   self.busy=false;self:render()
  end)
 end)
 self:render();self:reload(true);self.busy=false;self:render();return self
end
return P
