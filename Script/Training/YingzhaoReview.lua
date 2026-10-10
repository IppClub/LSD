-- Rebuild outcomes from validated observation archives, never infer hits from
-- intent, or label every zero-HP EMP shot as wasted ammunition.
local M={}
function M.rebuild(e)
 local ok,why=require('Enemy.BigYingzhaoEvidence').validateVirtual(e);if not ok then return nil,why end
 local r={schemaVersion=1,trainable=false,rows={},deployment=e.resources.quote.deployment,total=e.resources.spent,actionCost=0,demonstrator=e.demonstrator}
 for i,step in ipairs(e.boss.steps)do
  r.rows[i]={step=i,actor=step.actor,source=step.origin,action=step.action,skillStatus=step.skill and step.skill.status,released=step.skill and step.skill.releaseAt~=nil,arenaEdge=step.before.featureSchemaVersion>=4 and step.before.arenaEdge or 'unknown',waveCue=step.before.threat=='wave',waveReach=step.before.featureSchemaVersion>=3 and step.before.waveReach or 'unknown',targetBossSide=step.before.featureSchemaVersion>=2 and step.before.targetBossSide or 'unknown',duration=step.ended and math.max(0,step.ended-step.started)or 0,intent=step.aim and step.aim.intent,cost=0,units=0,hits=0,armor=0,health=0,parts={}}
 end
 for _,event in pairs(e.resources.events)do local row=r.rows[event.step];row.cost=row.cost+event.cost;row.units=row.units+event.count;r.actionCost=r.actionCost+event.cost end
 for _,hit in ipairs(e.boss.hits)do
  local row=hit.step and r.rows[hit.step]
  if row then
   row.hits=row.hits+1;row.armor=row.armor+(hit.armorDamage or 0);row.health=row.health+(hit.healthDamage or 0)
   local part=hit.summoned and 'summon'or hit.part;row.parts[part]=(row.parts[part]or 0)+1
  end
 end
 for _,row in ipairs(r.rows)do
  if row.action=='wind'or row.action=='fire'then
   row.outcome=not row.released and 'not-released'or row.hits==0 and'miss'or (row.armor>0 or row.health>0)and'effective'or'no-effect'
  elseif row.units>0 then
   row.outcome=row.hits==0 and 'miss'or (row.armor>0 or row.health>0)and 'effective'or'no-effect'
  else row.outcome='no-consumption'end
 end
 assert(r.actionCost+r.deployment==r.total,'Review must reconcile with the ledger')
 return r
end
local names={head='头部',torso='上身',flank='躯干',arms='手臂',forelegs='前腿',hindlegs='后腿',summon='援军'}
function M.text(r)
 local lines={string.format('示范复盘：整备 %d + 动作消耗 %d = %d',r.deployment,r.actionCost,r.total)}
 local movement={fmove={count=0,seconds=0},bmove={count=0,seconds=0},idle={count=0,seconds=0}}
 for _,row in ipairs(r.rows)do
  local item=movement[row.action]
  if item and row.actor==r.demonstrator and row.source=='demo'and (row.duration or 0)>=.15 then
   item.count=item.count+1;item.seconds=item.seconds+row.duration
  end
 end
 local count=movement.fmove.count+movement.bmove.count+movement.idle.count
 if count>0 then
  lines[#lines+1]=string.format('移动示范：前进 %d 段 / 后退 %d 段 / 停留 %d 段',movement.fmove.count,movement.bmove.count,movement.idle.count)
  lines[#lines+1]=string.format('持续时间：前进 %.1f秒 / 后退 %.1f秒 / 停留 %.1f秒',movement.fmove.seconds,movement.bmove.seconds,movement.idle.seconds)
  lines[#lines+1]='移动与停留也可用于学习；记录段数不等于合并后的学习样本数。'
 end
 local sides={same=0,opposite=0,overlap=0,unknown=0};local sideCount=0
 for _,row in ipairs(r.rows)do
  if row.actor==r.demonstrator and row.source=='demo'and ((movement[row.action]and (row.duration or 0)>=.15)or row.units>0)then
   local side=row.targetBossSide or 'unknown';sides[side]=sides[side]+1;sideCount=sideCount+1
  end
 end
 if sideCount>0 then
  lines[#lines+1]=string.format('方位记录：同侧 %d 段 / 夹击 %d 段 / 重合 %d 段 / 未知 %d 段',sides.same,sides.opposite,sides.overlap,sides.unknown)
  if sides.unknown>0 then lines[#lines+1]='旧资料或目标不可见时方位未知；补充当前战斗示范可以增加方位覆盖。'end
 end
 local waves={approaching=0,clear=0,unknown=0};local waveCount=0
 for _,row in ipairs(r.rows)do
  if row.actor==r.demonstrator and row.source=='demo'and row.waveCue and ((movement[row.action]and (row.duration or 0)>=.15)or row.units>0)then
   local reach=row.waveReach or'unknown';waves[reach]=waves[reach]+1;waveCount=waveCount+1
  end
 end
 if waveCount>0 then
  lines[#lines+1]=string.format('冲击波观察：可达 %d 段 / 范围外 %d 段 / 未知 %d 段',waves.approaching,waves.clear,waves.unknown)
  lines[#lines+1]='按动作开始时的观察统计；旧资料不推算当时的波前位置。'
 end
 local edges={left=0,right=0,none=0,unknown=0};local edgeCount=0
 for _,row in ipairs(r.rows)do
  if row.actor==r.demonstrator and row.source=='demo'and movement[row.action]and(row.duration or 0)>=.15 then
   local edge=row.arenaEdge or'unknown';edges[edge]=edges[edge]+1;edgeCount=edgeCount+1
  end
 end
 if edgeCount>0 then lines[#lines+1]=string.format('移动起点：左边界 %d 段 / 右边界 %d 段 / 场内 %d 段 / 未知 %d 段',edges.left,edges.right,edges.none,edges.unknown)end
 local displayed,total=0,0
 for _,row in ipairs(r.rows)do if row.actor==r.demonstrator and row.source=='demo'and (row.action=='shoot'or row.action=='melee'or row.action=='wind'or row.action=='fire')then
  total=total+1
  if displayed<30 then
   displayed=displayed+1;local hitParts={};for part in pairs(row.parts)do hitParts[#hitParts+1]=names[part]or part end;table.sort(hitParts)
   local outcome=row.outcome=='not-released'and'未释放'or row.outcome=='miss'and'未命中'or row.outcome=='no-effect'and'命中但未造成破甲或伤害'or row.outcome=='no-consumption'and'未消耗补给'or table.concat(hitParts,'、')
   lines[#lines+1]=string.format('#%d %s → %s；破甲 %.0f / 伤害 %.1f / 消耗 %d',row.step,names[row.intent]or(row.action=='wind'and'旋风'or row.action=='fire'and'火焰'or row.action=='melee'and'刀击'or'射击')..(row.skillStatus=='cancelled'and'（中断）'or''),outcome,row.armor,row.health,row.cost)
  end
 end end
 if total==0 then lines[#lines+1]='本轮没有学员攻击示范。'elseif total>displayed then lines[#lines+1]=string.format('另有 %d 条攻击保留在记录中。',total-displayed)end
 lines[#lines+1]='目标选择与实际命中分别记录；破甲有效的EMP不计为无效射击。'
 return table.concat(lines,'\n')
end
return M
