-- Prepare the same mission-result artwork and font glyphs before combat.
local D=require('Dora')
local Text=require('Factory.BattleText')
local Result={}
local title='废弃工厂 · 沼泽花妖'
local winTitle,loseTitle='沼泽道路已清理','调查中止'
local incomplete='有%d个行动未完成，保留已发生的结果，不计为落空。\n'
local winStory='沿道路向右到材料点。采集后打开通讯，点击通知医师。'
local loseStory='采用模型保留；返回列车检查队伍，再来调查。'
function Result.prepareAsync()
 -- Loading the actual component here avoids module work at the transition.
 require('UI.Settlement')
 D.Cache:loadAsync({'ar.clip','button.clip'})
 local names={'mentor','ninilite','wuyun'};local actors={}
 for _,actor in ipairs(names)do actors[actor]={health=0,armor=0,assistedHealth=0,damageTaken=0,friendlyDamage=0}end
 local report=require('Training.FlowerEvaluation').text({actors=actors})..'0123456789'
 local story=winStory..loseStory..string.format(incomplete,1234567890)..Text.defeat..Text.timeout..Text.victory..Text.incomplete..Text.withdraw
 for _,entry in ipairs({{140,winTitle..loseTitle},{42,report..story},{36,report..story},{38,'资源账单尚未接入，本场未启用行动物资扣费'},{55,title..'[主线]完成失败再次行动返回基地'}})do
  local label=assert(D.Label('SourceHanSansCN-Regular',entry[1]));label.text=entry[2];label:cleanup()
  D.sleep(0)
 end
end
function Result.create(b)
 local won=b.phase=='won';local evaluation=b.report.evaluation
 local remaining=b.report.remainingEnemies or {};local rows={}
 for _,enemy in ipairs(remaining)do
  rows[#rows+1]=string.format('%s：生命 %.0f/%.0f',enemy.summoned and '召唤花妖' or '花妖',enemy.hp,enemy.maxHP)
 end
 local unfinished=#rows>0 and '\n尚未清除：'..table.concat(rows,'；')or ''
 return require('UI.Settlement')({missionMode=true,economy=b.report.economy,missionTitle=title,resultTitle=won and winTitle or loseTitle,resultStatus=won and 'Complete' or 'Failed',
  reportText=require('Training.FlowerEvaluation').text(evaluation),storyY=-170,
  storyText=b.reason..'\n'..((evaluation and evaluation.incompleteActions>0)and string.format(incomplete,evaluation.incompleteActions)or '')..(won and winStory or loseStory)..unfinished})
end
return Result
