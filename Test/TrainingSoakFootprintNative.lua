-- Measure retained diagnostic rows in the actual Lua runtime, not game memory.
-- Read-only: no database, training model, wallet, or production changes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/training-soak-footprint-result.json'
local r={status='RUNNING',scope='diagnostic allocation accounting only'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local parent=D.json.decode(assert(D.Content:load(root..'/Test/training-soak-current-result.json')),32)
  assert(parent.status=='PASS' and parent.elapsed>=1800 and parent.completedCycles>=20,'Current soak not complete')
  r.sourceRunId=parent.runId;r.cycleCount=#parent.cycles
  assert(r.cycleCount==parent.completedCycles)
  r.measuredGrowth=parent.cycles[#parent.cycles].luaKB-parent.cycles[1].luaKB
  -- Normalize once before taking a baseline. Only the cycles array is removed;
  -- all other parsed report data stays live for both sides of this comparison.
  collectgarbage('collect');D.sleep(.1);collectgarbage('collect')
  local before=collectgarbage('count')
  parent.cycles=nil
  collectgarbage('collect');D.sleep(.1);collectgarbage('collect')
  local after=collectgarbage('count')
  r.diagnosticRowsKB=before-after;r.beforeKB=before;r.afterKB=after
  assert(r.diagnosticRowsKB>0,'Diagnostic footprint could not be measured')
  r.approximateGrowthMinusRowsKB=r.measuredGrowth-r.diagnosticRowsKB
  r.notWholeGameLeakProof=true;r.notAdditionalLongSoak=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and tostring(why)or nil;save();print('LSD_TRAINING_SOAK_FOOTPRINT_'..r.status)
end)
