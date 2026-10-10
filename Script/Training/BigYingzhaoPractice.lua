local D=require('Dora');local P={}
function P.createAsync(models,loadout,characterId)
 assert(characterId=='ninilite'or characterId=='wuyun','Unknown demonstrator')
 local supplies=assert(require('Economy.CombatSession').virtual('big-yingzhao-demo:'..os.time()..':'..tostring(D.App.runningTime),loadout))
 local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true,physicalSupport=true})
 require('Training.YingzhaoDemonstration').attach(b,characterId)
 return b
end
function P.openBattleAsync(models,loadout,characterId,onResult)
 local battle,snapshot
 return require('Factory.PatrolLevel').openAsync(models,onResult,{onSettledAsync=function()
  if not snapshot then
   local resources=battle.supplies:evidence();battle.bossTrace.resources=resources
   snapshot=D.json.decode(D.json.encode({schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=characterId,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=battle.bossTrace}),32)
  end
  battle.demonstrationReview=assert(require('Training.YingzhaoReview').rebuild(snapshot))
  local ok,why,id=require('Training.YingzhaoStore').saveAsync(snapshot);battle.demonstrationSourceId=id;return ok,why
 end,battleFactory=function(m)battle=P.createAsync(m,loadout,characterId);return battle end,music='Music/训练场.mp3',presentation={
  fitHeader=true,frameCamera=function(b,c)require('Enemy.BigYingzhaoCamera').attach(b,c)end,title='虚拟训练场 · 大英招部位示范',start='开始示范',withdrawButton='结束示范',withdraw='大英招示范已结束。',won='演练完成',failed='演练中止',baseText='返回训练',continueText='再次示范',saving='正在保存示范记录…',saveFailure='示范记录尚未保存，请重试；返回将放弃本轮记录。',unsavedBaseText='放弃并返回',
  supplyText=function(text)return text:gsub('虚拟补给（不扣物资）','虚拟补给'):gsub('妮妮莉特EMP','妮EMP'):gsub('乌云EMP','乌EMP'):gsub('乌云近战','乌近战'):gsub('已用成本','消耗')end,
  statusText=function(b)
   local target=({head='头部',torso='上身',flank='躯干',arms='手臂',forelegs='前腿',hindlegs='后腿',summon='援军'})[b.demonstrationTarget]
   local text
   if b.phase=='playing'then
    text=string.format('部位示范 · %s · 目标%s · Boss %.0f / 1000',b.demonstrator.character.name,target,b.enemies[1].enemyHP)
   else
    text=string.format('大英招部位示范 · %s\n摇杆/A、D移动 · 点击部位后J射击 · F/R队伍施法\n目标：%s · 大英招生命 %.0f / 1000\n虚拟补给；结束后保存观察，不自动训练或采用。',b.demonstrator.character.name,target,b.enemies[1].enemyHP)
   end
   if b.demonstrationFeedback then
    text=text..'\n'..(({PART_UNREACHABLE='当前角度、距离或遮挡不允许命中该部位。',BOSS_HIDDEN='目标暂不可见。',NO_VISIBLE_SUMMON='没有可见援军。',ACTION_UNAVAILABLE='当前动作或补给不允许射击。'})[b.demonstrationFeedback]or'暂时无法射击，请等待当前动作结束并检查补给。')
   end
   if b.phase=='playing'then
    local warning=require('Ground.BigYingzhaoLevel').supportWarningText(b)
    if warning~=''then text=text..'\n'..warning end
   end
   return text
  end,
  reportText=function(b)return (b.demonstrationReview and (require('Training.YingzhaoReview').text(b.demonstrationReview)..'\n')or'')..'未扣真实资源；示范观察独立保存，未自动训练或采用。'end,
 }})
end
function P.openAsync(onReturn,characterId,models,values)
 D.Director.ui3D:removeAllChildren()
 local panel=require('UI.SupplyLoadout')({virtual=true,virtualMode='big-yingzhao-demo',values=values or require('Economy.Loadout').defaults(),formation={mentor=true,learner=true,wuyun=true},closed=function(confirmed,selection)
  D.thread(function()
   if not confirmed then require('Training.Level')(onReturn,characterId);return end
   P.openBattleAsync(models,selection.loadout,characterId,function(_,_,action)
    if action=='again'then P.openAsync(onReturn,characterId,models,selection.values)else require('Training.Level')(onReturn,characterId)end
    return true
   end)
  end)
 end})
 panel.tag='big-yingzhao-supply-loadout';panel:addTo(D.Director.ui3D);panel:alignLayout();return panel
end
return P
