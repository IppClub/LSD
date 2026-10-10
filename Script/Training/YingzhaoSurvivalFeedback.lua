-- Display-only accounting from validated, closed vitality traces.
-- Never infer an attacking enemy from a shared skill name or change a policy.
local M={};local actors={'mentor','ninilite','wuyun'}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function near(a,b)return finite(a) and finite(b) and math.abs(a-b)<=1e-6 end
function M.summarize(v)
 if not v then return nil,'NOT_RECORDED' end
 if not require('Training.YingzhaoVitals').validate(v) then return nil,'INVALID_VITALS' end
 local result={};local current={}
 for _,id in ipairs(actors) do
  local first,last=v.initial[id],v.final[id]
  if not finite(first) or not finite(last) or first<0 or first>100 or last<0 or last>100 then return nil,'INVALID_HP' end
  current[id]=first;result[id]={initial=first,final=last,meleeDamage=0,projectileDamage=0,waveDamage=0,supportHazardDamage=0,otherDamage=0,healing=0,skills={}}
 end
 for _,e in ipairs(v.events) do
  local r=result[e.actor];local healing=e.healing or 0
  if not r or not near(current[e.actor],e.before) or not finite(e.after) or e.after<0 or e.after>100 or not finite(e.damage) or e.damage<0 or not finite(healing) or healing<0 or not near(e.after,e.before-e.damage+healing) then return nil,'EVENT_MISMATCH' end
  if not near(e.damage,math.max(0,e.before-e.after)) or not near(healing,math.max(0,e.after-e.before)) then return nil,'DELTA_MISMATCH' end
  if healing>0 and (v.schemaVersion~=2 or e.kind~='support-heal' or e.skill~='life-support') then return nil,'INVALID_HEALING' end
  current[e.actor]=e.after;r.healing=r.healing+healing
  local field=e.kind=='enemy-melee' and 'meleeDamage' or e.kind=='enemy-projectile' and 'projectileDamage' or e.kind=='enemy-wave' and 'waveDamage' or e.kind=='support-hazard' and 'supportHazardDamage' or 'otherDamage'
  r[field]=r[field]+e.damage
  if e.damage>0 and e.kind~='support-hazard' then local skill=e.skill or 'unknown';r.skills[skill]=(r.skills[skill] or 0)+e.damage end
 end
 for _,id in ipairs(actors) do if not near(current[id],result[id].final) then return nil,'FINAL_HP_MISMATCH' end end
 return result
end
function M.text(v)
 local r,why=M.summarize(v);if not r then return why=='NOT_RECORDED' and '历史记录未保存生命变化。' or '生命记录不完整，暂不显示分类复盘。' end
 local names={mentor='导师',ninilite='妮妮莉特',wuyun='乌云'};local rows={'生命复盘（来自实际生命变化）'}
 for _,id in ipairs(actors) do
  local a=r[id]
  rows[#rows+1]=string.format('%s：%.1f → %.1f · 回血 %.1f\n近战承伤 %.1f / 射弹承伤 %.1f / 冲击波承伤 %.1f\n支援失效承伤 %.1f / 其他 %.1f',names[id],a.initial,a.final,a.healing,a.meleeDamage,a.projectileDamage,a.waveDamage,a.supportHazardDamage,a.otherDamage)
  if a.final==0 then rows[#rows+1]=names[id]..'已倒下。' end
 end
 local energy=false;for _,a in pairs(r) do if a.supportHazardDamage>0 then energy=true end end
 if energy then rows[#rows+1]='本局出现支援失效承伤；检查辅助机金粉与保护范围，再调整任务时长和队伍间距。' end
 rows[#rows+1]='同名技能可能来自不同敌人，不能仅凭技能名认定攻击者或失败原因。'
 return table.concat(rows,'\n')
end
return M
