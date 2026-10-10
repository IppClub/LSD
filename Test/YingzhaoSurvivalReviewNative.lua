-- Read-only rendering of a real saved formal loss and real paired comparison.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/yingzhao-survival-review-result.json'
local r={status='RUNNING',osInput=false,readOnlyHistoricalReview=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(prior.outcome=='failed' and prior.episodeSaved and prior.returnedToTrain)
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-big%-yingzhao%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/survival-review-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local before=D.Content:load(db)
  local attempt=tonumber(prior.battle.economy.attempt:match('(%d+)$'))
  local episode=assert(require('Training.CombatStore').load(attempt))
  local I=require('Training.FlowerIdentity');local original=D.json.decode(D.json.encode(episode),32)
  local C=require('Training.YingzhaoContributions');local F=require('Training.YingzhaoSurvivalFeedback')
  local summary=assert(F.summarize(episode.boss.vitals));r.summary=summary
  assert(math.abs(summary.ninilite.meleeDamage-77.22420358657837)<1e-6)
  assert(summary.ninilite.healing==0 and summary.ninilite.final==0)
  assert(math.abs(summary.wuyun.healing-74.85074329376222)<1e-6)
  local text=C.text(episode.boss);assert(text:find('生命复盘',1,true))
  local function screenshot(name)D.App:saveScreenshot(root..'/Test/survival-'..name..'.tga');D.sleep(.3)end
  local function scrollLife(view)
   local prefix=view.label.text:match('^(.-)生命复盘')
   local measure=assert(D.Label('SourceHanSansCN-Regular',25));measure.visible=false;measure.textWidth=1110;measure.text=prefix
   local offset=math.max(0,measure.height-10);measure:cleanup();view.area:scrollTo(D.Vec2(0,offset));D.sleep(.3)
  end
  r.layouts={}
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.4)
   local screen=D.App.bufferSize;local name=string.format('%dx%d',screen.width,screen.height)
   local view=require('UI.MissionFail')({missionMode=true,missionTitle='大英招讨伐',economy=prior.battle.economy,reportText=text})
   view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.4)
   assert(not view.reportPanel)
   screenshot(name..'-failure')
   view.reportButton:emit('Tapped');assert(view.reportPanel and not view.visible)
   local popup=view.reportPanel;assert(popup.label.text:find('生命复盘',1,true))
   scrollLife(popup);screenshot(name..'-life')
   r.layouts[#r.layouts+1]={width=screen.width,height=screen.height,textHeight=popup.label.height,scrollHeight=popup.area.viewSize.height}
   popup.backButton:emit('Tapped');assert(view.visible and not view.reportPanel and popup.parent==view)
   screenshot(name..'-returned')
   view.reportButton:emit('Tapped');assert(view.reportPanel==popup and popup.parent==D.Director.ui3D)
   popup.backButton:emit('Tapped');assert(popup.parent==view);view:removeFromParent()
  end
  local paired=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_COMPARISON_RESULT'))),32)
  assert(paired.status=='PASS' and paired.report and #paired.report.rounds==2)
  local report=paired.report;local originalReport=D.json.decode(D.json.encode(report),32)
  local compared=require('Training.YingzhaoComparison').text(report)
  local _,count=compared:gsub('生命复盘','');assert(count==2)
  local view=require('UI.DisarmComparison')({title='大英招 · 训练对照生命复盘',summary=compared})
  view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.3);scrollLife(view);screenshot('comparison-life');view:removeFromParent()
  assert(I.equal(episode,original)and I.equal(report,originalReport),'Read-only feedback changed records')
  local old=D.json.decode(D.json.encode(episode.boss),32);old.vitals=nil
  assert(C.text(old):find('历史记录未保存生命变化',1,true))
  assert(D.Content:load(db)==before,'Review changed actual database')
  r.actualEpisodeColdRead=true;r.actualComparisonReviewed=true;r.databaseUnchanged=true;r.recordsUnchanged=true;r.returned=true;r.text=text
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
