local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/loadout-advice-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local L=require('Economy.Loadout');local values=L.defaults();values['ninilite:emp']=0
  D.Cache:loadAsync('button.clip');local confirmed,closed=false,false
  local path=D.Content.writablePath..'/loadout-advice-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  local v=require('UI.SupplyLoadout')({mission='c0-m01',values=values,formation={mentor=true,learner='ninilite'},balance=300,confirmAsync=function()confirmed=true;return {}end,closed=function(done)closed=done end})
  v:addTo(D.Director.ui3D);v:alignLayout();D.sleep(.1)
  assert(v.quote.total==82 and v.loadoutAdvice:find('未携带',1,true)and v.noteLabel.text:find('2波各至少2次',1,true))
  v.buttons[2][1]:emit('Tapped');assert(v.loadoutAdvice:find('可能不足',1,true)and v.quote.total==89)
  for i=1,3 do v.buttons[2][1]:emit('Tapped')end
  assert(v.loadoutAdvice:find('预留脱靶余量',1,true)and v.quote.total==101)
  -- Requirements come from the same authored rule used by the battle.
  local task=require('Mission.Catalog')['c0-m01'];task.learnerHitsPerWave=3
  assert(require('Economy.LoadoutAdvice').text('c0-m01',v.values,{learner='ninilite'}):find('各至少3次',1,true));task.learnerHitsPerWave=2
  for i=1,4 do v.buttons[2][-1]:emit('Tapped')end
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/loadout-advice.tga');D.sleep(.15)
  v.saveButton:emit('Tapped');local deadline=D.App.totalTime+5;while not closed do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(confirmed and L.load()['ninilite:emp']==0,'Advice silently changed or blocked the player choice')
  assert(require('Economy.LoadoutAdvice').text('c0-m05',values,{learner='ninilite'})==nil)
  local virtual=require('UI.SupplyLoadout')({mission='c0-m01',virtual=true,values=values,formation={mentor=true,learner='ninilite'}})
  virtual:addTo(D.Director.ui3D);virtual:alignLayout();assert(not virtual.loadoutAdvice);virtual:removeFromParent()
  r.checks={'live zero/low/reserve guidance','shared authored hit requirement','no quantity mutation or extra confirmation','other tasks and virtual practice do not inherit guard requirements'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
