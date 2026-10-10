local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-review-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-trial-panel-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-trial%-panel%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync());local Trials=require('Training.FlowerQTrials');local rows=assert(Trials.loadAsync(saved.id));local Review=require('Training.FlowerQReview')
  local review=Review.build(saved.id,rows);assert(review.total==3 and review.completed==1 and not review.adoptionEligible)
  assert(review.profiles.near.basic.count==1 and review.profiles.near.evaluate.count==2)
  local expected=0;for _,row in ipairs(rows)do if row.mode=='evaluate'then for _,id in ipairs({'mentor','ninilite','wuyun'})do expected=expected+row.facts.actors[id].damageTaken end end end
  assert(math.abs(review.profiles.near.evaluate.mean.teamDamage-expected/2)<1e-7);r.allRepetitions=true
  local far=Review.text(review,'far');assert(far:find('暂不计算差值',1,true) and not review.profiles.far.delta);r.missingNotZero=true
  local function copy(v)return D.json.decode(D.json.encode(v,false,true),32)end
  local changed=copy(rows);changed[1].candidate=saved.id+1;assert(not pcall(Review.build,saved.id,changed))
  changed=copy(rows);changed[#changed+1]=copy(changed[1]);assert(not pcall(Review.build,saved.id,changed))
  changed=copy(rows);changed[1].setup.bossScale=.5;assert(not pcall(Review.build,saved.id,changed));r.mixedRejected=true
  -- Synthetic boundary only: prove losses remain in the aggregate, not a natural failed match.
  changed=copy(rows);changed[1].status='failed';local losses=Review.build(saved.id,changed);assert(losses.profiles.near.evaluate.failed==1 and losses.profiles.near.evaluate.count==2);r.syntheticFailureIncluded=true
  local panel=require('Training.FlowerQPanel').openAsync(function()end,saved.source.baseModels);panel.reviewButton:emit('Tapped')
  assert(panel.reviewing and panel.reviewBack.visible and not panel.explore.visible and not panel.back.visible)
  panel.explore:emit('Tapped');assert(not panel.busy and not panel.running)
  assert(panel.label.text:find('对照覆盖1/4',1,true));D.sleep(.2)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-review-near.tga');D.sleep(.2)
  for _,id in ipairs({'far','reproduction','field','near'})do panel.scenario:emit('Tapped');assert(panel.profile==id)end
  panel.reviewBack:emit('Tapped');assert(not panel.reviewing and panel.explore.visible and panel.back.visible);r.publicNavigation=true
  assert(#assert(Trials.loadAsync(saved.id))==3 and Store.loadAsync().id==saved.id);r.readOnly=true;r.review=review
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
