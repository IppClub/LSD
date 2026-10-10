local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-budget-advice-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.Cache:loadAsync('button.clip');local L=require('Economy.Loadout');local formation={mentor=true,learner='ninilite',wuyun=true}
  local configurations={{name='default',values=L.defaults()},{name='one-each',values={['mentor:kinetic']=1,['ninilite:emp']=1,['wuyun:emp']=1,['wuyun:blade']=1}},{name='no-blade',values=L.defaults()}}
  configurations[3].values['wuyun:blade']=0
  for _,config in ipairs(configurations)do
   D.Director.ui3D:removeAllChildren();local view=require('UI.SupplyLoadout')({mission='c0-disarm',values=config.values,formation=formation,balance=400,confirmAsync=function()error('Preview must not create an attempt')end})
   view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.2)
   assert(view.noteLabel.text:find('未用补给退回',1,true)and view.noteLabel.text:find('实际消耗加整备',1,true))
   if config.name=='one-each'then assert(view.noteLabel.text:find('增加承伤',1,true))end
   if config.name=='no-blade'then assert(view.noteLabel.text:find('未配近战',1,true))end
   assert(view.noteLabel.height<49,'Budget hint overlaps bottom buttons: '..view.noteLabel.height)
   local screenshot=D.Content.writablePath..'/disarm-budget-'..config.name..'.tga';D.App:saveScreenshot(screenshot);D.sleep(.15)
   r.cases[#r.cases+1]={name=config.name,budget=view.quote.total,hintHeight=view.noteLabel.height,screenshot=screenshot}
   if config.name=='one-each'then view.buttons[4][-1]:emit('Tapped');assert(view.noteLabel.text:find('未配近战',1,true));assert(view.values['wuyun:blade']==0)end
   view.closeButton:emit('Tapped')
  end
  assert(not D.DB:existDB('lsd'));r.noSaveWrites=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
