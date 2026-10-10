-- Separate combat facts from authored story requirements; never infer old outcomes.
local M={version=1}
function M.capture(b)
 local enemiesRemaining=0
 for _,e in ipairs(b.enemies)do if e.enemyHP>0 and not e.enemyCombat.dead then enemiesRemaining=enemiesRemaining+1 end end
 local cleared=0
 for _,log in ipairs(b.song.logs)do cleared=cleared+(log.cleared or 0)end
 return {version=M.version,enemiesRemaining=enemiesRemaining,partyAlive=b.mentorHP>0 and b.arena.studentHP>0 and b.wuyun.studentHP>0,
  niniliteHit=b.arena.metrics.hits>0,wuyunHit=b.wuyun.metrics.hits>0,confusionCleared=cleared>0,injury=b.injury and true or false}
end
function M.valid(o)
 if type(o)~='table' or o.version~=1 or type(o.enemiesRemaining)~='number' or o.enemiesRemaining<0 or o.enemiesRemaining>=math.huge or o.enemiesRemaining%1~=0 then return false end
 for _,key in ipairs({'partyAlive','niniliteHit','wuyunHit','confusionCleared','injury'})do if type(o[key])~='boolean'then return false end end
 return true
end
function M.storyComplete(o)return o.niniliteHit and o.wuyunHit and o.confusionCleared and o.injury end
function M.satisfied(o,goal)
 if not M.valid(o) or o.enemiesRemaining~=0 or not o.partyAlive then return false end
 if goal=='resource-clear-v1' then return true end
 return goal==nil and M.storyComplete(o)
end
function M.validGoal(setup,episode,resource)
 local goal=setup and setup.trainingGoal
 return goal==episode.versions.trainingGoal and (goal==nil or goal=='resource-clear-v1' and resource and episode.resources and episode.resources.mode=='virtual' and episode.versions.outcome==1 and M.valid(episode.outcome))
end
function M.validMovement(setup,episode)
 if type(setup)~='table' or type(episode)~='table' or type(episode.versions)~='table' then return false end
 local v=setup.continuousMovement
 return v==episode.versions.continuousMovement and (v==nil or v==1 and setup.trainingGoal=='resource-clear-v1' and episode.resources and episode.resources.mode=='virtual')
end
function M.missing(o)
 local missing={}
 for _,item in ipairs({{'niniliteHit','妮妮莉特尚未命中'},{'wuyunHit','乌云尚未命中'},{'confusionCleared','尚未用歌谣解除蛊惑'},{'injury','尚未触发藤蔓剧情'}})do
  if not o[item[1]]then missing[#missing+1]=item[2]end
 end
 return missing
end
function M.text(o)
 if not M.valid(o)then return '旧记录未保存战斗与剧情分项结果。'end
 return string.format('战斗清场：%s · 队伍存活：%s · 剧情条件：%s',o.enemiesRemaining==0 and '是' or '否',o.partyAlive and '是' or '否',M.storyComplete(o)and '完成' or '未完成')
end
return M
