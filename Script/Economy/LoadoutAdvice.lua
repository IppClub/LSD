-- Inform the player without changing their quantities or preventing a risky loadout.
local M={}
function M.bossDetails(values,formation)
 local kinetic=values['mentor:kinetic']or 0
 local emp=(formation.learner and(values['ninilite:emp']or 0)or 0)+(formation.wuyun and(values['wuyun:emp']or 0)or 0)
 local blade=formation.wuyun and(values['wuyun:blade']or 0)or 0
 local rows={'当前携带（只计已编入成员）',string.format('导师实弹 %d · 学员EMP %d · 乌云近战能量 %d',kinetic,emp,blade),'',
 '武器分工','实弹造成生命伤害；EMP用于破甲，不造成生命伤害；乌云近战兼具破甲与生命伤害。',
 '大英招各部位护甲独立。瞄准正确部位，破甲后再用实弹或近战输出；头部破甲后更脆弱。',
 '援军没有护甲，EMP直接命中不会造成生命伤害。可用实弹、乌云近战或火焰/旋风应对；技能有冷却，不能连续代替弹药。','',
 '当前配置检查'}
 if kinetic==0 and blade==0 and not formation.learner and not formation.wuyun then rows[#rows+1]='未配能够直接造成生命伤害的补给，请检查编队和携带量。'
 elseif kinetic==0 and blade==0 then rows[#rows+1]='未携带实弹与近战能量，生命伤害需依靠技能；EMP不能替代输出。'
 elseif kinetic==0 then rows[#rows+1]='未携带导师实弹，清理援军与破甲后的输出更依赖乌云近战和技能。'
 elseif blade==0 then rows[#rows+1]='没有可用的乌云近战补给，贴身掩护更依赖实弹和技能。'
 else rows[#rows+1]='已携带实弹与近战补给；请为援军留出消耗余量。'end
 if kinetic>0 then
  local rules=require('Enemy.BigYingzhaoRules')
  local damage=kinetic*require('Combat.WeaponProfiles').mentor.healthDamage*rules.headMultiplier
  rows[#rows+1]=string.format('当前实弹理论伤害上限 %g，Boss生命 %d（每发都命中已破甲头部，未扣援军消耗）。',damage,rules.maxHP)
  rows[#rows+1]=damage<rules.maxHP and '仅靠这些实弹无法击败Boss；需要队友近战/技能输出，或增加实弹，并留出脱靶与清援余量。'or '这个上限不代表实际输出；护甲、脱靶与清理援军都会消耗弹药，仍需队友配合。'
 end
 if emp==0 then rows[#rows+1]=blade>0 and'未携带学员EMP，部位破甲更依赖乌云近战。'or'未携带学员EMP和乌云近战能量，缺少这两类主要破甲手段。'end
 rows[#rows+1]='';rows[#rows+1]='成本与结算'
 rows[#rows+1]='携带量只是上限：按实际消耗加整备费结算，未使用额度退回。成功也可能亏损；技能冷却、命中率和援军数量都会影响成本。'
 rows[#rows+1]='这些提示不保证通关，也不会自动修改你的携带数量。'
 return table.concat(rows,'\n')
end
function M.text(mission,values,formation)
 if mission=='c0-m06'then
  local hint='引开追兵：射击和火光各需命中一次，使用烟雾，护送四人后沿光路到右侧出口。烟雾隔在你与追兵之间可遮断追踪，火光只打断命中的目标；给后半段留烟雾，不必击杀全部敌人。未用补给退回。'
  if (values['mentor:kinetic']or 0)==0 or (values['mentor:smoke']or 0)==0 or (values['mentor:flare']or 0)==0 then return hint..'当前缺少任务所需的实弹、烟雾或火光，请检查携带量。'end
  return hint
 end
 if mission=='c0-m05'then
  return '花妖部位需要分别破甲；EMP只削甲，实弹与乌云近战伤害生命。Boss倒下后仍须清除召唤花妖，请为清场保留输出补给；吟唱会暂缓乌云攻击。'
 end
 if mission=='c0-m03' then
  if not formation.learner or not formation.wuyun then return '两侧学员都需命中，请将妮妮莉特和乌云同时编入队伍。未用补给退回，失败无报酬。'end
  local missing={}
  if (values['ninilite:emp']or 0)==0 then missing[#missing+1]='妮妮EMP'end
  if (values['wuyun:emp']or 0)==0 and (values['wuyun:blade']or 0)==0 then missing[#missing+1]='乌云EMP/近战'end
  if (values['mentor:kinetic']or 0)==0 then missing[#missing+1]='导师实弹'end
  if #missing>0 then return '两侧学员都需命中。未带：'..table.concat(missing,'、')..'。技能有冷却，耗尽后可能超时亏损。'end
  return '两侧学员都需命中并清除全部敌人；风火有冷却，石柱可挡击。未用补给退回，耗尽后可能超时亏损。'
 end
 if mission=='c0-yingzhao'then return '大英招各部位分别破甲：EMP破甲，实弹输出；头部破甲后更脆弱。留出清理援军的弹药，未用补给退回；高成本获胜仍可能亏损。'end
 if mission=='c0-disarm'then
  local hint='抢枪消耗原持有者弹药；未用补给退回，成本为实际消耗加整备。'
  if formation.wuyun and (values['wuyun:blade']or 0)==0 then return hint..'乌云未配近战能量，请留意缴械后的应对。'end
  local guns=(values['mentor:kinetic']or 0)+(formation.learner and (values['ninilite:emp']or 0)or 0)+(formation.wuyun and (values['wuyun:emp']or 0)or 0)
  if guns<=3 and (not formation.wuyun or (values['wuyun:blade']or 0)<=1)then return hint..'补给很少，可能延长交战并增加承伤。'end
  return hint
 end
 if mission~='c0-m01' then return nil end
 local task=require('Mission.Catalog')[mission]
 if not formation.learner then return '本任务需要妮妮莉特出战，并完成每波的命中要求。'end
 local count=values['ninilite:emp'] or 0
 local target=task.learnerHitsPerWave*#task.waves
 local requirement=string.format('任务要求：%d波各至少%d次学员命中；',#task.waves,task.learnerHitsPerWave)
 if count==0 then return requirement..'未携带学员EMP，请检查补给。'end
 if count<target then return requirement..string.format('当前EMP仅%d发，可能不足。',count)end
 return requirement..string.format('当前EMP %d发，请预留脱靶余量。',count)
end
return M
