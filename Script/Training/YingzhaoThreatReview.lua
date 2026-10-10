-- Damage evidence only; simultaneous timestamps do not prove a shared attacker.
local M={}
local names={mentor='导师',ninilite='妮妮莉特',wuyun='乌云'}
local skills={punch='拳击',massive='连斩',wave='冲击波',jump='跃击',kick='踢击',hero='连续技'}
function M.build(trace)
 if not trace or not trace.vitals then return nil end
 local r={damage={},groups={},windCooldownHits=0,windCooldownDamage=0};local events={}
 for _,e in ipairs(trace.vitals.events or {})do
  if (e.damage or 0)>0 then
   local key=e.skill or e.kind or 'unknown';local row=r.damage[key]or{skill=key,total=0,actors={}};r.damage[key]=row
   row.total=row.total+e.damage;row.actors[e.actor]=(row.actors[e.actor]or 0)+e.damage;events[#events+1]=e
   if e.actor=='wuyun'then
    local cooldown=false
    for _,s in ipairs(trace.steps or {})do
     local cast=s.skill
     if s.actor=='wuyun'and s.action=='wind'and cast and cast.startedAt and cast.cooldownUntil and e.at>=cast.startedAt and e.at<cast.cooldownUntil then cooldown=true;break end
    end
    if cooldown then r.windCooldownHits=r.windCooldownHits+1;r.windCooldownDamage=r.windCooldownDamage+e.damage end
   end
  end
 end
 table.sort(events,function(a,b)return a.at<b.at end)
 local current
 for _,e in ipairs(events)do
  if not current or e.at-current.at>.02 then current={at=e.at,actors={},count=0,damage=0};r.groups[#r.groups+1]=current end
  if not current.actors[e.actor]then current.count=current.count+1;current.actors[e.actor]=true end
  current.damage=current.damage+e.damage
 end
 local groups={};for _,g in ipairs(r.groups)do if g.count>1 then groups[#groups+1]=g end end;r.groups=groups
 local sorted={};for _,row in pairs(r.damage)do sorted[#sorted+1]=row end;table.sort(sorted,function(a,b)if a.total~=b.total then return a.total>b.total end;return a.skill<b.skill end);r.damage=sorted
 return r
end
function M.text(trace)
 local r=M.build(trace);if not r then return '此历史记录缺少受击明细，无法分析队伍受击。'end
 local lines={'队伍受击复盘'}
 for i=1,math.min(3,#r.damage)do
  local row=r.damage[i];local actors={};for _,id in ipairs({'mentor','ninilite','wuyun'})do if row.actors[id]then actors[#actors+1]=names[id]..' '..string.format('%.0f',row.actors[id])end end
  lines[#lines+1]=string.format('%s：合计 %.0f（%s）',skills[row.skill]or row.skill,row.total,table.concat(actors,'、'))
 end
 for _,row in ipairs(r.damage)do
  if row.skill=='punch'then lines[#lines+1]='拳击补练：在前摇阶段提前后退，并给身后留出退路；临近命中才反制可能先受伤。'
  elseif row.skill=='massive'then lines[#lines+1]='连斩补练：它会向前追进，贴身时仅靠后退未必能躲开；提前拉开距离，避免被逼到边界。'end
 end
 lines[#lines+1]=string.format('同一时刻多人受击 %d 次。',#r.groups)
 if #r.groups>0 then lines[#lines+1]='补练方向：技能预警时拉开站位，避免一起被逼到边界。'end
 if r.windCooldownHits>0 then
  lines[#lines+1]=string.format('风技能冷却期间，乌云受击 %d 次，损失 %.0f 生命。',r.windCooldownHits,r.windCooldownDamage)
  lines[#lines+1]='补练方向：冷却期间的移动、掩护与反制衔接。'
 end
 return table.concat(lines,'\n')
end
return M
