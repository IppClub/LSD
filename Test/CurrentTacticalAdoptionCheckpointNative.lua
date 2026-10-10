-- Explicit exploratory choice in a copied QA save, not a recommendation or
-- an update to the player's production save. Keep an adopted checkpoint and
-- prove the public rollback before any later deployment trial.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/current-tactical-adoption-checkpoint-result.json'
local r={status='RUNNING',exploratoryDeployment=true,stableBenefitProven=false,naturalVictory=false,osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),64)
  assert(prior.status=='PASS'and prior.protectedStateUnchanged and prior.report.candidate.characterId=='ninilite')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-post%-armor%-compare%-%d+%.db$'))
  local db=D.Content.writablePath..'/current-tactical-adoption-'..os.time()..'.db';r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available
  local S=require('Training.YingzhaoAdoptionStore');local I=require('Training.FlowerIdentity');local initial=S.state('ninilite');local continuing=os.getenv('LSD_QA_CONTINUE_TACTICAL_ADOPTION')=='1';assert((continuing or initial.current==0)and S.state('wuyun').current==0);r.continuingExploratoryChoice=continuing;r.previousAdoption=initial
  local function protected()return {basic=D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),other=D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),missions=D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),wallet=E.wallet().available}end
  local before=protected()
  local function wait(fn)local stop=D.App.runningTime+30;while not fn()do assert(D.App.runningTime<stop,'Exploratory adoption UI timeout');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
  wait(function()local v=D.Director.ui3D:getChildByTag('yingzhao-adoption');return v and not v.state.busy end)
  local p=D.Director.ui3D:getChildByTag('yingzhao-adoption').state
  assert(p.bundle and p.bundle.comparison.id==prior.comparisonId and p.adopt.visible)
  assert(p.proof.review.stableBenefitProven==false);r.review=p.proof.review
  p.adopt:emit('Tapped');p.cancel:emit('Tapped');assert(I.equal(initial,S.state('ninilite')))
  p.adopt:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  local models=assert(require('Training.FlowerPractice').models());local adopted=assert(S.loadAsync('ninilite',models,'mission'))
  assert(p.already and adopted.id==S.state('ninilite').current and I.equal(adopted.proof.candidate.model,prior.report.candidate))
  r.active=adopted.id;r.model=adopted.proof.candidate.model
  local checkpoint=D.Content.writablePath..'/current-tactical-adopted-checkpoint-'..os.time()..'.db'
  assert(D.DB:exec("VACUUM lsd INTO '"..checkpoint.."'")>=0);r.adoptedCheckpoint=checkpoint
  r.balanceAfter=E.wallet().available;assert(r.balanceAfter==r.balanceBefore and I.equal(before,protected()))
  p.rollback:emit('Tapped');p.cancel:emit('Tapped');assert(S.state('ninilite').current==r.active)
  p.rollback:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  assert(S.state('ninilite').current==initial.current and S.state('ninilite').revision==initial.revision+2 and S.state('wuyun').current==0 and I.equal(before,protected()))
  r.publicRollbackVerified=true;r.protectedStateUnchanged=true;r.scope='isolated-exploratory-checkpoint-only'
  p.back:emit('Tapped');assert(controls().visible)
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
