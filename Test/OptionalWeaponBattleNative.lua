local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/optional-weapon-battle-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-small-target-fallback-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-small%-target%-fallback%-%d+%.db$'))
  local dest=D.Content.writablePath..'/optional-weapon-battle-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local candidate=assert(require('Training.ResourceQStore').loadLatestAsync());local L=require('Economy.Loadout');local values=L.defaults()
  values['mentor:kinetic']=60;values['ninilite:emp']=0;values['wuyun:emp']=0;values['wuyun:blade']=60;assert(L.saveAsync(values))
  local E=require('Economy.Store');assert(E.open());local wallet=E.wallet();local supplies
  local view=require('UI.SupplyLoadout')({virtual=true,virtualMode='compare',values=assert(L.load()),formation={mentor=true,learner='ninilite',wuyun=true},closed=function(done,selection)assert(done);supplies=selection.loadout end})
  view:addTo(D.Director.ui3D);view:alignLayout();assert(view.quote.total==183 and view.quote.deployment==3);view.saveButton:emit('Tapped');local deadline=D.App.totalTime+5
  while not supplies do assert(D.App.totalTime<deadline);D.sleep(.02)end;assert(#supplies==2)
  local result=require('Training.FlowerQSession').runAsync({mode='basic',models=candidate.bundle.baseModels,profile='field',virtualSupplies=supplies})
  assert(result.status=='won' or result.status=='failed');r.outcome=result.status;r.cost=result.episode.resources.spent;r.seconds=result.report.seconds
  for _,step in ipairs(result.episode.steps)do assert(step.action.weapon~='emp' or (step.action.emitted or 0)==0,'Unprovisioned EMP emitted')end
  for _,actor in ipairs({'ninilite','wuyun'})do
   assert(#result.trace.actors[actor].steps>0)
   for _,row in ipairs(result.trace.actors[actor].steps)do assert(require('Training.ResourceFeatures').project(row.state).empAmmo=='unequipped')end
  end
  local P=require('Training.ResourcePracticeStore');local yes,why,id=P.saveRunAsync(result);assert(yes,tostring(why));local source=assert(P.loadVersionAsync(id));assert(source.review.trainable)
  assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
  assert(L.load()['ninilite:emp']==0 and L.load()['wuyun:emp']==0)
  r.budget=183;r.source=id;r.checks={'virtual loadout entry preserves omitted weapons','complete natural battle with zero EMP','unequipped observation retained for both learners','no unprovisioned projectile','resource practice saved and rebuilt','formal wallet unchanged'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
