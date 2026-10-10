local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/factory-phase-view-result.json','{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db';local dest=D.Content.writablePath..'/flower-phase-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  D.App.winSize=D.Size(683,384)
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}});local b=c.battle
  D.sleep(.1);c.start:emit('Tapped');for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  b.roots[1].nextEnemy=math.huge;b.roots[2].nextEnemy=math.huge
  local boss=b.roots[3];assert(boss.enemyCombat.phaseEnabled);boss.enemyHP=100;b.partCombat.target.damage.hp=100 -- explicit phase threshold fixture
  local events={};boss.enemy.playable:slot('AnimationEnd',function(name)events[#events+1]={name=name,elapsed=D.App.runningTime-boss.enemyCombat.partStarted}end)
  local deadline=D.App.runningTime+8;while boss.enemyCombat.bossPhase~=2 do assert(D.App.runningTime<deadline,D.json.encode({phase=b.phase,hp=boss.enemyHP,enemyPhase=boss.enemyPhase,stage=boss.enemyCombat.stage,done=boss.enemyCombat.stageDone,elapsed=D.App.runningTime-boss.enemyCombat.partStarted,duration=boss.enemyCombat.stageDuration,studentHP=b.arena.studentHP,current=boss.enemy.playable.current,speed=boss.enemy.playable.speed,events=events}));D.sleep(.01)end
  D.sleep(.1);assert(c.status.text:find('繁殖期') and c.status.text:find('100/220'))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/factory-phase-1366.tga');D.sleep(.15)
  D.App.winSize=D.Size(960,540);D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/factory-phase-1920.tga');D.sleep(.15)
  b:finish('aborted','QA');assert(b.report.bossPhase==2 and #b.report.bossPhaseEvents==1);r.hostPhase=true;r.phaseReport=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil
 D.Content:save(root..'/Test/factory-phase-view-result.json',D.json.encode(r))
end)
