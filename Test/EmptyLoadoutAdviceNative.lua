local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/empty-loadout-advice-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.Cache:loadAsync('button.clip');local L=require('Economy.Loadout');local values=L.defaults()
  values['mentor:kinetic']=0;values['ninilite:emp']=4;values['wuyun:emp']=0;values['wuyun:blade']=0
  local confirmed=false
  local view=require('UI.SupplyLoadout')({mission='c0-m01',values=values,formation={mentor=true,learner='ninilite'},balance=300,confirmAsync=function()confirmed=true;return {}end})
  view:addTo(D.Director.ui3D);view:alignLayout();assert(view.quote.total==19 and view.loadoutAdvice:find('预留脱靶',1,true))
  for i=1,4 do view.buttons[2][-1]:emit('Tapped')end
  assert(not view.quote and view.loadoutAdvice:find('未携带学员EMP',1,true)and view.noteLabel.text:find('未携带学员EMP',1,true),'Empty budget retained previous guidance')
  assert(not view.noteLabel.text:find('当前EMP 4发',1,true))
  view.saveButton:emit('Tapped');assert(not confirmed and not view.saving and view.noteLabel.text:find('至少一种补给',1,true))
  view.buttons[2][1]:emit('Tapped');assert(view.quote.total==7 and view.loadoutAdvice:find('当前EMP仅1发',1,true))
  assert(not view.noteLabel.text:find('至少一种补给',1,true),'Validation message persisted after correction')
  view:removeFromParent();r.checks={'live advice on zero budget','empty confirmation blocked','adding one unit clears stale error'}
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
