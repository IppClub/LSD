-- Wait for the auto-save before exposing result navigation; explicit retries
-- write the same frozen observation and retain its idempotency key.
local D=require('Dora');local M={}
function M.callback()
 local first=true
 return function(_,report)
  local initial=first;first=false
  local trace=report and report.disarmTrace
  if not trace then return false,'MISSING_DISARM_TRACE'end
  local deadline=D.App.runningTime+12
  while trace.sourceSaveState==nil or trace.sourceSaveState=='saving'do
   if D.App.runningTime>=deadline then return false,'OBSERVATION_SAVE_PENDING'end
   D.sleep(.02)
  end
  if trace.sourceSaveState=='saved'then return true end
  if trace.sourceSaveState=='failed'and not initial then
   trace.sourceSaveState='saving'
   local ok,why,id=require('Training.DisarmStore').saveAsync(trace)
   trace.sourceSaveState=ok and 'saved'or'failed';trace.sourceSaveError=why;trace.sourceId=id
   if ok then return true end
  end
  return false,trace.sourceSaveError or trace.resourceReviewError or 'OBSERVATION_SAVE_FAILED'
 end
end
return M
