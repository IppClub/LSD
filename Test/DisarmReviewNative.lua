local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-review-ui-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-performance-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/lsd%-disarm%-practice%-qa%-%d+%.db$'))
  local dest=D.Content.writablePath..'/disarm-review-'..os.time()..'.db';r.database=dest
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local untilAt=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<untilAt,'review timeout');D.sleep(.02)end end
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0DisarmObservations'),D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun')},false,true)end
  local before=saved();require('Training.Level')(nil,'ninilite');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local ui=D.Director.ui3D:getChildByTag('training-controls');local arena=ui.arena;local mode=arena.mode
  ui:getChildByTag('training-menu'):getChildByTag('缴械复盘'):emit('Tapped')
  local panel=assert(D.Director.ui3D:getChildByTag('disarm-review'));assert(not ui.visible and not D.Director.ui3D:getChildByTag('trainingHUD').visible)
  assert(panel.record and panel.label.text:find('模拟总成本',1,true));r.count=#panel.ids;r.cost=panel.record.review.total
  if #panel.ids>1 then local first=panel.record.id;panel.next:emit('Tapped');assert(panel.record.id~=first);panel.previous:emit('Tapped');assert(panel.record.id==first);r.navigation=true end
  if #panel.ids>1 then panel.next:emit('Tapped')end;assert(panel.record.source.trace.vitalsVersion==1 and panel.label.text:find('队伍累计承伤',1,true));r.vitalsDisplayed=true
  D.sleep(.5);r.screenshot=D.Content.writablePath..'/disarm-review.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
  assert(panel.area.viewSize.height>panel.area.height);panel.area:scrollToPosY(-10000,0);D.sleep(.2);r.bottomScreenshot=D.Content.writablePath..'/disarm-review-bottom.tga';D.App:saveScreenshot(r.bottomScreenshot);D.sleep(.2)
  panel.closeButton:emit('Tapped');assert(ui.visible and ui.arena==arena and arena.mode==mode);assert(saved()==before);r.returned=true;r.recordsUnchanged=true
  local rows=D.DB:query('SELECT id,payload FROM lsd.Game0DisarmObservations ORDER BY id DESC');assert(#rows>0)
  assert(D.DB:exec('UPDATE lsd.Game0DisarmObservations SET payload=? WHERE id=?',{'invalid',rows[1][1]})>=0)
  panel=require('UI.DisarmReview')({});assert(not panel.record and panel.label.text:find('未通过读取核对',1,true));r.corruptHandled=true;panel:cleanup()
  assert(D.DB:exec('UPDATE lsd.Game0DisarmObservations SET payload=? WHERE id=?',{rows[1][2],rows[1][1]})>=0)
  assert(saved()==before)
  assert(D.DB:exec('DELETE FROM lsd.Game0DisarmObservations')>=0)
  panel=require('UI.DisarmReview')({});assert(#panel.ids==0 and not panel.next.visible and panel.label.text:find('完成一次缴械演练',1,true));r.emptyHandled=true;panel:cleanup()
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
