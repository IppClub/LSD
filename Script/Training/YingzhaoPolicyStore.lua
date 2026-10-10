-- Candidate history only. Never writes an adopted model or mission progress.
local D=require('Dora');local P=require('Training.YingzhaoPolicy');local S={};local busy=false
local function open()return D.DB:existDB('lsd')and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0YingzhaoCandidates(id INTEGER PRIMARY KEY AUTOINCREMENT,actor TEXT NOT NULL,identity TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0 end
function S.learnAsync(actor,selection)
 if busy then return nil,'BUSY'end;busy=true
 local ok,result,why=xpcall(function()
  if actor~='ninilite'and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
  if selection~=nil and selection~='all'and selection~='latest'then return nil,'INVALID_SOURCE_SELECTION'end
  local archive=require('Training.YingzhaoStore');local ids,why=archive.listAsync(actor);if not ids then return nil,why end
  -- A correction session can stand on its own without deleting old evidence.
  -- Insufficient recent samples fail explicitly; never silently merge history.
  if selection=='latest'and #ids>0 then ids={ids[1]}end
  local records={}
  for _,id in ipairs(ids)do local r,why=archive.loadAsync(id);if not r then return nil,why end;records[#records+1]=r end
  local model,why=P.buildAsync(records,actor);if not model then return nil,why end
  local used={};for _,episode in ipairs(model.sourceEpisodes)do used[episode]=true end
  local sources={};for _,r in ipairs(records)do if used[r.episode]then sources[#sources+1]=r end end
  local payload=D.json.encode({schemaVersion=1,model=model,records=sources},false,true)
  if #payload>16*1024*1024 then return nil,'SOURCE_TOO_LARGE'end
  if not open()then return nil,'WRITE_FAILED'end
  local identity=actor..':'..os.time()..':'..D.App.runningTime
  if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0YingzhaoCandidates(actor,identity,payload) VALUES(?,?,?)',{{actor,identity,payload}}}})then return nil,'WRITE_FAILED'end
  local rows=D.DB:query('SELECT id FROM lsd.Game0YingzhaoCandidates WHERE identity=?',{identity});if not rows or not rows[1]then return nil,'READ_FAILED'end
  return {id=rows[1][1],model=model,sourceCount=#sources,sourceId=selection=='latest'and ids[1]or nil}
 end,debug.traceback)
 busy=false;if not ok then return nil,'BUILD_FAILED'end;return result,why
end
function S.loadLatestAsync(actor)
 if actor~='ninilite'and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoCandidates WHERE actor=? ORDER BY id DESC LIMIT 1',{actor})
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NO_CANDIDATE'end
 if #rows[1][2]>16*1024*1024 then return nil,'SOURCE_TOO_LARGE'end
 local ok,result,why=xpcall(function()
  local source=D.json.decode(rows[1][2],32);if type(source)~='table'or source.schemaVersion~=1 then return nil,'INVALID_SOURCE'end
  local valid,why=P.validate(source.model,actor);if not valid then return nil,why end
  local rebuilt,why=P.buildAsync(source.records,actor,source.model.featureSchemaVersion,source.model.builderVersion or 1,source.model.actionSetVersion);if not rebuilt then return nil,why end
  if not require('Training.FlowerIdentity').equal(rebuilt,source.model)then return nil,'SOURCE_MODEL_MISMATCH'end
  return {id=rows[1][1],model=source.model}
 end,debug.traceback)
 if not ok then return nil,'INVALID_SOURCE'end;return result,why
end
return S
