local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/supply-loadout-native-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local path=D.Content.writablePath..'/supply-loadout-'..os.time()..'.db';assert(not D.DB:existDB('lsd') and not D.Content:exist(path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  D.Cache:loadAsync('button.clip')
  local L=require('Economy.Loadout');local values=assert(L.load());local formation={mentor=true,learner='ninilite',wuyun=true}
  local originalQuantity=values['mentor:kinetic']
  local before=assert(L.quote(values,formation)).total
  local saved
  local v=require('UI.SupplyLoadout')({values=values,formation=formation,balance=300,closed=function(value)saved=value end});v:addTo(D.Director.ui3D);v:alignLayout();D.sleep(.2)
  assert(v.summaryLabel.text:find('-193 至 +91',1,true),'Missing net range')
  v.buttons[1][1]:emit('Tapped');assert(v.quote.total==before+2)
  v.buttons[1][-1]:emit('Tapped');assert(v.quote.total==before)
  v.buttons[1][5]:emit('Tapped');assert(v.quote.total==before+10)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/supply-loadout.tga');D.sleep(.1)
  v.saveButton:emit('Tapped');D.sleep(.2);assert(saved==true and L.load()['mentor:kinetic']==originalQuantity+5)
  assert(L.quote(values,{mentor=true}).total==(originalQuantity+5)*2+2)
  local persisted=assert(L.load());local closed
  local cancelled=require('UI.SupplyLoadout')({values=persisted,formation=formation,balance=20,closed=function(value)closed=value end});cancelled:addTo(D.Director.ui3D);cancelled:alignLayout()
  cancelled.defaultsButton:emit('Tapped');assert(cancelled.quote.total==before and L.load()['mentor:kinetic']==originalQuantity+5)
  cancelled.buttons[1][5]:emit('Tapped');cancelled.closeButton:emit('Tapped');assert(closed==false and L.load()['mentor:kinetic']==originalQuantity+5)
  assert(not L.saveAsync({}));r.budget=before+10;r.savedQuantity=originalQuantity+5;r.checks={'original artwork rendered','live budget','single-unit adjustment','success cost range','formation filtering','persisted selection','cancel preserves save','invalid configuration rejected'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
