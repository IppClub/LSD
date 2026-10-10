-- Real ground/factory learner actions and journals; isolated controlled arenas.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/part-action-interruption-result.json'
local r={status='RUNNING',scope='controlled-native-part-action-journals',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)
   local stop=D.App.runningTime+12
   while not fn()do assert(D.App.runningTime<stop,'Part action fixture stalled');D.sleep(.01)end
  end
  assert(not D.DB:existDB('lsd'))
  local db=D.Content.writablePath..'/part-action-interruption.db'
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config')
  local service={finishAsync=function()return true end}
  local function exercise(b,a,action,label)
   a.nextDecision=math.huge
   wait(function()return a.student.onSurface and D.App.runningTime>=a.nextShot end)
   local journal=b.partCombat.journal;local before=#journal.steps
   assert(a.student:start(a.physical[action]));D.sleep(.1)
   local step=assert(journal.steps[before+1]);assert(not step.finished)
   a.student:stop();D.sleep(.03)
   assert(step.finished and step.reason=='interrupted','Native interruption lost journal reason')
   local ended=step.finished;D.sleep(.1);assert(step.finished==ended,'Duplicate interruption finish')
   wait(function()return a.student.onSurface and D.App.runningTime>=a.nextShot end)
   before=#journal.steps;assert(a.student:start(a.physical[action]))
   local complete=assert(journal.steps[before+1]);wait(function()return complete.finished end)
   assert(not complete.reason and complete.duration>.1,'Natural completion marked interrupted')
   r.cases[#r.cases+1]={label=label,interrupted=step,completed=complete}
  end
  local g=require('Ground.Battle').createAsync(service,{id='interruption-ground',mission='c0-m02',model=model('ninilite')})
  g.arena.enemyCombat.update=function()end;exercise(g,g.arena,'laser','ground-laser')
  local f=require('Factory.Battle').createAsync(service,{id='interruption-factory',mission='c0-m05',models={ninilite=model('ninilite'),wuyun=model('wuyun')}},nil,{training=true})
  for _,e in ipairs(f.roots)do e.enemyCombat:close()end
  assert(f:start());for _,a in ipairs(f.learners)do a.nextDecision=math.huge end
  exercise(f,f.arena,'laser','factory-laser');exercise(f,f.wuyun,'melee','factory-melee')
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
