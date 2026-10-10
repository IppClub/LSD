-- Observation archives only; no training/adoption pointer or wallet mutation.
local D=require('Dora');local Review=require('Training.DisarmResourceReview')
local equal=require('Training.FlowerIdentity').equal
local S={maxBytes=4*1024*1024};local busy=false
local fields={'schemaVersion','startedAt','comparisonSetup','comparisonProfile','comparisonController','candidate','candidateDecisions','adoptions','adoptionDecisions','demonstrator','kind','clock','trainable','trainingBlock','actions','weaponEvents','rejected','consumption','limit','truncated','status','finishedAt','resources','virtualResult','resourcesFinalizedAt','executionVersion','executions','impactVersion','impacts','projectiles','vitalsVersion','vitals'}
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0DisarmObservations(id INTEGER PRIMARY KEY AUTOINCREMENT,episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0
end
local function decode(payload)
 if type(payload)~='string' or #payload>S.maxBytes then return nil,'SOURCE_TOO_LARGE'end
 local ok,source,review,why=pcall(function()
  local source=D.json.decode(payload,32)
  if type(source)~='table' or source.schemaVersion~=1 then return nil,nil,'INVALID_SOURCE'end
  local review,why=Review.rebuild(source.trace);return source,review,why
 end)
 if not ok then return nil,'INVALID_SOURCE'end
 if not review then return nil,why end
 return source,review
end
function S.loadLatestAsync()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,payload FROM lsd.Game0DisarmObservations ORDER BY id DESC LIMIT 1')
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NOT_RECORDED'end
 local source,review=decode(rows[1][2]);if not source then return nil,review end
 return {id=rows[1][1],source=source,review=review}
end
function S.listAsync()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id FROM lsd.Game0DisarmObservations ORDER BY id DESC LIMIT 20')
 if not rows then return nil,'READ_FAILED'end
 local ids={};for _,row in ipairs(rows)do ids[#ids+1]=row[1]end;return ids
end
function S.loadAsync(id)
 if type(id)~='number' or id%1~=0 or id<1 then return nil,'INVALID_SOURCE_ID'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0DisarmObservations WHERE id=?',{id})
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NOT_RECORDED'end
 local source,review=decode(rows[1][1]);if not source then return nil,review end
 return {id=id,source=source,review=review}
end
function S.saveAsync(trace)
 if busy then return false,'BUSY'end;busy=true
 local ok,accepted,reason,id=xpcall(function()
  if type(trace)~='table'or trace.kind~='disarm-practice'then return false,'INVALID_SOURCE'end
  local snapshot={};for _,key in ipairs(fields)do snapshot[key]=trace[key]end
  local payload=D.json.encode({schemaVersion=1,trace=snapshot},false,true)
  local source,review=decode(payload);if not source then return false,review end
  if not open()then return false,'WRITE_FAILED'end
  local episode=source.trace.resources.attempt
  local rows=D.DB:query('SELECT id,payload FROM lsd.Game0DisarmObservations WHERE episode=?',{episode})
  if not rows then return false,'READ_FAILED'end
  if rows[1]then
   local old=decode(rows[1][2]);if not old or not equal(old,source)then return false,'SOURCE_CONFLICT'end
   return true,'ALREADY_RECORDED',rows[1][1]
  end
  if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0DisarmObservations(episode,payload) VALUES(?,?)',{{episode,payload}}}})then return false,'WRITE_FAILED'end
  rows=D.DB:query('SELECT id FROM lsd.Game0DisarmObservations WHERE episode=?',{episode})
  if not rows or not rows[1]then return false,'READ_FAILED'end
  return true,nil,rows[1][1]
 end,debug.traceback)
 busy=false
 if not ok then return false,'INVALID_SOURCE'end
 return accepted,reason,id
end
return S
