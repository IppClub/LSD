-- UI event integration, not OS input or natural Boss victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-practice-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  assert(not D.DB:existDB('lsd'))
  local db=D.Content.writablePath..'/yingzhao-observations-'..os.time()..'.db';r.database=db;assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')}
  local loadout={{actor='wuyun',item='emp',quantity=2},{actor='wuyun',item='blade',quantity=2}}
  local returned=false
  local c=require('Training.BigYingzhaoPractice').openBattleAsync(models,loadout,'wuyun',function()returned=true;return true end)
  local b=c.battle
  assert(b.demonstrator==b.wuyun and c.melee and c.gather and c.melee.y~=c.gather.y)
  assert(c.targetButtons.head and b.supplies.isVirtual)
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do if D.App.runningTime>=stop then r.timeoutState={x=b.wuyun.student.x,y=b.wuyun.student.y,mode=b.wuyun.mode,face=b.wuyun.student.faceRight,vx=b.wuyun.student.velocityX,back=b.wuyun.student:isDoing(b.wuyun.physical.bmove),phase=b.phase};error('Practice timeout')end;D.sleep(.02)end end
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  b.enemies[1].guard.nextAttack=math.huge;b.enemies[1].enemy.playable.speed=0;b.arena.mode='review';b.arena.student.x=1400;D.sleep(.5)
  c.hud.move.onMove('keyLeft',true);wait(function()if b.wuyun.student.x<=1700 then return true end;b:command('left');return false end);c.hud.move.onMove('keyLeft',false);D.sleep(.1)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-practice-before.tga');D.sleep(.2)
  r.positions={student={x=b.wuyun.student.x,y=b.wuyun.student.y},boss={x=b.enemies[1].enemy.x,y=b.enemies[1].enemy.y}}
  c.targetButtons.head:emit('Tapped');D.emit('Skill.Began');assert(not b.demonstrationFeedback,b.demonstrationFeedback)
  wait(function()return b.supplies.emissions==1 end)
  wait(function()return not b.wuyun:isAttacking()and next(b.bossCombat.shots)==nil end)
  assert(#b.bossTrace.hits==1 and b.bossTrace.hits[1].part=='head'and b.bossTrace.hits[1].source=='wuyun')
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-practice-controls.tga');D.sleep(.2)
  assert(D.DB:exec('CREATE TABLE lsd.Game0YingzhaoObservations(id INTEGER PRIMARY KEY AUTOINCREMENT,episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0)
  assert(D.DB:exec("CREATE TRIGGER lsd.reject_demo BEFORE INSERT ON Game0YingzhaoObservations BEGIN SELECT RAISE(ABORT,'QA write fault'); END")>=0)
  c.withdraw:emit('Tapped');wait(function()return c.phase=='save-error'end)
  assert(D.DB:exec('DROP TRIGGER lsd.reject_demo')>=0);c.result.againButton:emit('Tapped');wait(function()return c.phase=='result'end)
  local store=require('Training.YingzhaoStore');local e=assert(store.loadAsync(b.demonstrationSourceId))
  assert(e.demonstrator=='wuyun'and e.resources.mode=='virtual'and e.boss.hits[1].part=='head')
  assert(not require('Enemy.BigYingzhaoEvidence').validate(e),'Virtual source passed formal validator')
  local saved,why,id=store.saveAsync(e);assert(saved and why=='ALREADY_RECORDED'and id==b.demonstrationSourceId)
  local altered=D.json.decode(D.json.encode(e),32);altered.boss.status='failed';assert(not store.saveAsync(altered),'Conflicting retry accepted')
  altered=D.json.decode(D.json.encode(e),32);altered.boss.hits[1].armorDamage=999;assert(not store.saveAsync(altered),'Forged damage saved')
  assert(D.DB:query('SELECT COUNT(*) FROM lsd.Game0YingzhaoObservations')[1][1]==1)
  local review=assert(require('Training.YingzhaoReview').rebuild(e));assert(review.actionCost==4 and review.deployment==4 and review.total==8)
  local attack;for _,row in ipairs(review.rows)do if row.action=='shoot'and row.actor=='wuyun'then attack=row end end
  assert(attack and attack.intent=='head'and attack.armor==35 and attack.health==0 and attack.outcome=='effective'and attack.cost==4)
  assert(c.result.reportLabel.text:find('示范复盘',1,true))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/yingzhao-review-result.tga');D.sleep(.2)
  r.review=true;r.persisted=true;r.retry=true;r.idempotent=true
  assert(c.result.resultLayout=='MissionFail')
  c.result.baseButton:emit('Tapped');wait(function()return returned end)
  r.virtual=true;r.target='head';r.actor='wuyun';r.cost=b.supplies.ledger.spent;r.returned=returned
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
