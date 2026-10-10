local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/energy-budget-advice-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.Cache:loadAsync('button.clip');local L=require('Economy.Loadout');local advice=require('Economy.LoadoutAdvice')
  local formation={mentor=true,learner='ninilite',wuyun=true}
  for _,empty in ipairs({false,true})do
   local values=L.defaults();if empty then for k in pairs(values)do values[k]=0 end end
   local v=require('UI.SupplyLoadout')({mission='c0-m03',values=values,formation=formation,balance=300})
   v:addTo(D.Director.ui3D);v:alignLayout();D.sleep(.1)
   assert(v.loadoutAdvice:find('两侧学员都需命中',1,true)and v.loadoutAdvice:find('耗尽后',1,true))
   assert(v.noteLabel.height<=42.5,'Advice overflows the bottom of the budget panel')
   if empty then r.emptyScreenshot=D.Content.writablePath..'/energy-advice-empty.tga';D.App:saveScreenshot(r.emptyScreenshot);D.sleep(.15)end
   if empty then
    assert(not v.quote and v.loadoutAdvice:find('妮妮EMP',1,true)and v.loadoutAdvice:find('乌云EMP/近战',1,true))
    v.buttons[2][1]:emit('Tapped');assert(not v.loadoutAdvice:find('妮妮EMP',1,true))
    v.buttons[4][1]:emit('Tapped');assert(not v.loadoutAdvice:find('乌云EMP/近战',1,true))
    assert(v.values['mentor:kinetic']==0 and v.values['wuyun:emp']==0)
   end
   local path=D.Content.writablePath..'/energy-advice-'..tostring(empty)..'.tga';D.App:saveScreenshot(path);D.sleep(.15)
   r.cases[#r.cases+1]={initialEmpty=empty,height=v.noteLabel.height,screenshot=path};v:removeFromParent()
  end
  assert(advice.text('c0-m03',L.defaults(),{mentor=true}):find('同时编入',1,true))
  local v=require('UI.SupplyLoadout')({mission='c0-m03',virtual=true,values=L.defaults(),formation=formation,balance=300})
  assert(not v.loadoutAdvice);v:cleanup();assert(not D.DB:existDB('lsd'));r.noSaveWrites=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
