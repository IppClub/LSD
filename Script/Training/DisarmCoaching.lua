-- Diagnostics use the exact accepted supervised samples, never model actions.
local C={}
function C.review(records,actor)
 local P=require('Training.DisarmPolicy');local data,why=P.inspect(records,actor);if not data then return nil,why end
 local r={actor=actor,samples=#data.samples,episodes=#data.sources,excluded=data.excluded,actions={},distance={},ammo={},bladeAmmo={},crossWeapon={lowEMPBlade=0,emptyEMPBlade=0,noEMPBlade=0,emptyBladeShot=0,noBladeShot=0},disarmed=0,armedEnemy=0,conflictingStates=0};local states={}
 for _,sample in ipairs(data.samples)do
  local s=sample.state;r.actions[sample.action]=(r.actions[sample.action]or 0)+1;r.distance[s.distance]=(r.distance[s.distance]or 0)+1
  r.ammo[s.empAmmo]=(r.ammo[s.empAmmo]or 0)+1
  r.bladeAmmo[s.bladeAmmo]=(r.bladeAmmo[s.bladeAmmo]or 0)+1
  if sample.action=='melee'then
   local key=({low='lowEMPBlade',empty='emptyEMPBlade',unequipped='noEMPBlade'})[s.empAmmo];if key then r.crossWeapon[key]=r.crossWeapon[key]+1 end
  elseif sample.action=='laser'then
   local key=({empty='emptyBladeShot',unequipped='noBladeShot'})[s.bladeAmmo];if key then r.crossWeapon[key]=r.crossWeapon[key]+1 end
  end
  if s.weapon=='disarmed'then r.disarmed=r.disarmed+1 end;if s.enemyArmed=='true'then r.armedEnemy=r.armedEnemy+1 end
  local key={};for _,name in ipairs(P.names)do key[#key+1]=s[name]end;key=table.concat(key,'|')
  local seen=states[key];if not seen then states[key]={action=sample.action}elseif seen.action~=sample.action and not seen.conflict then seen.conflict=true;r.conflictingStates=r.conflictingStates+1 end
 end
 return r
end
function C.load(actor)
 local Store=require('Training.DisarmStore');local ids,why=Store.listAsync();if not ids then return nil,why end
 local records={};for _,id in ipairs(ids)do local record,why=Store.loadAsync(id);if not record then return nil,why end;records[#records+1]=record end
 return C.review(records,actor)
end
function C.text(r)
 if not r then return '示范记录未通过读取核对，请先检查缴械复盘。'end
 local names={ninilite='妮妮莉特',wuyun='乌云'};local a=r.actions
 local lines={names[r.actor]..' · 最近20场中的亲自示范',string.format('有效动作 %d · 来源 %d 场 · 未完成等排除 %d',r.samples,r.episodes,r.excluded),string.format('射击 %d · 刀击 %d · 靠近 %d · 后退 %d · 等待 %d',a.laser or 0,a.melee or 0,a.fmove or 0,a.bmove or 0,a.idle or 0),string.format('近距 %d · 中距 %d · 远距 %d',r.distance.near or 0,r.distance.mid or 0,r.distance.far or 0),string.format('被缴械时 %d · 敌方持枪时 %d',r.disarmed,r.armedEnemy),string.format('EMP充足 %d · 少量 %d · 耗尽 %d · 未携带 %d',r.ammo.ready or 0,r.ammo.low or 0,r.ammo.empty or 0,r.ammo.unequipped or 0)}
 if r.actor=='wuyun'then
  local c=r.crossWeapon
  lines[#lines+1]=string.format('刀具充足 %d · 少量 %d · 耗尽 %d · 未携带 %d',r.bladeAmmo.ready or 0,r.bladeAmmo.low or 0,r.bladeAmmo.empty or 0,r.bladeAmmo.unequipped or 0)
  lines[#lines+1]=string.format('完整刀击：EMP少量时%d，耗尽时%d，未携带时%d',c.lowEMPBlade,c.emptyEMPBlade,c.noEMPBlade)
  lines[#lines+1]=string.format('完整射击：刀具耗尽时%d，未携带时%d',c.emptyBladeShot,c.noBladeShot)
 end
 lines[#lines+1]='';lines[#lines+1]='建议补练：'
 if r.samples<6 then lines[#lines+1]='完成至少6个有效动作、至少两种动作后再学习；攻击需实际出手并收招。'end
 if not a.laser then lines[#lines+1]='补充合适距离的完整射击，避免只学到移动和等待。'end
 if r.actor=='wuyun'and not a.melee then lines[#lines+1]='乌云可补充近距离刀击与退开的完整动作。'end
 if r.disarmed==0 then lines[#lines+1]='还没有武器被夺时的有效示范；练习移动避开敌方射击，取回后再攻击。'end
 if (r.ammo.ready or 0)+(r.ammo.low or 0)>0 and not r.ammo.empty then lines[#lines+1]=r.actor=='wuyun'and '可减少EMP，练习在合适距离改用仍有余量的刀具；不能攻击时再移动避让。'or '可在补给页减少EMP，练习少量或耗尽时的移动与等待。'end
 if r.actor=='wuyun'then
  local c=r.crossWeapon
  if c.lowEMPBlade==0 or c.emptyEMPBlade==0 then lines[#lines+1]='EMP不足时的刀击示范仍不完整，先确认距离、刀具余量和出手时机。'end
  if (r.bladeAmmo.ready or 0)+(r.bladeAmmo.low or 0)>0 and c.emptyBladeShot==0 then lines[#lines+1]='还没有刀具耗尽后改用EMP的完整射击示范，可减少刀具补练。'end
  if c.noEMPBlade==0 or c.noBladeShot==0 then lines[#lines+1]='若计划不携带某类武器，请先在相同配装下示范并对照，耗尽与未携带分别统计。'end
 end
 if r.conflictingStates>0 then lines[#lines+1]=string.format('%d组相同观察条件对应不同动作；检查复盘中的时机与距离，当前特征可能无法区分这些选择。',r.conflictingStates)end
 lines[#lines+1]='覆盖数量只说明示范范围，不代表动作正确或策略有效。补练后重新学习并对照胜负、成本和承伤；不会自动采用。'
 return table.concat(lines,'\n')
end
return C
