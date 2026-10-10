-- Frozen adopted learners and the existing VR/HUD; no training or story writes.
local D=require('Dora');local P={}
function P.createAsync(models,loadout,demonstrator,candidate,useAdopted)
 local Enemy=require('Enemy.MediumYingzhao');D.Cache:loadAsync('spine:'..Enemy.asset)
 local battle=require('Factory.PatrolBattle').createAsync(models,{
  id='medium-yingzhao-practice',scene='VRTraining',enemyAsset=Enemy.asset,enemyFactory=Enemy.create,controller=Enemy,
  singleEnemy=true,enemyHP=360,timeLimit=90,
  timeoutReason='演练超时。留意抢夺前摇，失去武器后先避开射击。',
  victory=function()return true,'中英招已击败。武器归还，已采用的训练成果保留。'end,
 })
 local _,defaults=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true})
 battle.supplies=assert(require('Economy.CombatSession').virtual('disarm-practice:'..os.time()..':'..tostring(D.App.runningTime),loadout or defaults))
 for _,arena in ipairs(battle.learners)do arena.supplies=battle.supplies end
 if demonstrator then require('Training.DisarmDemonstration').attach(battle,demonstrator)end
 require('Training.DisarmTrace').attach(battle)
 if candidate then require('Training.DisarmTrial').attach(battle,candidate)end
 if useAdopted then require('Training.DisarmDeployment').attachAsync(battle,models)end
 return battle
end
local function statusText(b)
 local enemy=b.enemies[1];local hint=require('Combat.DisarmStatus').hint(b)
 local controls=b.demonstrator and ('示范'..b.demonstrator.character.name..'：摇杆/A、D移动 · J射击'..(b.demonstrator.character.legal.melee and ' · E刀击'or'')..' · F/R队伍施法')or '摇杆/A、D移动 · J射击 · F火焰 · R旋风'
 if b.trialCandidate then controls='候选#'..b.trialCandidate.id..'控制'..b.candidateArena.character.name..'；你控制导师 · J射击/F火焰/R旋风'end
 if b.adoptionStatus then controls=controls..' · '..b.adoptionStatus end
 local hits=b.demonstrator and b.demonstrator.metrics.hits or b.mentorHits
 return string.format('虚拟训练场 · 中英招缴械　敌人生命 %.0f / 360\n导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f\n%s\n命中：%s %d · 火焰 %d · 旋风 %d\n%s',enemy.enemyHP,b.mentorHP,b.arena.studentHP,b.wuyun.studentHP,controls,b.demonstrator and '示范学员'or'导师射击',hits,b.magic.fireHits,b.magic.windHits,hint)
end
local function openBattleAsync(onReturn,characterId,models,selection,demonstrator,candidate)
 return require('Factory.PatrolLevel').openAsync(models,function(_,_,action)
  if action=='again' then P.openAsync(onReturn,characterId,models,selection.values,demonstrator,candidate)
  else require('Training.Level')(onReturn,characterId)end
  return true
 end,{onSettledAsync=require('Training.DisarmPersistence').callback(),battleFactory=function(m)return P.createAsync(m,selection.loadout,demonstrator,candidate,not demonstrator and not candidate)end,music='Music/训练场.mp3',presentation={
  reportText=function(b)
   local stolen=0;for _,event in pairs(b.supplies.ledger.events)do if event.performer~=event.owner then stolen=stolen+event.cost end end
   return (b.adoptionStatus and (b.adoptionStatus..'\n')or '')..(b.trialCandidate and ('候选试战：'..b.candidateArena.character.name..' #'..b.trialCandidate.id..'\n')or '')..(b.demonstrator and ('亲自示范：'..b.demonstrator.character.name..'\n')or '')..string.format('导师命中 %d · 火焰 %d · 旋风 %d\n虚拟资源消耗 %d（含整备）；其中被夺武器消耗 %d\n本次演练不扣真实物资，未自动训练或采用新模型。',b.mentorHits,b.magic.fireHits,b.magic.windHits,b.supplies.ledger.spent,stolen)
  end,
  statusText=statusText,title='虚拟训练场 · 中英招缴械',start='开始演练',withdrawButton='结束演练',withdraw='已结束缴械演练。武器已归还。',
  ready='中英招会抢枪后射击，消耗原持有者的弹药。使用有限虚拟补给，不扣真实物资；被缴械后移动躲避，命中它可夺回武器。',
  playing='避开抢夺前摇。被缴械时保持机动，配合学员攻击以取回武器。',
  won='演练完成',failed='演练中止',baseText='返回基础训练',continueText='再次演练',saving='正在保存本轮演练记录…',saveFailure='本轮演练记录尚未保存，可重试保存。现在返回会放弃这份未保存的记录，旧训练成果不受影响。',unsavedBaseText='放弃并返回',
 }})
end
function P.openAsync(onReturn,characterId,models,values,demonstrator,candidate)
 D.Director.ui3D:removeAllChildren()
 local panel=require('UI.SupplyLoadout')({virtual=true,virtualMode=candidate and 'disarm-trial'or demonstrator and 'disarm-demo'or'disarm',values=values or require('Economy.Loadout').defaults(),formation={mentor=true,learner=true,wuyun=true},
  closed=function(confirmed,selection)
   D.thread(function()
    if confirmed then openBattleAsync(onReturn,characterId,models,selection,demonstrator,candidate)
    else require('Training.Level')(onReturn,characterId)end
   end)
  end})
 panel.tag='disarm-supply-loadout';panel:addTo(D.Director.ui3D);panel:alignLayout();return panel
end
return P
