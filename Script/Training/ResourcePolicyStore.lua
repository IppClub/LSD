-- Append-only resource C4.5 candidates with frozen, independently rebuildable demos.
local D=require('Dora');local E=require('Training.ResourcePolicyEvidence');local S={};local busy=false
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0ResourceC45Candidates(id INTEGER PRIMARY KEY AUTOINCREMENT,learner TEXT NOT NULL,payload TEXT NOT NULL)')>=0
end
local function decode(payload,actor)
 if type(payload)~='string' or #payload>E.maxBytes then return nil,'INVALID_EVIDENCE_PAYLOAD'end
 local ok,e=pcall(D.json.decode,payload,32);if not ok then return nil,'INVALID_EVIDENCE_PAYLOAD'end
 local yes,why=E.verifyAsync(e,actor);if not yes then return nil,why end
 return e
end
function S.evidenceAsync(actor)
 if actor~='ninilite' and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id,payload FROM lsd.Game0ResourceC45Candidates WHERE learner=? ORDER BY id DESC LIMIT 1',{actor})
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NOT_RECORDED'end
 local e,why=decode(rows[1][2],actor);if not e then return nil,why end
 return {id=rows[1][1],evidence=e,model=e.policy}
end
function S.loadAsync(actor)
 local row,why=S.evidenceAsync(actor);if not row then return nil,why end
 return row.model,nil,row.id
end
function S.saveAsync(model,history)
 if busy then return false,'BUSY'end;busy=true
 local ok,accepted,why,persisted=xpcall(function()
  local evidence,why=E.make(model,history);if not evidence then return false,why end
  local payload=D.json.encode(evidence,false,true);if #payload>E.maxBytes then return false,'EVIDENCE_TOO_LARGE'end
  local frozen,why=decode(payload,model.characterId);if not frozen then return false,why end
  if not open()then return false,'WRITE_FAILED'end
  local current,why=S.evidenceAsync(model.characterId)
  if not current and why~='NOT_RECORDED'then return false,why end
  if current and require('Training.FlowerIdentity').equal(current.evidence,frozen)then return true,'ALREADY_SAVED',current.model end
  local saved=D.DB:transactionAsync({{'INSERT INTO lsd.Game0ResourceC45Candidates(learner,payload) VALUES(?,?)',{{frozen.policy.characterId,payload}}}})
  if not saved then return false,'WRITE_FAILED'end
  return true,'SAVED',frozen.policy
 end,debug.traceback)
 busy=false;if not ok then return false,'RESOURCE_C45_STORE_ERROR',accepted end
 return accepted,why,persisted
end
return S
