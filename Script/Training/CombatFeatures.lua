-- Observable categorical features shared by recording and inference.
local F={names={'enemyKind','armorState','observedPart','healthBand','energyReady'}}
F.categories={enemyKind={unknown=true,taotie=true,shanxiao=true,flower=true,fox=true,yingzhao=true},
 armorState={unknown=true,intact=true,broken=true,unarmored=true},
 observedPart={unknown=true,whole=true,head=true,gem=true,back=true,leg=true,tail=true},
 healthBand={unknown=true,healthy=true,low=true},energyReady={unknown=true,yes=true,no=true,unlimited=true}}
function F.value(state,name)if state[name]==nil then return 'unknown'end;return state[name]end
function F.validate(state)
 for _,name in ipairs(F.names)do if not F.categories[name][F.value(state,name)]then return false,'INVALID_'..name end end
 return true
end
function F.enemyKind(asset)
 for pattern,kind in pairs({taotie='taotie',shanxiao='shanxiao',huayao='flower',huli='fox',yingzhao='yingzhao'})do if asset:find(pattern,1,true)then return kind end end
 return 'unknown'
end
function F.part(raw)
 if raw=='head-gem'then return 'gem' elseif raw and raw:find('back',1,true)then return 'back' elseif raw and raw:find('leg',1,true)then return 'leg' end
 return raw or 'unknown'
end
return F
