-- Formal paid firing with idle-model fixtures, isolating original-owner billing.
-- Enemy approach, theft, shot, empty-gun melee and return use their real AI/actions.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ground-disarm-ownership-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/ground-disarm-ownership-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn,seconds)local endAt=D.App.runningTime+(seconds or 20);while not fn()do assert(D.App.runningTime<endAt,'Ownership timeout '..tostring(r.stage));D.sleep(.02)end end
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local E=require('Economy.Store');assert(E.open());local S=assert(require('Mission.Service').open())
  local before=D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmAdoptionState')},false,true)
  for _,owner in ipairs({'mentor','wuyun'})do
   r.owner=owner;r.stage='begin';save();local item=owner=='mentor'and'kinetic'or'emp';local balance=E.wallet().available
   local attempt,why=S:beginAsync('c0-disarm',models,{mentor=true,learner='ninilite',wuyun=true},{loadout={{actor=owner,item=item,quantity=1}},reward=100});assert(attempt,why)
   local c=require('Ground.DisarmLevel').openAsync(S,attempt);local b=c.battle;local guard=b.enemies[1].guard
   assert(not b.disarmTrace.adoptions.wuyun,'Different fixture base must not deploy a prior candidate')
   c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
   if owner=='wuyun'then c.hud.move:emit('Left',true);D.sleep(1.2);c.hud.move:emit('Left',false)end
   r.stage='natural-theft-shot';save();wait(function()return #b.disarmTrace.consumption>0 or b.phase~='playing'end,70)
   assert(b.phase=='playing','Ended before stolen shot');local row=b.disarmTrace.consumption[1]
   assert(row.owner==owner and row.item==item and row.performer=='enemy:1'and row.before.ammo[item]==1 and row.after.ammo[item]==0)
   local unit=owner=='mentor'and b.mentor or b.wuyun.student;assert(unit.data.weaponDisarmed)
   wait(function()return c.status.text:find((owner=='mentor'and'导师'or'乌云')..'武器被夺',1,true)end)
   local emissions=b.supplies.emissions;local yes,why
   if owner=='mentor'then yes,why=b:command('shoot')else yes,why=b.wuyun:request('laser','qa-rejected')end
   assert(not yes and why=='WEAPON_DISARMED'and b.supplies.emissions==emissions)
   local shotTime=row.at;r.stage='empty-gun-melee';save()
   wait(function()for _,strike in ipairs(guard.strikes)do if strike.started and strike.started>shotTime and strike.skill=='punch'then return true end end;return false end)
   wait(function()return not unit.data.weaponDisarmed end)
   if owner=='mentor'then yes,why=b:command('shoot')else yes,why=b.wuyun:request('laser','qa-rejected')end
   assert(not yes and why=='OUT_OF_SUPPLIES'and b.supplies.emissions==1)
   assert(require('Combat.DisarmStatus').hint(b):find('已耗尽',1,true)and not require('Combat.DisarmStatus').hint(b):find('可以再次射击',1,true))
   if owner=='mentor'then c.withdraw:emit('Tapped')end
   r.stage=owner=='mentor'and'withdraw'or'natural-failure';save();wait(function()return c.phase=='result'or c.phase=='save-error'end,110)
   assert(c.phase=='result',c.error);assert(b.phase==(owner=='mentor'and'aborted'or'failed'));assert(not unit.data.weaponDisarmed)
   local report=b.report.economy;assert(report.income==0 and report.cost==(owner=='mentor'and 4 or 7)and report.net==-report.cost and E.wallet().available==balance-report.cost)
   assert(c.result.resultLayout=='MissionFail'and report.lines[1].usedByOthers==1)
   local e=assert(require('Training.CombatStore').load(attempt.id));assert(e.resources.events[row.event].owner==owner and e.resources.events[row.event].performer=='enemy:1')
   assert(S:finishAsync(attempt,b.phase,b.report,e));assert(E.wallet().available==balance-report.cost)
   r.cases[#r.cases+1]={owner=owner,item=item,stolen=1,cost=report.cost,net=report.net,status=b.phase,seconds=b.report.seconds};save()
  end
  assert(before==D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmAdoptionState')},false,true));r.trainingUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
