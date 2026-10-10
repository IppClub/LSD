local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-comparison-history-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-wuyun-comparison-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-comparison%-ui%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-comparison-history-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local untilAt=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<untilAt,'History UI timeout');D.sleep(.05)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();require('Training.Level')(nil,'wuyun');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local controls=D.Director.ui3D:getChildByTag('training-controls')
  local function open()
   controls:getChildByTag('training-menu'):getChildByTag('对照记录'):emit('Tapped')
   local v=D.Director.ui3D:getChildByTag('disarm-comparison-history');assert(v and not controls.visible);collectgarbage('collect');assert(v.label);return v
  end
  local view=open();assert(#view.ids==2 and view.index==1 and view.record.id==view.ids[1]);assert(view.label.text:find('乌云',1,true)and view.label.text:find('候选 #2',1,true));assert(not view.retryButton.visible)
  local firstId=view.record.id;view.next:emit('Tapped');assert(view.record.id~=firstId);view.previous:emit('Tapped');assert(view.record.id==firstId);r.navigation=true
  D.sleep(.2);r.screenshot=D.Content.writablePath..'/comparison-history.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
  view.backButton:emit('Tapped');assert(controls.visible and not D.Director.ui3D:getChildByTag('disarm-comparison-history'));r.sameTrainingReturned=true
  local payload=assert(D.DB:query('SELECT payload FROM lsd.Game0DisarmComparisons WHERE id=?',{firstId}))[1][1]
  assert(D.DB:exec('UPDATE lsd.Game0DisarmComparisons SET payload=? WHERE id=?',{'broken-json',firstId})==1)
  view=open();assert(not view.record and view.label.text:find('未通过',1,true));view.next:emit('Tapped');assert(view.record);r.corruptRecordSkippable=true;view.backButton:emit('Tapped')
  assert(D.DB:exec('UPDATE lsd.Game0DisarmComparisons SET payload=? WHERE id=?',{payload,firstId})==1)
  local Store=require('Training.DisarmComparisonStore');assert(not Store.load(-1));assert(not Store.load('1'));assert(not Store.load(999999))
  assert(D.DB:exec('DELETE FROM lsd.Game0DisarmComparisons')==2)
  view=open();assert(#view.ids==0 and not view.previous.visible and not view.next.visible and view.label.text:find('尚无',1,true));view.backButton:emit('Tapped');r.empty=true
  assert(snapshot()==before);r.trainingUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
