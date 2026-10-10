-- Earned one-unit medicine, actual durable consumption, controlled health and
-- delayed consumption response. Fake mission completion isolates report timing.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/pursuit-medicine-settlement-result.json'
local r={status='RUNNING',cases={},osInput=false,controlledFixture=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load('/private/tmp/lsd-report-snapshot-full-journey-20261009/fresh-recovery-current/result.json')),32)
  assert(prior.status=='PASS'and prior.sameJourney)
  local function wait(fn)local deadline=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<deadline,'Pursuit medicine boundary timeout');D.sleep(.02)end end
  for _,variant in ipairs({'before','after'})do
   for _,boundary in ipairs({'zero-health','withdraw-during-write'})do
    local db=D.Path(D.Content.writablePath,'pursuit-medicine-'..variant..'-'..boundary..'.db')
    assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
    local S=require('Story.Supplies');assert(S.count('mentor','first-aid-water')==1)
    local module
    if variant=='before'then local path='/private/tmp/lsd-pursuit-medicine-before-20261009/Pursuit.lua';module=assert(load(assert(D.Content:load(path)),'@'..path))()
    else module=require('Ruins.Pursuit')end
    local recorded
    local b=module.createAsync({finishAsync=function(_,_,status,report)recorded={status=status,report=D.json.decode(D.json.encode(report,false,true),32)};return true end},{mission='c0-m06'})
    b.update=function()return false end
    local row={variant=variant,boundary=boundary,database=db,parentDatabase=prior.database,stockBefore=1};r.cases[#r.cases+1]=row
    if boundary=='zero-health'then
     b.mentorHP=0;local accepted,reason=b:command('medicine');row.accepted=accepted;row.reason=reason
     wait(function()return not b.medicineBusy end)
     assert(b.mentorHP==0)
     assert(S.count('mentor','first-aid-water')==(variant=='before'and 0 or 1))
     if variant=='after'then assert(not accepted and reason=='NOT_ALIVE')end
     b:finish('failed','Controlled zero-health boundary')
    else
     b.mentorHP=75
     local consume=S.consumeAsync;local committed=false
     S.consumeAsync=function(...)
      local success,err=consume(...);assert(success,err);committed=true
      D.sleep(.3);return success,err
     end
     assert(b:command('medicine'));wait(function()return committed end)
     assert(b.medicineBusy and S.count('mentor','first-aid-water')==0)
     b:finish('aborted','Controlled withdrawal during medicine response');D.sleep(.1)
     row.savedWhileMedicinePending=recorded~=nil
     if variant=='before'then assert(recorded and recorded.report.medicineUses==0)
     else assert(not recorded and b.phase=='saving')end
     wait(function()return not b.medicineBusy end);S.consumeAsync=consume
     assert(b.mentorHP==75,'Settlement must not heal a closed battle')
    end
    wait(function()return recorded and(b.phase=='failed'or b.phase=='aborted')end)
    row.stockAfter=S.count('mentor','first-aid-water');row.reportMedicineUses=recorded.report.medicineUses;row.health=b.mentorHP
    if boundary=='withdraw-during-write'then
     assert(row.stockAfter==0 and row.reportMedicineUses==(variant=='before'and 0 or 1))
     row.reportMatchesConsumedStock=row.reportMedicineUses==row.stockBefore-row.stockAfter
    else assert(row.reportMedicineUses==0)end
    save()
    D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();D.sleep(.3)
    assert(D.DB:exec('DETACH DATABASE lsd')>=0)
   end
  end
  r.scope='Copied earned medicine inventory, actual async consumption, controlled zero HP and delayed response, original Pursuit finish/report; fake completion service. Not formal mission billing, actual OS or normal victory.'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
