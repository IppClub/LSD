local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-history-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior='/private/tmp/lsd-combat-qa-tqw7b37d/save/yingzhao-compare-1791254542.db'
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-history-'..os.time()..'.db';r.database=db;assert(D.Content:copyAsync(prior,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local store=require('Training.YingzhaoComparisonStore');local ids=assert(store.list());assert(#ids==1);local saved=assert(store.load(ids[1]));assert(store.saveAsync(saved)==ids[1])
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<stop,'History timeout');D.sleep(.02)end end
  require('Training.Level')(nil,'ninilite');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local controls=D.Director.ui3D:getChildByTag('training-controls');controls:getChildByTag('training-menu'):getChildByTag('部位记录'):emit('Tapped')
  local view=assert(D.Director.ui3D:getChildByTag('yingzhao-history'));assert(view.record and view.label.text:find('候选',1,true));view.backButton:emit('Tapped');assert(controls.visible)
  local payload=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoComparisons WHERE id=?',{ids[1]})[1][1]
  local bad=D.json.decode(payload,32);bad.rounds[1].armorDamage=999
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoComparisons SET payload=? WHERE id=?',{D.json.encode(bad),ids[1]})>=0)
  controls:getChildByTag('training-menu'):getChildByTag('部位记录'):emit('Tapped');view=D.Director.ui3D:getChildByTag('yingzhao-history');assert(not view.record and view.label.text:find('未通过核对',1,true));view.backButton:emit('Tapped')
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoComparisons SET payload=? WHERE id=?',{payload,ids[1]})>=0)
  r.coldRead=true;r.publicEntry=true;r.corruptionRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
