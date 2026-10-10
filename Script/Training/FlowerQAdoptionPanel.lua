local D=require('Dora');local P={};local ids={'near','far','reproduction','field'}
local A=require('Training.FlowerQAssessment');local S=require('Training.FlowerQAdoptionStore')
local messages={ENCOUNTER_CHANGED='战斗规则已更新，请重新评价；旧成果仍可查看和回滚。',WRITE_FAILED='保存失败，原采用状态保持不变，可以重试。',REVIEW_STALE='候选或评价已有变化，请刷新并重新查看。',Q_ADOPTION_CHANGED='采用版本已变化，请刷新后重试。',OTHER_POLICY_ACTIVE='当前正在使用C4.5花妖专项，请先在对应成果页退回基础策略。',BASE_MODELS_CHANGED='基础成果已变化，请返回训练室重新进入。',EVALUATION_BLOCKED='评价证据还不完整，请补齐试战。',READ_FAILED='读取失败，请刷新重试。'}
function P.openAsync(models,onReturn)
 local self={models=D.json.decode(D.json.encode(models,false,true),32),page=1,seen={},busy=true,closed=false,message='正在重建候选与评价…'}
 local node=D.Node();node.tag='flower-q-adoption-controls';node.panel=self;node.order=200;node:addTo(D.Director.ui3D);self.node=node
 local bg=D.DrawNode();bg.order=-1;bg:addTo(node)
 local label=D.Label('SourceHanSansCN-Regular',23);label.anchor=D.Vec2(0,1);label.alignment='Left';label:addTo(node);self.label=label
 self.buttons={}
 local function button(text,fn)
  local b=require('UI.InputButton')({text=text,textBG=''});b.scaleX=.5;b.scaleY=.5;b:addTo(node);b:slot('Tapped'):clear()
  b:slot('Tapped',function()if not self.closed and not self.busy and b.visible then fn()end end);self.buttons[#self.buttons+1]=b;return b
 end
 function self:layout()
  local size=D.App.bufferSize;local scale=math.min(1,size.width/1200,size.height/1000);node.scaleX=scale;node.scaleY=scale
  local w,h=size.width/scale,size.height/scale;node.size=D.Size(w,h);label.position=D.Vec2(25,h-20);label.textWidth=w-340
  bg:clear();bg:drawPolygon({D.Vec2.zero,D.Vec2(w,0),D.Vec2(w,h),D.Vec2(0,h)},D.Color(0xff101b28))
  local n=0;for _,b in ipairs(self.buttons)do if b.visible then b.position=D.Vec2(w-155,h-50-n*54);n=n+1 end end
 end
 function self:render()
  local lines={'花妖自主成果 · '..require('Training.FlowerScenarios').get(ids[self.page]).name}
  lines[#lines+1]=self.current and string.format('当前采用 #%d；来自候选 #%d。',self.current.id,self.current.bundle.candidate) or self.expected and self.expected>0 and '当前采用档案读取异常；可尝试回滚，历史仍保留。' or '当前未采用Q策略。'
  if self.currentOldRules then lines[#lines+1]='当前档案来自旧战斗规则，正式战斗使用基础策略；旧档案可回滚，重新评价后再采用。'end
  if self.bundle then
   lines[#lines+1]=require('Training.FlowerQReview').text(self.bundle.assessment.review,ids[self.page])
   lines[#lines+1]=A.text(self.bundle.assessment,ids[self.page])
  end
  local count=0;for _,id in ipairs(ids)do if self.seen[id]then count=count+1 end end
  lines[#lines+1]=string.format('已查看%d/4类场景；采用会同时影响两名学员的正式花妖战斗。',count)
  if self.confirming=='adopt'then lines[#lines+1]='确认采用当前审查的候选？不保证比基础策略更好；可在此回滚。'
  elseif self.confirming=='rollback'then lines[#lines+1]=self.current and self.current.parent>0 and ('确认恢复上一采用 #'..self.current.parent..'？当前历史将保留。') or '确认回滚当前采用？无上一版时恢复基础策略，历史保留。'end
  lines[#lines+1]=self.message or '';label.text=table.concat(lines,'\n')
  local ready=not self.busy and not self.confirming
  self.previous.visible=ready and self.bundle~=nil;self.next.visible=self.previous.visible
  self.adopt.visible=ready and self.bundle~=nil and self.bundle.assessment.readyForDecision and count==4 and not self.stale and not self.alreadyAdopted and not self.currentError
  self.confirmAdopt.visible=not self.busy and self.confirming=='adopt'
  self.rollback.visible=ready and self.expected~=nil and self.expected>0
  self.confirmRollback.visible=not self.busy and self.confirming=='rollback'
  self.cancel.visible=not self.busy and self.confirming~=nil;self.refresh.visible=ready;self.back.visible=ready
  self:layout()
 end
 function self:reload()
  self.seen={};self.confirming=nil;self.stale=nil;self.error=nil
  self.bundle,self.error=A.captureAsync(self.models)
  self.expected=S.currentId();self.current,self.currentError=S.inspectAsync()
  if self.currentError=='NOT_ADOPTED'then self.currentError=nil end
  self.currentOldRules=self.current and not require('Factory.Rules').qCurrent(self.current.bundle)
  self.alreadyAdopted=self.current and self.bundle and require('Training.FlowerIdentity').equal(self.current.bundle,self.bundle) or false
  if self.bundle then self.seen[ids[self.page]]=true end
  self.message=self.error and (messages[self.error] or '候选来源读取失败，请刷新或返回训练。') or self.currentError and '采用档案未通过校验，请先检查或回滚。' or self.alreadyAdopted and '该审查版本已经采用。' or '请查看四类场景中的收益与不利变化，再决定是否采用。'
 end
 local function operation(kind)
  self.busy=true;self:render()
  D.thread(function()
   local success,ok,why=xpcall(function()
    if kind=='adopt'then return S.adoptAsync(self.bundle,{accepted=true,assessment=self.bundle.assessment},self.models,self.expected)end
    return S.rollbackAsync(self.expected)
   end,debug.traceback)
   self.confirming=nil;self.error=success and (not ok and why or nil) or 'OPERATION_ERROR'
   if success and ok then
    self:reload();if kind=='adopt' and self.alreadyAdopted then for _,id in ipairs(ids)do self.seen[id]=true end end;self.message=kind=='adopt' and '已采用双人自主策略，下次正式花妖战斗生效。' or '已回滚，原档案保留，下次正式花妖战斗使用恢复后的策略。'
    if self.error or self.currentError then self.message=self.message..' 仍有来源读取异常，请刷新检查。'end
   else
    self.stale=self.error=='REVIEW_STALE' or self.error=='Q_ADOPTION_CHANGED'
    self.message=messages[self.error] or '操作未完成，请刷新确认当前状态。'
   end
   self.busy=false;self:render()
  end)
 end
 self.previous=button('上一场景',function()self.page=(self.page+2)%4+1;self.seen[ids[self.page]]=true;self:render()end)
 self.next=button('下一场景',function()self.page=self.page%4+1;self.seen[ids[self.page]]=true;self:render()end)
 self.adopt=button('采用该候选',function()self.confirming='adopt';self:render()end)
 self.confirmAdopt=button('确认采用双人策略',function()operation('adopt')end)
 self.rollback=button('回滚当前采用',function()self.confirming='rollback';self:render()end)
 self.confirmRollback=button('确认回滚',function()operation('rollback')end)
 self.cancel=button('取消',function()self.confirming=nil;self:render()end)
 self.refresh=button('刷新审查',function()self.busy=true;self:render();D.thread(function()self:reload();self.busy=false;self:render()end)end)
 self.back=button('返回自主训练',function()self.closed=true;node:removeFromParent();D.thread(onReturn)end)
 node:gslot('AppChange',function(name)if name=='Size'then self:layout()end end)
 self:render();self:reload();self.busy=false;self:render();return self
end
return P
