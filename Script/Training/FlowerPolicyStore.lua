local D=require('Dora');local P=require('Training.FlowerPolicy');local S={}
local function open()
 if not D.DB:existDB('lsd')then return false end
 return D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0FlowerCandidates (learner TEXT PRIMARY KEY, payload TEXT NOT NULL)')>=0 and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0FlowerCandidateEvidence (learner TEXT PRIMARY KEY, payload TEXT NOT NULL)')>=0
end
function S.saveAsync(model,history)
 local ok,why=P.validate(model);if not ok then return false,why end
 local E=require('Training.FlowerEvidence');local evidence,why=E.make(model,history);if not evidence then return false,why end
 local archived=D.json.encode(evidence,false,true);if #archived>E.maxBytes then return false,'EVIDENCE_TOO_LARGE'end
 -- Snapshot inputs before yielding to the native builder.
 evidence=D.json.decode(archived,32);local ok,why=E.verifyAsync(evidence,model.characterId);if not ok then return false,why end
 model=evidence.policy
 local payload=D.json.encode(model,false,true);if #payload>1048576 then return false,'MODEL_TOO_LARGE'end
 if not open()then return false,'WRITE_FAILED'end
 local saved=D.DB:transactionAsync({
  {'INSERT INTO lsd.Game0FlowerCandidates(learner,payload) VALUES(?,?) ON CONFLICT(learner) DO UPDATE SET payload=excluded.payload',{{model.characterId,payload}}},
  {'INSERT INTO lsd.Game0FlowerCandidateEvidence(learner,payload) VALUES(?,?) ON CONFLICT(learner) DO UPDATE SET payload=excluded.payload',{{model.characterId,archived}}}
 })
 if not saved then return false,'WRITE_FAILED'end;return true,nil,D.json.decode(payload,32)
end
function S.load(actor)
 if actor~='ninilite' and actor~='wuyun' then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0FlowerCandidates WHERE learner=?',{actor});if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return nil,'NOT_RECORDED'end
 local payload=rows[1][1];if type(payload)~='string' or #payload>1048576 then return nil,'INVALID_PAYLOAD'end
 local model=D.json.decode(payload,32);local ok,why=P.validate(model,actor);if not ok then return nil,why end;return model
end
function S.evidence(actor)
 local model,why=S.load(actor);if not model then return nil,why end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0FlowerCandidateEvidence WHERE learner=?',{actor});if not rows then return nil,'READ_FAILED'end
 if not rows[1]then return nil,'EVIDENCE_NOT_RECORDED'end
 local payload=rows[1][1];local E=require('Training.FlowerEvidence')
 if type(payload)~='string' or #payload>E.maxBytes then return nil,'INVALID_EVIDENCE_PAYLOAD'end
 local evidence=D.json.decode(payload,32);local ok,why=E.validate(evidence,actor);if not ok then return nil,why end
 if not require('Training.FlowerIdentity').equal(evidence.policy,model)then return nil,'EVIDENCE_POLICY_MISMATCH'end
 return evidence
end
return S
