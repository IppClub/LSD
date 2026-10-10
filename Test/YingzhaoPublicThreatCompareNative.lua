-- Compare the candidate built through public post-armor demonstration/learning.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-public-threat-compare-result.json'
local r={status='RUNNING',osInput=false,automaticAdoption=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS'and prior.protectedStateUnchanged and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-threat%-lesson%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-public-threat-compare-'..os.time()..'.db';r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local S=require('Training.YingzhaoAdoptionStore');local I=require('Training.FlowerIdentity')
  local function protected()return {wallet=E.wallet().available,basic=D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),other=D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),missions=D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),ninilite=S.state('ninilite'),wuyun=S.state('wuyun')}end
  local before=protected();local candidate=assert(require('Training.YingzhaoPolicyStore').loadLatestAsync('ninilite'));assert(candidate.id==prior.newCandidate and I.equal(candidate.model,prior.model))
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Public threat comparison timeout');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位对照'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-budget')end)
  D.Director.ui3D:getChildByTag('yingzhao-comparison-budget').saveButton:emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-result')end,420)
  local view=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');assert(view.saved,view.saveError or view.error)
  local report=assert(require('Training.YingzhaoComparisonStore').load(view.saved));r.report=report;r.comparisonId=view.saved
  r.rawVisibleEqual=I.equal(report,view.report);r.normalizedVisible=D.json.decode(D.json.encode(view.report,false,true),32)
  r.numericDifferences={};local otherDifference=false
  local function difference(stored,visible,path)
   if type(stored)~=type(visible)then otherDifference=true;return end
   if type(stored)=='table'then
    for k,v in pairs(stored)do difference(v,visible[k],path..'/'..tostring(k))end
    for k in pairs(visible)do if stored[k]==nil then otherDifference=true end end
   elseif stored~=visible then
    if type(stored)=='number'then r.numericDifferences[#r.numericDifferences+1]={path=path,stored=stored,visible=visible,delta=math.abs(stored-visible)}
    else otherDifference=true end
   end
  end
  difference(report,view.report,'');r.nonNumericDifference=otherDifference;save()
  assert(not otherDifference,'Visible report differs beyond numeric serialization')
  for _,d in ipairs(r.numericDifferences)do assert(d.delta<=1e-10*math.max(1,math.abs(d.stored)),'Visible report materially changed after save')end
  assert(I.equal(report,r.normalizedVisible),'Canonical visible report differs from saved report')
  assert(I.equal(report.candidate,candidate.model),'Candidate changed during comparison')
  assert(#report.rounds==2 and report.rounds[1].mode=='baseline'and report.rounds[2].mode=='candidate')
  r.comparisonId=view.saved;r.report=report;r.effects={}
  for _,round in ipairs(report.rounds)do r.effects[#r.effects+1]=require('Training.YingzhaoContributions').summarize(round.trace)end
  r.text=require('Training.YingzhaoComparison').text(report);save()
  view.backButton:emit('Tapped');wait(controls);assert(I.equal(before,protected()),'Comparison changed adoption, wallet, basic models or mission state')
  r.protectedStateUnchanged=true;r.fullNaturalComparison=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
