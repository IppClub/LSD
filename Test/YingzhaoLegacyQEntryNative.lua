-- Cold-read an actual previously adopted archive; only copy QA saves.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-legacy-q-entry-result.json'
local r={status='RUNNING',osInput=false,source='Docs/evidence/2026-10-07/virtual-shield-training/actual-legacy-q-source/actual-save.db'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-legacy-q-'..os.time()..'.db';r.database=db
  assert(D.Content:copyAsync(root..'/'..r.source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local Store=require('Training.YingzhaoQStore');local Rewards=require('Training.YingzhaoRewards');local Identity=require('Training.FlowerIdentity')
  local rows=D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoQCandidates ORDER BY id');assert(#rows==2)
  local original=D.json.encode(rows);local parent
  for _,row in ipairs(rows)do local old=D.json.decode(row[2],32);local loaded,why=Store.loadAsync(row[1]);assert(loaded,why);assert(loaded.model.rewardPolicy==Rewards.legacyPolicy and loaded.model.featureSchemaVersion==2);assert(Identity.equal(loaded.model,old.model));parent=loaded end
  r.coldRead=true;r.parent=parent.id
  local economy=require('Economy.Store');assert(economy.open());local balance=economy.wallet().available
  local function wait(fn)local deadline=D.App.runningTime+30;while not fn()do assert(D.App.runningTime<deadline,'Legacy public UI timeout');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  local models=assert(require('Training.FlowerPractice').models());local Entry=require('Training.YingzhaoQEntry')
  local panel=Entry.openAsync(nil,'ninilite',models,parent);assert(panel.noteLabel.text:find('旧收益规则',1,true));panel.closeButton:emit('Tapped');wait(controls)
  assert(D.json.encode(D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoQCandidates ORDER BY id'))==original)
  panel=Entry.openAsync(nil,'ninilite',models,parent);panel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoQTraining end)
  local c=D.Platformer.Data.store.world.patrolLevel
  assert(not c.battle.physicalShield and c.battle.yingzhaoQTraining.q.rewardPolicy==Rewards.legacyPolicy)
  assert(c.battle.yingzhaoQTraining.q.updates==parent.model.updates)
  c.start:emit('Tapped');wait(function()return #c.battle.yingzhaoQTraining.transitions>=2 end);c.withdraw:emit('Tapped');wait(function()return c.phase=='result' or c.phase=='save-error'end)
  assert(c.phase=='result',c.result and c.result.saveError or 'Legacy continuation failed to save')
  local child,why=Store.loadAsync(c.battle.qCandidateId);assert(child,why);assert(child.source.parentId==parent.id and child.model.rewardPolicy==Rewards.legacyPolicy and child.model.updates>parent.model.updates)
  assert(D.json.encode(D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoQCandidates WHERE id<=2 ORDER BY id'))==original)
  r.continued=true;r.child=child.id;r.updates=child.model.updates-parent.model.updates
  c.result.baseButton:emit('Tapped');wait(controls)
  panel=Entry.openAsync(nil,'ninilite',models,nil);panel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoQTraining end)
  c=D.Platformer.Data.store.world.patrolLevel;assert(c.battle.physicalShield and c.battle.yingzhaoQTraining.q.rewardPolicy==Rewards.policy)
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end);assert(c.battle.qNoUpdates)
  assert(assert(Store.loadLatestAsync('ninilite')).id==child.id and economy.wallet().available==balance)
  assert(D.json.encode(D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoQCandidates WHERE id<=2 ORDER BY id'))==original)
  r.freshPreservesLegacy=true;r.walletUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
