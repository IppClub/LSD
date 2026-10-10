local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-adoption-result.json';local r={status='RUNNING',checks={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-low-gun-regression-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-low%-gun%-regression%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-adoption-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.DisarmAdoptionStore');local C=require('Training.DisarmCompare');local CS=require('Training.DisarmComparisonStore');local equal=require('Training.FlowerIdentity').equal
  local actor='wuyun';local models=assert(require('Training.FlowerPractice').models())
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();local state=assert(S.state(actor));assert(state.current==0 and state.revision==0)
  local old=assert(CS.loadLatest());assert(not old.record.setup.combatRules)
  local bundle,why=S.captureAsync(old.id,models);assert(not bundle and why=='ENCOUNTER_CHANGED');r.checks.historicalReviewOnly=true
  local candidate=assert(require('Training.DisarmPolicyStore').loadLatestAsync(actor))
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true})
  local bundles={};local proofs={}
  for group=1,2 do
   r.group=group;save()
   local record,why=C.runAsync(candidate,models,loadout,{onBattle=function(_,index)r.currentRun=index;save()end});assert(record and not why,why)
   local id=assert(CS.saveAsync(record));bundles[group],proofs[group]=S.captureAsync(id,models);assert(bundles[group],proofs[group])
  end
  bundle=bundles[1];local ack={accepted=true,comparisonId=bundle.comparison.id,review=proofs[1].review}
  local function reject(expectedReason,... )local yes,reason=S.adoptAsync(...);assert(not yes and reason==expectedReason,tostring(reason))end
  reject('EXPECTED_ADOPTION_REQUIRED',bundle,ack,models,nil)
  reject('REVIEW_NOT_ACKNOWLEDGED',bundle,{accepted=false},models,state)
  reject('BASE_MODELS_CHANGED',bundle,ack,{},state)
  local malformed=D.json.decode(D.json.encode(bundle,false,true),32);malformed.comparison.id=-1;reject('INVALID_BUNDLE',malformed,ack,models,state)
  assert(equal(S.state(actor),state));r.checks.confirmationAndVersions=true
  local yes,reason,id=S.adoptAsync(bundle,ack,models,state);assert(yes and reason=='ADOPTED',reason);r.first=id
  assert(S.loadAsync(actor,models).id==id and S.state('ninilite').current==0)
  local firstState=S.state(actor);local yes,reason,again=S.adoptAsync(bundle,ack,models,firstState);assert(yes and reason=='ALREADY_ADOPTED'and again==id)
  reject('ADOPTION_CHANGED',bundle,ack,models,state);assert(equal(firstState,S.state(actor)));r.checks.idempotentAndRoleIsolated=true
  local function archiveSnapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0DisarmAdoptions'),D.DB:query('SELECT * FROM lsd.Game0DisarmAdoptionState')},false,true)end
  local second=bundles[2];local secondAck={accepted=true,comparisonId=second.comparison.id,review=proofs[2].review}
  for _,trigger in ipairs({
   "CREATE TRIGGER lsd.break_adopt BEFORE INSERT ON Game0DisarmAdoptions BEGIN SELECT RAISE(ABORT,'write failure'); END",
   "CREATE TRIGGER lsd.break_adopt AFTER UPDATE ON Game0DisarmAdoptionState BEGIN DELETE FROM Game0DisarmAdoptionState WHERE actor=NEW.actor; END",
   "CREATE TRIGGER lsd.break_adopt AFTER UPDATE ON Game0DisarmAdoptionState BEGIN UPDATE Game0DisarmCandidates SET payload='{}' WHERE id="..candidate.id.."; END",
   "CREATE TRIGGER lsd.break_adopt AFTER UPDATE ON Game0DisarmAdoptionState BEGIN UPDATE Game0DisarmAdoptions SET payload='{}' WHERE id=NEW.current; END"
  })do
   local beforeArchive=archiveSnapshot();assert(D.DB:exec(trigger)>=0)
   reject('WRITE_FAILED',second,secondAck,models,firstState)
   assert(D.DB:exec('DROP TRIGGER lsd.break_adopt')>=0);assert(archiveSnapshot()==beforeArchive and snapshot()==before)
  end
  r.checks.adoptionTransactionAtomic=true
  local yes,reason,secondId=S.adoptAsync(second,secondAck,models,firstState);assert(yes and reason=='ADOPTED',reason);assert(S.inspectAsync(actor).parent==id)
  local secondState=S.state(actor)
  for _,trigger in ipairs({
   "CREATE TRIGGER lsd.break_rollback AFTER UPDATE ON Game0DisarmAdoptionState BEGIN DELETE FROM Game0DisarmAdoptionState WHERE actor=NEW.actor; END",
   "CREATE TRIGGER lsd.break_rollback AFTER UPDATE ON Game0DisarmAdoptionState BEGIN UPDATE Game0DisarmAdoptions SET payload='{}' WHERE id=NEW.current; END"
  })do
   local beforeArchive=archiveSnapshot();assert(D.DB:exec(trigger)>=0)
   local yes,reason=S.rollbackAsync(actor,secondState);assert(not yes and reason=='WRITE_FAILED',reason)
   assert(D.DB:exec('DROP TRIGGER lsd.break_rollback')>=0);assert(archiveSnapshot()==beforeArchive)
  end
  local yes,reason,restored=S.rollbackAsync(actor,secondState);assert(yes and reason=='ROLLED_BACK'and restored==id,reason)
  assert(S.loadAsync(actor,models).id==id);reject('ADOPTION_CHANGED',second,secondAck,models,firstState)
  local yes,reason=S.rollbackAsync(actor,S.state(actor));assert(yes and reason=='RESTORED_BASIC',reason)
  local saved,reason=S.loadAsync(actor,models);assert(not saved and reason=='NOT_ADOPTED');r.checks.rollbackAndStaleRevision=true
  assert(S.adoptAsync(bundle,ack,models,S.state(actor)));assert(snapshot()==before)
  r.active=S.state(actor).current;r.checks.originalProgressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
