-- Public joint entry and eight natural paired trials. All records stay in QA.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-team-smoke-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-wuyun-current-result.json'),32));assert(prior.status=='PASS' and prior.ready)
  assert(D.Path:getFilename(prior.database):match('^flower%-wuyun%-current%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-team-smoke-'..os.time()..'.db';assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local T=require('Training.FlowerTeamTrials');local equal=require('Training.FlowerIdentity').equal
  local function singleState()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerPractice'),D.DB:query('SELECT * FROM lsd.Game0FlowerTrials'),D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState')},false,true)end
  local before=singleState();local function wait(fn,seconds)local untilAt=D.App.totalTime+(seconds or 10);while not fn()do assert(D.App.totalTime<untilAt,'Joint entry timeout');D.sleep(.02)end end
  local c=P.openAsync(nil,'ninilite');D.sleep(.3);assert(c.teamButton.visible);local old=c.ui;c.teamButton:emit('Tapped')
  wait(function()local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');return ui and ui~=old end)
  c=D.Director.ui3D:getChildByTag('flower-practice-controls').practice;assert(c.teamSources and c.profile.id=='field')
  assert(not c:start() and not c:learnAsync('latest'));D.sleep(.2);assert(not c.hud.visible and not c.adoptionButton.visible and not c.learnButton.visible)
  local sources=c.teamSources;assert(sources.ninilite.policy.sampleCount==39 and sources.wuyun.policy.sampleCount==35);r.publicEntry=true
  c.basicButton:emit('Tapped');D.sleep(1);c.finishButton:emit('Tapped');wait(function()return c.result or c.battle.phase=='save-error'end,20)
  assert(c.result,c.battle.saveError);assert(c.result.trialSaved)
  local record=assert(T.history())[1];assert(record.status=='aborted' and T.validate(record));assert(T.saveAsync(c.trialRecord))
  assert(not require('Training.FlowerTrialStore').validate(record));assert(singleState()==before);r.storeRoundtrip=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
