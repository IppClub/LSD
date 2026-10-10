-- Controlled real UnitActions; no policy, mission victory or visual acceptance.
local D=require('Dora')
local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/arena-interrupted-action-trace-result.json'
local r={status='RUNNING',scope='native-action-interruption-record-closure',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end
save()
D.thread(function()
 local ok,err=xpcall(function()
  local A=require('Training.Arena');local K=require('Combat.Displacement')
  local ni=A.createAsync({scene='VRTraining',manualUpdate=true,actionPrefix='interruptTraceNi_'})
  local wu=A.createAsync({world=ni.world,manualUpdate=true,characterId='wuyun',actionPrefix='interruptTraceWu_'})
  local function wait(fn)
   local deadline=D.App.runningTime+12
   while not fn()do assert(D.App.runningTime<deadline,'Native interruption fixture stalled');D.sleep(.01)end
  end
  for _,a in ipairs({ni,wu})do
   local records={}
   local function begin(owner)
    local record={started=D.App.runningTime,actor=a.character.id};records[#records+1]=record;return #records
   end
   local function finish(id,owner,source,status)
    local record=assert(records[id]);record.notifications=(record.notifications or 0)+1
    record.ended=D.App.runningTime;record.result=status
   end
   a.beginCombatAction=begin;a.beginMeleeAction=begin
   a.finishCombatAction=finish;a.finishMeleeAction=function(id,owner,status)finish(id,owner,nil,status)end
   local action=a.character.id=='ninilite'and'laser'or'melee'
   wait(function()return a.student.onSurface end)
   assert(a.student:start(a.physical[action]));D.sleep(.1)
   assert(a.student:isDoing(a.physical[action]),'Attack did not start')
   assert(K.apply({unit=a.student},480,1080,{}),'Actual displacement rejected')
   D.sleep(.05)
   local record=assert(records[1]);assert(record.ended,'Interrupted native action has no finish notification')
   assert(record.notifications==1 and record.result=='interrupted','Wrong interrupted action closure')
   wait(function()return not K.blocked(a.student)and a.student.onSurface end)
   D.sleep(.1);assert(record.notifications==1,'Interrupted action finished twice')
   assert(a.student:start(a.physical[action]));wait(function()return records[2]and records[2].ended end)
   assert(records[2].notifications==1 and records[2].result=='completed','Natural completion was not preserved')
   r.cases[#r.cases+1]={actor=a.character.id,action=action,interrupted=record,completed=records[2]}
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
