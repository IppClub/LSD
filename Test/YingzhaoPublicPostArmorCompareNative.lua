-- Compare the candidate built through public post-armor demonstration/learning.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-public-post-armor-compare-result.json'
local r={status='RUNNING',osInput=false,automaticAdoption=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  local recent=os.getenv('LSD_QA_RECENT_COMPARE')=='1'
  local tactical=os.getenv('LSD_QA_TACTICAL_COMPARE')=='1'
  local protection=os.getenv('LSD_QA_WUYUN_PROTECTION_COMPARE')=='1'
  assert(not (recent and tactical or recent and protection or tactical and protection),'Select only one comparison source')
  local actor=(tactical or protection)and'wuyun'or'ninilite'
  if tactical then assert(prior.publicTacticalLesson and prior.characterId==actor,'Expected actual Wuyun public tactical lesson')end
  if protection then assert(prior.actor=='wuyun'and prior.coverage.retreat>0 and prior.model.characterId=='wuyun','Expected actual saved protection lesson')end
  local parentDB=recent and prior.recentCandidateCheckpoint or prior.database
  assert(prior.status=='PASS'and prior.protectedStateUnchanged)
  local sourcePattern=protection and '^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-wuyun%-protection%-%d+%.db$'or tactical and '^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-tactical%-lesson%-%d+%.db$'or (recent and '^/private/tmp/lsd%-combat%-qa%-.+/save/recent%-candidate%-checkpoint%-%d+%.db$'or '^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-public%-post%-armor%-%d+%.db$')
  assert(type(parentDB)=='string' and parentDB:match(sourcePattern),'Unexpected source database')
  r.recentSourceOnly=recent or tactical;r.publicTacticalComparison=tactical;r.publicProtectionComparison=protection;r.characterId=actor
  local db=D.Content.writablePath..'/yingzhao-public-post-armor-compare-'..os.time()..'.db';r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(parentDB,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local S=require('Training.YingzhaoAdoptionStore');local I=require('Training.FlowerIdentity')
  local function protected()return {wallet=E.wallet().available,basic=D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),other=D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),missions=D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),ninilite=S.state('ninilite'),wuyun=S.state('wuyun')}end
  local before=protected();local candidate=assert(require('Training.YingzhaoPolicyStore').loadLatestAsync(actor));assert(candidate.id==(recent and prior.recentCandidate or prior.newCandidate) and I.equal(candidate.model,recent and prior.recentModel or prior.model))
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Public post-armor comparison timeout');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,actor);wait(controls)
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
  if os.getenv('LSD_QA_SUPPORT_SUMMARY')=='1'then
   local Store=require('Training.YingzhaoComparisonStore')
   assert(report.supportAccountingVersion==1 and r.text:find('维生',1,true)and r.text:find('机体生命',1,true))
   for _,round in ipairs(report.rounds)do
    local a=round.trace.supportAccounting;local summary=round.supportSummary
    assert(summary.goldSpent==a.goldSpent and summary.upkeepGold==a.upkeepGold and summary.machineDamage==a.machineDamage)
   end
   local forged=D.json.decode(D.json.encode(report,false,true),32)
   forged.rounds[2].supportSummary.upkeepGold=forged.rounds[2].supportSummary.upkeepGold+1
   local valid,why=Store.validate(forged);assert(not valid and why=='SUPPORT_SUMMARY_MISMATCH')
   forged=D.json.decode(D.json.encode(report,false,true),32);forged.rounds[1].supportSummary=nil
   valid,why=Store.validate(forged);assert(not valid and why=='MISSING_SUPPORT_SUMMARY')
   local previous=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PREVIOUS_COMPARISON'))),32)
   assert(previous.status=='PASS'and previous.report.supportAccountingVersion==nil)
   assert(Store.validate(previous.report))
   assert(require('Training.YingzhaoComparison').text(previous.report):find('历史报告未单列',1,true))
   r.supportSummaryVerified=true;r.forgedSummaryRejected=true;r.oldComparisonPreserved=true
  end

  view.backButton:emit('Tapped');wait(controls);assert(I.equal(before,protected()),'Comparison changed adoption, wallet, basic models or mission state')
  r.protectedStateUnchanged=true;r.fullNaturalComparison=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
