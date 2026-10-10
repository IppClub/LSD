-- Cold-read a real failed formal battle; verify display accounting without changing it.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/yingzhao-emp-feedback-result.json';local r={status='RUNNING',osInput=false,displayOnly=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(prior.operationVariant=='visible-remote-interior-no-chase-public-route-v11'and prior.outcome=='failed')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-emp-feedback-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local rows=assert(D.DB:query('SELECT payload FROM lsd.Game0CombatEpisodes WHERE attempt=8'))
  local e=D.json.decode(rows[1][1],32);assert(require('Enemy.BigYingzhaoEvidence').validate(e))
  local equal=require('Training.FlowerIdentity').equal;assert(equal(e,prior.uncommittedEpisode))
  local before=D.json.decode(D.json.encode(e),32);local C=require('Training.YingzhaoContributions')
  local summary=C.summarize(e.boss);r.summary=summary
  local n,w=summary.actors.ninilite,summary.actors.wuyun
  assert(n.empNoEffectBossHits==11 and w.empNoEffectBossHits==3)
  assert(n.empKnownExposedHits==10 and w.empKnownExposedHits==2)
  assert(n.empNoEffectCost==44 and w.empNoEffectCost==12)
  assert(summary.totalCost==167 and summary.actionCost+summary.deployment==167)
  -- Legacy traces lacking decision geometry retain actual hit/cost accounting,
  -- but must not fabricate knowledge at the time of the shot.
  local legacy=D.json.decode(D.json.encode(e.boss),32);legacy.steps=nil
  local old=C.summarize(legacy);assert(old.actors.ninilite.empKnownExposedHits==0)
  assert(old.actors.ninilite.empNoEffectBossHits==11 and old.actors.ninilite.empNoEffectCost==44)
  local text=C.text(e.boss);assert(text:find('EMP只削减护甲',1,true))
  assert(text:find('对应耗材 44',1,true)and text:find('对应耗材 12',1,true))
  assert(equal(e,before),'Display changed actual episode')
  local view=require('UI.Settlement')({missionMode=true,resultStatus='Failed',missionTitle='大英招讨伐',reportText=text,economy=prior.battle.economy})
  view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.2)
  assert(view.resultLayout=='MissionFail');view.reportButton:emit('Tapped');D.sleep(.2)
  assert(view.reportPanel and view.reportLabel.text:find('EMP只削减护甲',1,true))
  r.screenshots={}
  for _,size in ipairs({{1920,1080},{1366,768}})do
   D.App.winSize=D.Size(size[1]/2,size[2]/2);view.reportPanel:alignLayout();D.sleep(.2)
   view.reportArea:scrollTo(D.Vec2(0,250));D.sleep(.2)
   local path=root..'/Test/yingzhao-emp-feedback-'..size[1]..'.tga';D.App:saveScreenshot(path);D.sleep(.2);r.screenshots[#r.screenshots+1]=path
  end
  view.reportPanel.backButton:emit('Tapped');assert(not view.reportPanel and view.visible)
  view:removeFromParent();assert(equal(e,before));r.failureReportAndReturn=true;r.text=text
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
