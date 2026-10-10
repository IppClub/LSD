local D=require('Dora');local M={}
function M.openAsync(onReturn,characterId,models,candidate,values)
 D.Director.ui3D:removeAllChildren()
 local panel=require('UI.SupplyLoadout')({trainingNote='已采用成果按当前战斗规则重新对照；旧规则成果仅作为虚拟对照基准，重新审查采用后才可用于正式任务。',virtual=true,virtualMode='yingzhao-compare',values=values or require('Economy.Loadout').defaults(),formation={mentor=true,learner=true,wuyun=true},closed=function(confirmed,selection)
  if not confirmed then require('Training.Level')(onReturn,characterId);return end
  D.thread(function()
   local cancelled=false;local label
   local ok,report=xpcall(function()
    local adoption=require('Training.YingzhaoAdoptionStore');local other=characterId=='ninilite'and'wuyun'or'ninilite'
    local function comparisonSource(actor)
     local source,why=adoption.loadAsync(actor,models,'mission')
     -- A rules update invalidates deployment, not the immutable learned model.
     -- Compare that explicitly confirmed model under the current environment;
     -- every other rejection remains a rejection, including changed base models.
     if not source and why=='ENCOUNTER_CHANGED' then
      source,why=adoption.inspectAsync(actor)
      if source and source.scope~='practice-and-mission' then source=nil;why='MISSION_NOT_CONFIRMED'end
      if source and not require('Training.FlowerIdentity').equal(models,source.proof.record.setup.models)then source=nil;why='BASE_MODELS_CHANGED'end
     end
     assert(source or why=='NOT_ADOPTED','当前专项配置不可用，请先检查成果审查。 '..tostring(why))
     return source
    end
    local primary=comparisonSource(characterId)
    local companion=comparisonSource(other)
    local states={[characterId]=assert(adoption.state(characterId)),[other]=assert(adoption.state(other))}
    return require('Training.YingzhaoComparison').runAsync(models,candidate.model,selection.loadout,nil,{
    baseline=primary and primary.proof.candidate.model,companion=companion and companion.proof.candidate.model,adoptionStates=states,
    candidateId=candidate.id,
    cancelled=function()return cancelled end,
    onBattle=function(b,mode,index)
     local ui=D.Node();ui.size=D.App.bufferSize;ui.tag='yingzhao-comparison-progress';ui:addTo(D.Director.ui3D)
     label=assert(D.Label('SourceHanSansCN-Regular',26));label.anchor=D.Vec2(0,1);label.alignment='Left';label.textWidth=ui.width-400;label.position=D.Vec2(30,ui.height-30);label:addTo(ui)
     local holder=D.Node();holder.tag='comparison-stop-holder';holder.scaleX=.5;holder.scaleY=.5;holder.position=D.Vec2(ui.width-190,ui.height-85);holder:addTo(ui)
     local stop=require('UI.InputButton')({text='停止对照',textBG=''});stop.tag='comparison-stop';stop:addTo(holder);stop:slot('Tapped',function()cancelled=true end);ui.stopButton=stop
    end,
    update=function(b,mode)label.text=string.format('大英招对照 · %s\\n自动运行；两场相同补给与导师规则。\\nBoss生命 %.0f · 当前虚拟消耗 %d',mode=='baseline'and'原策略 1/2'or'候选 2/2',b.enemies[1].enemyHP,b.supplies.ledger.spent):gsub('\\n','\n')end,
   })end,debug.traceback)
   D.Director.ui3D:removeAllChildren()
   local store=require('Training.YingzhaoComparisonStore');local saved,saveError
   if ok and not report.cancelled then saved,saveError=store.saveAsync(report)end
   local summary=ok and require('Training.YingzhaoComparison').text(report)or'对照未完成，请返回重试；原成果保留。'
   local saving=false;local view
   view=require('UI.DisarmComparison')({title='大英招 · 原策略与候选对照',summary=summary,saved=saved,saveFailed=ok and not report.cancelled and not saved,
    closed=function()if not saving then require('Training.Level')(onReturn,characterId)end end,
    retry=function()
     if saving or saved then return end;saving=true;view.retryButton.visible=false;view.discardButton.visible=false
     D.thread(function()
      saved,saveError=store.saveAsync(report);saving=false;view.saved=saved;view.saveError=saveError
      view.retryButton.visible=not saved;view.discardButton.visible=not saved;view.backButton.visible=saved~=nil
      view:setText(summary..(saved and ('\n对照记录 #'..saved..' 已保存。')or'\n保存失败，可重试或放弃并返回。'))
     end)
    end})
   view.tag='yingzhao-comparison-result';view.report=ok and report or nil;view.error=not ok and report or nil;view.saved=saved;view.saveError=saveError;view:addTo(D.Director.ui3D);view:alignLayout()
  end)
 end})
 panel.tag='yingzhao-comparison-budget';panel:addTo(D.Director.ui3D);panel:alignLayout();return panel
end
return M
