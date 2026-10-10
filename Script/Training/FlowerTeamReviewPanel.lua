-- Read-only joint review; complete combinations remain separate from single adoption.
local D=require('Dora');local P={};local ids={'near','far','reproduction','field'}
function P.open(sources,models,onClose)
 local Store=require('Training.FlowerTeamAdoptionStore')
 local self={page=0,closed=false,seen={},busy=false}
 local messages={Q_ADOPTION_ACTIVE='当前使用自主训练策略，请先在“采用与回滚”中退回基础策略。',ADOPTED='已采用完整联合成果。',ALREADY_ADOPTED='当前已采用此组合。',RESTORED_BASIC='两人已恢复基础成果。',ROLLED_BACK='已恢复上一版组合。',WRITE_FAILED='保存失败，原组合保留，可重试。',REVIEW_STALE='来源或评价已改变，请重新审查。',SINGLE_ADOPTION_ACTIVE='请先在单人成果审查中回滚专项，再采用联合组合。',NOT_ADOPTED='当前未采用联合成果。'}
 local function refresh()self.current,self.currentError=Store.inspect()end;refresh();local rows,why=require('Training.FlowerTeamTrials').history()
 if rows then self.bundle,self.review=require('Training.FlowerTeamReview').make(sources,models,rows);if not self.bundle then self.error=self.review;self.review=nil end else self.error=why end
 local node=D.Node();node.order=100;node:addTo(D.Director.ui3D);self.node=node
 local bg=D.DrawNode();bg.order=-1;bg:addTo(node)
 local label=D.Label('SourceHanSansCN-Regular',24);label.anchor=D.Vec2(0,1);label.alignment='Left';label:addTo(node);self.label=label
 local function button(text,fn)
  local b=require('UI.InputButton')({text=text,textBG=''});b.scaleX=.52;b.scaleY=.52;b:addTo(node);b:slot('Tapped'):clear();b:slot('Tapped',function()if not self.closed and not self.busy then fn()end end);return b
 end
 function self:render()
  local lines={'双学员组合审查（'..(self.page+1)..'/5）'}
  if not self.review then
   lines[#lines+1]=self.error=='MISSING_PROFILE_PAIR' and '请先完成同一组合的四类基础 / 候选配对试战。' or '联合记录暂不可用，请重新进入审查。'
  elseif self.page==0 then
   for _,id in ipairs({'ninilite','wuyun'})do
    local policy=self.bundle.sources[id].policy
    lines[#lines+1]=string.format('%s：%d个示范，拟合率%.1f%%。',id=='ninilite' and '妮妮莉特' or '乌云',policy.sampleCount,policy.trainingAccuracy*100)
    lines[#lines+1]=require('Training.FlowerPolicy').learnedActionsText(policy)
   end
   lines[#lines+1]='拟合率描述示范学习情况，不代表联合胜率。'
   for _,id in ipairs(ids)do
    local pair=self.review.pairs[id];lines[#lines+1]=require('Training.FlowerScenarios').get(id).name..'：双基础'..(pair.basic.won and '胜利' or '失败')..' / 双候选'..(pair.candidate.won and '胜利' or '失败')
   end
   lines[#lines+1]=string.format('观察到%d项收益、%d项退步；请逐页查看具体取舍。',#self.review.improvements,#self.review.tradeoffs)
   lines[#lines+1]=self.review.readyForDecision and '四类候选均胜；单次对照仍不能证明稳定提升。' or '存在失败或旧战斗规则评价，需要重新试战。'
  else
   local id=ids[self.page];local pair=self.review.pairs[id]
   lines[#lines+1]=require('Training.FlowerScenarios').get(id).name
   lines[#lines+1]='双基础：'..(pair.basic.won and '胜利' or '失败')..'；双候选：'..(pair.candidate.won and '胜利' or '失败')
   lines[#lines+1]='指标：基础 → 候选（候选减基础）'
   for _,m in ipairs({{'armor','两学员有效削甲'},{'health','两学员生命伤害'},{'assistedHealth','两学员破甲协作'},{'teamDamage','全队承伤'},{'friendlyDamage','全队误伤'},{'teamHealing','全队治疗'},{'teamFinalHP','剩余队伍生命'},{'seconds','用时（秒）'}})do
    lines[#lines+1]=string.format('%s：%.1f → %.1f（%+.1f）',m[2],pair.basic[m[1]],pair.candidate[m[1]],pair.delta[m[1]])
   end
   lines[#lines+1]='承伤、误伤增加需要留意；治疗多寡需结合受伤与剩余生命判断。'
   if not pair.basic.won or not pair.candidate.won then lines[#lines+1]='失败回合的较短用时不代表提速。'end
  end
  lines[#lines+1]=self.current and ('当前联合成果 #'..self.current.id..'；可恢复上一版。') or (messages[self.currentError] or '当前联合成果读取失败。')
  lines[#lines+1]='采用将同时部署两名学员；单人专项须先回滚。'
  if self.rollbackPending then lines[#lines+1]='请确认恢复上一版完整组合。'end
  if self.message then lines[#lines+1]=self.message end
  if self.busy then lines[#lines+1]='正在重建来源并保存，请稍候…'end
  local seen=true;for i=1,4 do if not self.seen[i]then seen=false end end
  self.adopt.visible=seen and self.review~=nil and self.review.readyForDecision and not self.saved and not self.rollbackPending
  self.rollback.visible=self.current~=nil and not self.rollbackPending
  self.confirmRollback.visible=self.current~=nil and self.rollbackPending==true
  label.text=table.concat(lines,'\n');self.previous.visible=self.page>0;self.next.visible=self.review~=nil and self.page<4
 end
 self.previous=button('上一项',function()self.page=math.max(0,self.page-1);self:render()end)
 self.next=button('下一项',function()if self.review then self.page=math.min(4,self.page+1);self.seen[self.page]=true;self:render()end end)
 self.back=button('返回试战',function()self.closed=true;node:removeFromParent();onClose()end)
 self.adopt=button('确认联合采用',function()
  if not self.adopt.visible or not self.bundle then return end
  self.busy=true;self:render();D.thread(function()
   local ok,why=Store.adoptAsync(self.bundle,{accepted=true,review=self.review})
   self.busy=false;self.saved=ok;self.error=not ok and why or nil;self.message=messages[why] or '成果未改变，请重新审查。';refresh();self:render()
  end)
 end)
 self.rollback=button('恢复上一版',function()if not self.current then return end;self.rollbackPending=true;self:render()end)
 self.confirmRollback=button('确认回滚',function()
  if not self.rollbackPending or not self.current then return end
  local expected=self.current.id;self.busy=true;self:render();D.thread(function()
   local ok,why=Store.rollbackAsync(expected);self.busy=false;self.error=not ok and why or nil;self.message=messages[why] or '成果未改变，请重新审查。'
   if ok then self.rollbackPending=false;self.saved=false end;refresh();self:render()
  end)
 end)
 local function layout()
  local size=D.App.bufferSize;local scale=math.min(1,size.height/800,size.width/1100);node.scaleX=scale;node.scaleY=scale
  size=D.Size(size.width/scale,size.height/scale);node.size=size;label.position=D.Vec2(35,size.height-30);label.textWidth=size.width-70
  bg:clear();bg:drawPolygon({D.Vec2.zero,D.Vec2(size.width,0),D.Vec2(size.width,size.height),D.Vec2(0,size.height)},D.Color(0xff101b28))
  self.previous.position=D.Vec2(size.width*.16,45);self.next.position=D.Vec2(size.width*.43,45);self.back.position=D.Vec2(size.width*.73,45)
  self.adopt.position=D.Vec2(size.width*.43,110);self.rollback.position=D.Vec2(size.width*.16,110);self.confirmRollback.position=self.rollback.position
 end
 layout();node:gslot('AppChange',function(name)if name=='Size'then layout()end end);self:render();return self
end
return P
