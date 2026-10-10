local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/optional-weapon-loadout-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local path=D.Content.writablePath..'/optional-weapon-loadout-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and not D.Content:exist(path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  local L=require('Economy.Loadout');local E=require('Economy.Store');assert(E.open());D.Cache:loadAsync('button.clip')
  local values=assert(L.load());local formation={mentor=true,learner='ninilite',wuyun=true};local before=assert(L.quote(values,formation)).total
  local closed,confirmed=false,0
  local v=require('UI.SupplyLoadout')({values=values,formation=formation,balance=300,confirmAsync=function()confirmed=confirmed+1;return {}end,closed=function(done)closed=done end});v:addTo(D.Director.ui3D);v:alignLayout();D.sleep(.1)
  for i=1,4 do for j=1,40 do v.buttons[i][-5]:emit('Tapped')end end
  assert(not v.quote and v.loadoutError=='EMPTY_LOADOUT');v.saveButton:emit('Tapped');D.sleep(.1);assert(not closed and confirmed==0 and not v.saving)
  assert(L.load()['mentor:kinetic']==40,'Empty selection persisted')
  v.buttons[4][1]:emit('Tapped');assert(v.quote.total==2 and v.quote.deployment==1 and #v.quote.lines==1);assert(not v.noteLabel.text:find('请先为本次出战',1,true))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/optional-weapon-loadout.tga');D.sleep(.1)
  v.saveButton:emit('Tapped');D.sleep(.2);assert(closed and confirmed==1)
  local saved=assert(L.load());assert(saved['mentor:kinetic']==0 and saved['ninilite:emp']==0 and saved['wuyun:emp']==0 and saved['wuyun:blade']==1)
  local q,why=L.quote(saved,{mentor=true,learner='ninilite'});assert(not q and why=='EMPTY_LOADOUT','Inactive member funded the quote')
  local bad=D.json.decode(D.json.encode(saved),32);bad['mentor:kinetic']=-1;assert(not L.validate(bad));bad['mentor:kinetic']=.5;assert(not L.validate(bad))
  local wallet=E.wallet();local profile=assert(L.forMission('c0-m05',formation));assert(profile.quote.total==2 and #profile.loadout==1)
  assert(E.beginAsync('optional-weapons',profile.loadout,0))
  local session=assert(require('Economy.CombatSession').open('optional-weapons'))
  assert(not session:canSpend('mentor','kinetic')and not session:canSpend('ninilite','emp')and not session:canSpend('wuyun','emp'))
  local a=require('Training.Arena').createAsync({characterId='wuyun',enemySpeed=0,enemyMaxHP=1000,manualUpdate=true});a.supplies=session;a.enemy.x=a.student.x+600;a.student.faceRight=true;D.sleep(.3)
  a.mode='trial';assert(not a:available('laser'));local accepted,why=a:request('laser','model');assert(not accepted and why=='ACTION_UNAVAILABLE'and session.emissions==0)
  local deadline=D.App.runningTime+8;while not a:available('melee')do assert(D.App.runningTime<deadline);D.sleep(.02)end
  assert(a.student:start(a.physical.melee));D.sleep(.1);while a:isAttacking()do assert(D.App.runningTime<deadline);D.sleep(.02)end
  assert(session.emissions==1 and E.load('optional-weapons').spent==2 and not a:available('melee'))
  assert(session:observation('wuyun').ammo.emp==nil and session:observation('wuyun').ammo.blade==0)
  a.closed=true;a.world:removeFromParent();assert(E.settleAsync('optional-weapons','aborted'));assert(E.wallet().available==wallet.available-2)
  local restored=assert(L.load());assert(restored['wuyun:emp']==0 and restored['wuyun:blade']==1)
  r.database=path;r.budgetBefore=before;r.budgetAfter=profile.quote.total;r.checks={'zero quantity persisted','omitted weapons have no deployment cost','empty active formation blocked without saving','negative and fractional amounts rejected','unprovisioned EMP cannot fire','provisioned blade actually consumes once','wallet and inventory settle consistently'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
