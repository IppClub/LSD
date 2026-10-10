-- Reopen real joint evidence in a fresh process and exercise public navigation.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/flower-team-cold-read-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-native-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-native%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-team-cold-read-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local T=require('Training.FlowerTeamTrials');local P=require('Training.FlowerPractice');local S=require('Training.FlowerTrialStore')
  local equal=require('Training.FlowerIdentity').equal
  local function copy(x)return D.json.decode(D.json.encode(x,false,true),32)end
  local rows=assert(T.history());assert(#rows==8);local sources=assert(P.teamSources());local models=assert(P.models())
  local review=assert(T.review(sources,models,rows));assert(review.completed==4)
  assert(require('Training.FlowerAdoptionReview').sameAssessment(review,prior.review));r.coldRead=true
  for _,record in ipairs(rows)do
   assert(not S.validate(record))
   local disguised=copy(record);disguised.teamSources=nil;disguised.setup.teamPolicies=nil;disguised.setup.teamVersion=nil;disguised.setup.teamFormation=nil
   assert(not S.validate(disguised),'Joint context accepted by single store')
  end;r.singleContextRejected=true
  local singles=assert(S.history('ninilite'));assert(#singles>0 and not T.validate(singles[1]));assert(not T.compare(singles[1],rows[1]));r.mixedPairRejected=true
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState'),false,true)
  local function wait(fn)local deadline=D.App.totalTime+15;while not fn()do assert(D.App.totalTime<deadline,'Navigation timeout');D.sleep(.02)end end
  local c=P.openAsync(nil,'wuyun');D.sleep(.3)
  local function press(button)
   local old=c.ui;button:emit('Tapped');wait(function()local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');return ui and ui~=old end)
   c=D.Director.ui3D:getChildByTag('flower-practice-controls').practice;D.sleep(.2)
  end
  press(c.teamButton);assert(c.profile.id=='field' and c.context.returnCharacter=='wuyun')
  for _,id in ipairs({'near','far','reproduction','field'})do
   press(c.scenarioButton);assert(c.profile.id==id and c.context.returnCharacter=='wuyun' and equal(c.teamSources,sources));assert(c.teamReview.completed==4)
  end
  press(c.restartButton);assert(c.profile.id=='field' and c.context.returnCharacter=='wuyun')
  assert(not c.hud.visible and not c.adoptionButton.visible);r.profileCycle=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-team-cold-read.tga');D.sleep(.2)
  c.backButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  assert(D.Director.ui3D:getChildByTag('training-controls').arena.character.id=='wuyun');r.returnedToWuyun=true
  assert(#assert(T.history())==8);assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState'),false,true));r.noAdoptionMutation=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
