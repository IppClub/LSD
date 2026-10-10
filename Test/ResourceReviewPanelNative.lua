local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-review-panel-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-q-frozen-trials-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-[%w_%-]+/save/resource%-q%-trials%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local raw=D.json.decode(D.DB:query('SELECT payload FROM lsd.Game0ResourceQCandidates ORDER BY id DESC LIMIT 1')[1][1],32)
  local rebuilt
  for _,id in ipairs(raw.sourceIds)do local entry=assert(require('Training.ResourcePracticeStore').loadVersionAsync(id));rebuilt=assert(require('Training.ResourceQ').learn(entry.source.trace,entry.source.episode,entry.source.status,rebuilt))end
  local differences={}
  local function compare(a,b,path)
   if type(a)~=type(b)then differences[#differences+1]=path..': type';return end
   if type(a)=='table'then for k,v in pairs(a)do compare(v,b[k],path..'.'..tostring(k))end;for k in pairs(b)do if a[k]==nil then differences[#differences+1]=path..'.'..tostring(k)..': missing'end end
   elseif a~=b then differences[#differences+1]=path..': '..tostring(a)..' vs '..tostring(b)end
  end
  compare(raw.models,rebuilt,'models');r.rebuildDifferences=differences
  local candidate=assert(require('Training.ResourceQStore').loadLatestAsync())
  D.Cache:loadAsync('button.clip');local panel=require('Training.FlowerQPanel').openAsync(function()end,candidate.bundle.baseModels)
  assert(panel.resourceReviewButton.visible);panel.resourceReviewButton:emit('Tapped')
  local deadline=D.App.totalTime+10;while not panel.resourceReviewView do assert(D.App.totalTime<deadline,panel.message);D.sleep(.02)end
  local view=panel.resourceReviewView;assert(#view.groups==1);local group=view.groups[1]
  assert(group.basic.count==1 and group.evaluate.count==1)
  for _,trial in ipairs(prior.trials)do assert(group[trial.mode].cost==trial.cost and group[trial.mode].wins==(trial.status=='won'and 1 or 0))end
  assert(view.label.text:find('训练目标：全队存活并清场',1,true));if group.basic.wins==0 and group.evaluate.wins==0 then assert(view.label.text:find('两组均未取得胜利',1,true))end;D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/resource-review-top.tga');D.sleep(.1)
  view.area:scrollToPosY(-10000,0);D.sleep(.1);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/resource-review-bottom.tga');D.sleep(.1)
  view.back:emit('Tapped');assert(panel.node.visible and not panel.busy and not panel.resourceReviewView)
  r.checks={'real saved trials rebuilt','player review entry','same loadout grouped','failure not presented as saving','scroll to conclusion','return restores training'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
