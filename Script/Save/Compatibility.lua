-- Read-only gate before any story service can create tables or migrate data.
local D=require('Dora');local C={}
local supported={Game0StoryMeta=1,Game0MissionMeta=1,Game0FoxMeta=1,Game0ValleyMeta=1,
 Game0InfiltrationMeta=1,Game0InfiltrationPath=1,Game0Researcher=1,Game0SecondPatrol=1,
 Game0ControlPod=1,Game0Roof=1,Game0RoofDuel=1,Game0AuxiliarySelection=1,Game0EndingViews=1}
function C.check(alias)
 assert(alias=='lsd'or alias=='restore_source')
 local ok,value,why=pcall(function()
  local tables=D.DB:query("SELECT name FROM "..alias..".sqlite_master WHERE type='table' AND name LIKE 'Game0%'")
  if not tables then return nil,'SAVE_UNREADABLE'end
  for _,row in ipairs(tables)do
   local name=row[1];local quoted='"'..name:gsub('"','""')..'"'
   local columns=D.DB:query('PRAGMA '..alias..'.table_info('..quoted..')');if not columns then return nil,'SAVE_UNREADABLE'end
   local versioned=false;for _,column in ipairs(columns)do if column[2]=='schemaVersion'then versioned=true end end
   if supported[name]and not versioned then return nil,'SAVE_SCHEMA_UNSUPPORTED'end
   if versioned then
    if not supported[name]then return nil,'SAVE_NEWER_VERSION'end
    local versions=D.DB:query('SELECT schemaVersion FROM '..alias..'.'..quoted)
    if not versions then return nil,'SAVE_UNREADABLE'end
    for _,version in ipairs(versions)do
     if type(version[1])~='number'or version[1]~=supported[name]then
      return nil,type(version[1])=='number'and version[1]>supported[name]and 'SAVE_NEWER_VERSION'or'SAVE_SCHEMA_UNSUPPORTED'
     end
    end
   end
  end
  return true
 end)
 if not ok then return nil,'SAVE_UNREADABLE'end
 return value,why
end
return C
