local D=require('Dora');local L=require('Economy.Ledger');local M={}
M.slots={
 {actor='mentor',item='kinetic',name='导师 · 实弹手枪',art='kinetic-pistol',crate='crate-kinetic-small',default=40},
 {actor='ninilite',item='emp',name='妮妮莉特 · EMP手枪',art='emp-pistol',crate='crate-emp-small',default=36},
 {actor='wuyun',item='emp',name='乌云 · EMP手枪',art='emp-pistol',crate='crate-emp-small',default=6},
 {actor='wuyun',item='blade',name='乌云 · 近战能量',art='equipment-blade',default=36}}
M.tools={
 {actor='mentor',item='smoke',name='导师 · 烟雾投掷物',art='crate-unknown-small',default=2,optional=true},
 {actor='mentor',item='flare',name='导师 · 火光投掷物',art='crate-unknown-small',default=2,optional=true}}
function M.displaySlots(mission)
 if mission=='c0-m06'then return {M.slots[1],M.tools[1],M.tools[2]}end
 return M.slots
end
function M.defaults()
 local values={};for _,slot in ipairs(M.slots)do values[slot.actor..':'..slot.item]=slot.default end;for _,slot in ipairs(M.tools)do values[slot.actor..':'..slot.item]=slot.default end;return values
end
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0SupplyLoadout(id INTEGER PRIMARY KEY CHECK(id=1),version INTEGER NOT NULL CHECK(version=1),payload TEXT NOT NULL)')>=0
end
function M.validate(values)
 if type(values)~='table'then return false end
 for key,value in pairs(values)do
  local found=false;for _,slot in ipairs(M.slots)do if key==slot.actor..':'..slot.item then found=true end end
  for _,slot in ipairs(M.tools)do if key==slot.actor..':'..slot.item then found=true end end
  if not found or type(value)~='number' or value%1~=0 or value<0 or value>200 then return false end
 end
 for _,slot in ipairs(M.slots)do if not values[slot.actor..':'..slot.item]then return false end end
 return true
end
function M.load()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT version,payload FROM lsd.Game0SupplyLoadout WHERE id=1');if not rows then return nil,'READ_FAILED'end
 if rows[1]then
  local ok,values=pcall(D.json.decode,rows[1][2],32)
  if rows[1][1]~=1 or not ok or not M.validate(values)then return nil,'INVALID_LOADOUT_SAVE'end
  for _,slot in ipairs(M.tools)do local key=slot.actor..':'..slot.item;if values[key]==nil then values[key]=slot.default end end
  return values
 end
 return M.defaults()
end
function M.quote(values,formation,mission)
 if not M.validate(values)then return nil,'INVALID_LOADOUT'end
 local lines={}
 for _,slot in ipairs(M.displaySlots(mission))do
  if slot.actor=='mentor' or slot.actor=='ninilite' and formation.learner or slot.actor=='wuyun' and formation.wuyun then
   local amount=values[slot.actor..':'..slot.item] or slot.default
   if amount>0 then lines[#lines+1]={actor=slot.actor,item=slot.item,quantity=amount}end
  end
 end
 local quote,why=L.quote(lines);if not quote then return nil,why end
 return quote,lines
end
function M.saveAsync(values)
 if not M.validate(values)then return nil,'INVALID_LOADOUT'end
 if not open()then return nil,'WRITE_FAILED'end
 return D.DB:transactionAsync({{'INSERT OR REPLACE INTO lsd.Game0SupplyLoadout VALUES(1,1,?)',{{D.json.encode(values,false,true)}}}})
end
-- Task reward stays in the task profile, never in user-editable quantities.
function M.forMission(mission,formation)
 if mission~='c0-roof' and mission~='c0-researcher' and mission~='c0-patrol-second' and mission~='c0-patrol' and mission~='c0-yingzhao' and mission~='c0-disarm' and mission~='c0-m05' and mission~='c0-m01' and mission~='c0-m02' and mission~='c0-m03' and mission~='c0-m06' and mission~='c0-m07' and mission~='c0-m08' and mission~='c0-m09' then return nil,'UNSUPPORTED_ECONOMY_MISSION'end
 if mission=='c0-m06'then formation={mentor=true}
 elseif mission=='c0-roof' or mission=='c0-patrol-second' or mission=='c0-m01' or mission=='c0-m02' or mission=='c0-m07' or mission=='c0-m08' or mission=='c0-m09'then formation={mentor=true,learner=formation.learner}end
 local values,why=M.load();if not values then return nil,why end
 local quote,lines=M.quote(values,formation,mission);if not quote then return nil,lines end
 return {loadout=lines,reward=100,quote=quote}
end
return M
