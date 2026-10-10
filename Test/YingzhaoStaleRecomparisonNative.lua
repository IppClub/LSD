-- Actual archived adoption, public recompare and explicit confirmation.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-stale-recomparison-result.json'
local r={status='RUNNING',osInput=false,checks={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32);assert(prior.status=='PASS' and prior.algorithm=='yingzhao-c45')
  assert(prior.adoptedCheckpoint:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-ui%-adopted%-checkpoint%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-stale-recomparison-'..os.time()..'.db';r.database=db;r.parentEvidence=parent;r.algorithm=prior.algorithm;save()
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.adoptedCheckpoint,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.YingzhaoAdoptionStore');local I=require('Training.FlowerIdentity');local models=assert(require('Training.FlowerPractice').models())
  local old=assert(S.inspectAsync('ninilite'));local initial=assert(S.state('ninilite'));local partner=assert(S.state('wuyun'));assert(partner.current==0)
  local deployed,why=S.loadAsync('ninilite',models,'mission');assert(not deployed and why=='ENCOUNTER_CHANGED')
  local economy=require('Economy.Store');assert(economy.open());local balance=economy.wallet().available
  local function walletBasic()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id')})end
  local baseline=walletBasic()
  local function wait(fn,seconds)local deadline=D.App.runningTime+(seconds or 30);while not fn()do local failed=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');if failed and failed.error then error(failed.error)end;assert(D.App.runningTime<deadline,'Stale recompare UI timeout');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位对照'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-budget')end);local budget=D.Director.ui3D:getChildByTag('yingzhao-comparison-budget');assert(budget.noteLabel.text:find('旧规则成果仅作为虚拟对照基准',1,true));budget.saveButton:emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-result')end,420)
  local v=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');assert(v.saved,v.saveError or v.error)
  assert(I.equal(v.report.baseline,old.proof.candidate.model) and require('Training.YingzhaoRules').current(v.report.setup))
  assert(I.equal(initial,S.state('ninilite')) and I.equal(partner,S.state('wuyun')) and economy.wallet().available==balance and walletBasic()==baseline)
  deployed,why=S.loadAsync('ninilite',models,'mission');assert(not deployed and why=='ENCOUNTER_CHANGED');r.checks.recomparePreservesOldAndRequiresConfirmation=true;r.comparisonId=v.saved;r.report=v.report;save()
  v.backButton:emit('Tapped');wait(controls);menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
  wait(function()local ui=D.Director.ui3D:getChildByTag('yingzhao-adoption');return ui and not ui.state.busy end)
  local p=D.Director.ui3D:getChildByTag('yingzhao-adoption').state;assert(p.bundle and p.adopt.visible);p.adopt:emit('Tapped');p.cancel:emit('Tapped');assert(I.equal(initial,S.state('ninilite')))
  p.adopt:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  local current,why=S.loadAsync('ninilite',models,'mission');assert(current,why);assert(current.parent==old.id and current.id~=old.id and p.already)
  assert(I.equal(partner,S.state('wuyun')) and economy.wallet().available==balance and walletBasic()==baseline)
  local raw=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoAdoptions WHERE id=?',{old.id});assert(raw[1][1]==old.payload)
  r.active=current.id;r.checks.explicitReAdoption=true;r.checks.oldArchiveWalletAndPartnerPreserved=true
  local checkpoint=D.Content.writablePath..'/yingzhao-ui-adopted-checkpoint-'..os.time()..'.db';assert(D.DB:exec("VACUUM lsd INTO '"..checkpoint.."'")>=0);r.adoptedCheckpoint=checkpoint
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
