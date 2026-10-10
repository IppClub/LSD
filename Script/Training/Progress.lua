local Store=require("Training.Store")
local Characters=require("Training.Characters")
local function profile(characterId)
 local p={characterId=characterId}
 function p.load()
  local store,err=Store.open(nil,characterId); p.store=store; p.adopted,p.previous=nil,nil
  if not store then return false,err end
  local saved,status=store:load()
  if saved then p.adopted,p.previous=saved.adopted,saved.previous end
  if store.writeBlocked then p.status="INCOMPATIBLE_SAVE_READ_ONLY"; return false,p.status end
  p.status=status; return status=="LOADED" or status=="NEW_PROFILE" or status=="RECOVERED_BACKUP",status
 end
 function p.saveAsync(adopted,previous,trace)
  if not p.store then return false,"NO_GAME_DATABASE" end
  local ok,err=p.store:saveAsync(adopted,previous,trace); if ok then p.adopted,p.previous=adopted,previous end; return ok,err
 end
 return p
end
local Progress=profile("ninilite")
local profiles={ninilite=Progress}
function Progress.forCharacter(id)
 assert(Characters[id],"Unknown learner "..tostring(id))
 if not profiles[id] then profiles[id]=profile(id) end
 return profiles[id]
end
return Progress
