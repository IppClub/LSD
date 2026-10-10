-- Read-only actual outcomes, prospective production failure wording/UI check.
local entry,resultName=...
local D=require('Dora')
local root=D.Path:getPath(D.Path:getScriptPath(entry))
local out=root..'/Test/'..(resultName or 'actual-party-defeat-reason-result.json')
local result={status='RUNNING',osInput=false,uiOnly=true,combatReplayed=false,cases={}}
local function save()D.Content:save(out,D.json.encode(result,false,true))end
save()
D.thread(function()
 local ok,why=xpcall(function()
  local records={
   {'/private/tmp/lsd-battle-feedback-os-boss-20261009/result.json','导师倒下，行动中止。'},
   {'/private/tmp/lsd-battle-feedback-output-os-boss-20261009/result.json','乌云倒下，行动中止。'},
   {'/private/tmp/lsd-battle-feedback-sustained-os-boss-20261009/result.json','辅助机被摧毁，调查行动中止。'},
  }
  local Battle=require('Factory.PatrolBattle')
  local Characters=require('Training.Characters')
  for index,spec in ipairs(records)do
   local before=assert(D.Content:load(spec[1]))
   local actual=assert(D.json.decode(before,32))
   assert(actual.status=='PASS'and actual.outcome=='failed'and actual.returnedToTrain)
   local learners={}
   for _,id in ipairs({'ninilite','wuyun'})do
    learners[#learners+1]={character=Characters[id],studentHP=actual.battle.learners[id].hp}
   end
   local state=setmetatable({mentorHP=actual.battle.mentorHP,learners=learners},Battle)
   local cause
   if state:partyDefeated()then
    cause=state.defeatReason and state:defeatReason()or'队伍失去战斗能力。'
   else cause=actual.battle.reason end
   result.cases[index]={source=spec[1],recordedReason=actual.battle.reason,prospectiveReason=cause,expected=spec[2],screenshots={}}
   save()
   assert(cause==spec[2],'Actual defeated actor hidden by generic failure reason: '..cause)
   for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
    D.App.winSize=size;D.sleep(.15)
    local view=require('UI.Settlement')({missionMode=true,resultStatus='Failed',resultTitle='讨伐未完成',missionTitle='地面调查 · 大英招讨伐',economy=actual.battle.economy,storyText=cause,reportText='实际倒下成员反馈验证',baseText='返回列车'})
    view:addTo(D.Director.ui3D);D.sleep(.2);view:alignLayout();D.sleep(.1)
    assert(view.resultLayout=='MissionFail'and view.failureReasonLabel.text==cause and view.failureReasonLabel.visible)
    assert(view.economyLabel.text:find('消耗 %-'..string.format('%d',actual.battle.economy.cost))and view.economyLabel.text:find('结余 '..string.format('%d',actual.balanceAfter),1,true))
    local path=D.Path(D.Content.writablePath,'actual-party-defeat-'..index..'-'..string.format('%d',D.App.bufferSize.width)..'.tga')
    D.App:saveScreenshot(path);D.sleep(.1)
    result.cases[index].screenshots[#result.cases[index].screenshots+1]={path=path,width=D.App.bufferSize.width,height=D.App.bufferSize.height}
    view.reportButton:emit('Tapped');D.sleep(.1)
    assert(view.reportLabel.text:find(cause,1,true))
    view.reportPanel.backButton:emit('Tapped');D.sleep(.1);assert(view.visible)
    view:removeFromParent()
   end
   assert(D.Content:load(spec[1])==before,'Historical actual report changed')
   result.cases[index].actualRecordUnchanged=true;save()
  end
  result.sourceRecordsUnchanged=true
 end,debug.traceback)
 result.status=ok and'PASS'or'FAIL';result.error=not ok and why or nil;save()
end)
