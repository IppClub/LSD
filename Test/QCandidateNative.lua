local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/q-candidate-native-result.json';local r={status='RUNNING',characters={}}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,why=xpcall(function()
  local database=D.Content.writablePath..'/q-candidates.db';assert(not D.Content:exist(database) and not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  local Store=require('Training.Store');local Arena=require('Training.Arena')
  for _,character in ipairs({'ninilite','wuyun'})do
   r.current=character;r.phase='training';save()
   local old={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=character,sampleCount=7,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}
   local store=assert(Store.open(nil,character));store:load();assert(store:saveAsync(old))
   local a=Arena.createAsync({characterId=character,adopted=old})
   local candidate,err=a:trainQAsync(12345);assert(candidate,err)
   assert(a.adopted==old and a.candidate==candidate and #a.qTrainingReport.rounds==3 and candidate.updates>0)
   local accepted,reason=a:adopt();assert(not accepted and reason=='EVALUATION_REQUIRED')
   r.phase='comparison';save()
   local evaluation=assert(a:evaluateAsync());assert(#evaluation.baseline==3 and #evaluation.candidate==3 and #evaluation.previous==3)
   assert(a:adopt());assert(store:saveAsync(a.adopted,a.previous,a.qTrainingReport))
   store=assert(Store.open(nil,character));local loaded=assert(store:load());assert(loaded.adopted.algorithm=='qlearning' and loaded.previous.sampleCount==7)
   assert(a:rollback());assert(a.adopted==old and a.previous==candidate);assert(store:saveAsync(a.adopted,a.previous,a.qTrainingReport))
   assert(a:rollback());assert(store:saveAsync(a.adopted,a.previous,a.qTrainingReport))
   -- Resume creates a private learner. Cancellation leaves adopted Q unchanged.
   local serialized=D.json.encode(a.adopted);local result,finished
   D.thread(function()result=a:trainQAsync(6789);finished=true end)
   local limit=D.App.runningTime+3
   while not a.qSession or a.qSession.closed or not a.qSession.pending do assert(D.App.runningTime<limit);D.sleep(.02)end
   assert(a:cancelQTraining())
   while not finished do D.sleep(.02)end
   assert(not result and a.candidate==nil and D.json.encode(a.adopted)==serialized)
   local saved=assert(store:load());assert(saved.adopted.updates==candidate.updates)
   r.characters[#r.characters+1]={character=character,updates=candidate.updates,summary=evaluation.summary,adopted=true,rollback=true,cancelPreserved=true}
   save()
  end
  assert(D.DB:exec('DETACH DATABASE lsd')>=0)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and why or nil;save()
end)
