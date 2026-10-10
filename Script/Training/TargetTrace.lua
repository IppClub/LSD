-- Evidence for an adopted part policy. Result fields never become observations.
local D=require('Dora');local Policy=require('Training.TargetPolicy')
local T={}
local function copy(v)return D.json.decode(D.json.encode(v,false,true),64)end
local function same(a,b)
 if type(a)~=type(b)then return false end
 if type(a)=='number'then return math.abs(a-b)<=1e-10*math.max(1,math.abs(a),math.abs(b))end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
function T.create(policy,demonstrations,evaluation,qTraining)
 if not evaluation or evaluation.model~=policy then return nil,'EVALUATION_REQUIRED'end
 local trace={schemaVersion=1,id=policy.traceId,characterId=policy.characterId,policy=copy(policy),demonstrations=copy(demonstrations),groups=copy(evaluation.groups)}
 if policy.q then trace.qTraining=copy(qTraining);trace.demonstrations={}end
 local ok,why=T.validate(trace,policy);if not ok then return nil,why end
 return trace
end
local function validate(trace,policy)
 if type(trace)~='table' or trace.schemaVersion~=1 or not Policy.validate(policy) or type(policy.traceId)~='string' or trace.id~=policy.traceId or trace.characterId~=policy.characterId or not same(trace.policy,policy) then return false,'TRACE_POLICY_MISMATCH'end
 if type(trace.demonstrations)~='table' or #trace.demonstrations>1500 then return false,'INVALID_DEMONSTRATIONS'end
 if policy.q then
  local ok,why=require('Training.PartQTrace').validate(trace.qTraining,policy.q);if not ok then return false,why end
 else
 local rec,rounds=Policy.recordDemonstrations(policy.characterId,trace.demonstrations,policy.tree.featureSchemaVersion)
 if not rec or #rec.samples~=policy.tree.sampleCount then return false,'TRACE_SAMPLE_MISMATCH'end
 local count=0;for _ in pairs(rounds)do count=count+1 end
 if count~=policy.roundCount then return false,'TRACE_ROUND_MISMATCH'end
 end
 local groups=trace.groups
 if type(groups)~='table' or not groups.baseline or not groups.candidate then return false,'MISSING_COMPARISON'end
 for kind,group in pairs(groups)do
  if (kind~='baseline' and kind~='candidate' and kind~='adopted') or type(group)~='table' or #group~=3 then return false,'INVALID_COMPARISON'end
  for i,r in ipairs(group)do
   if r.distance~=({420,620,780})[i] or r.opportunities~=6 or type(r.steps)~='table' or not finite(r.unavailable) or r.unavailable<0 or r.unavailable%1~=0 or #r.steps+r.unavailable~=6 then return false,'INVALID_OPPORTUNITIES'end
   local total={emitted=0,hits=0,armor=0,breaks=0,targeted=0,matched=0,fallback=0}
   for _,step in ipairs(r.steps)do
    local a=step.action
    if not step.sealed or step.truncated or type(a)~='table' or a.controller~=(kind=='baseline' and 'baseline' or 'target-model') or type(step.hits)~='table' then return false,'INVALID_COMPARISON_STEP'end
    local emitted=a.emitted or 0
    if not finite(emitted) or emitted<0 or emitted>1 or emitted%1~=0 then return false,'INVALID_EMISSION'end
    if a.targetFallback then
     if kind=='baseline' or (kind=='candidate' and not policy.q) or a.intendedPart~='unknown' or (a.targetFallback~='UNSEEN_STATE' and a.targetFallback~='UNSEEN_ACTIONS') then return false,'INVALID_TARGET_FALLBACK'end
     total.fallback=total.fallback+emitted
    end
    total.emitted=total.emitted+emitted
    local targeted=a.intendedPart~='unknown';if targeted then total.targeted=total.targeted+emitted end
    for _,hit in ipairs(step.hits)do
     if not finite(hit.armorDamage) or hit.armorDamage<0 or hit.armorDamage>120 then return false,'INVALID_HIT'end
     total.hits=total.hits+1;total.armor=total.armor+hit.armorDamage
     if hit.armorBroken then total.breaks=total.breaks+1 end
     if targeted and hit.part==a.intendedPart then total.matched=total.matched+1 end
    end
   end
   for k,v in pairs(total)do if (k=='fallback' and (r[k] or 0) or r[k])~=v then return false,'COMPARISON_TOTAL_MISMATCH'end end
  end
 end
 return true
end
function T.validate(trace,policy)
 local ok,result,why=pcall(validate,trace,policy)
 if not ok then return false,'MALFORMED_TRACE'end
 return result,why
end
return T
