-- Public factory HUD aiming, with isolated save and stationary combat fixtures.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
local out=root..'/Test/factory-movement-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db'
  local dest=D.Content.writablePath..'/factory-aim-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  D.App.winSize=D.Size(683,384)
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}})
  local b=c.battle;local combat=b.partCombat
  local function wait(f,t)local deadline=D.App.runningTime+(t or 6);while not f()do assert(D.App.runningTime<deadline,'Factory armor timeout '..#combat.events);D.sleep(.01)end end
  D.sleep(.1);c.start:emit('Tapped')
  for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for i=1,2 do b.roots[i].enemyHP=0;b.roots[i].enemy.x=7500 end

  local gold=b.support.gold;b.last=D.App.runningTime+1;D.sleep(.1);assert(b.support.gold<gold,'Negative wall interval stopped battle updates')
  local a=b.arena;a.student.x=4800;a.student.faceRight=true;D.sleep(.2)
  wait(function()return a.student.onSurface end)
  local first=#combat.journal.steps+1;local x=a.student.x
  local adopted=a.trialModel;a.trialModel=model('ninilite','fmove');a.nextDecision=D.App.runningTime;a:update();a.nextDecision=math.huge;a.trialModel=adopted
  assert(a.student:isDoing(a.physical.fmove));D.sleep(.2);assert(a.student.x>x+10,'Forward action did not move forward')
  local count=#combat.journal.steps;assert(not a:request('fmove','model'));assert(#combat.journal.steps==count,'Held movement duplicated an action')
  local forward=combat.journal.steps[first];assert(forward.action.name=='fmove' and forward.action.origin=='model')
  assert(a:request('bmove','model'));x=a.student.x;D.sleep(.2);assert(a.student.x<x-10,'Back action moved forward')
  assert(forward.sealed and forward.duration>0 and forward.reason=='stopped')
  assert(a:request('idle','model'));x=a.student.x;D.sleep(.2);assert(math.abs(a.student.x-x)<5,'Wait action moved')
  assert(a:request('fmove','model'));D.sleep(.1)
  local interrupted=combat.journal.steps[#combat.journal.steps]
  local target;for _,t in ipairs(b.targets())do if t.unit==a.student then target=t end end
  assert(b.effects:apply(target,'virus',2,{kind='QA-move-interrupt'}));D.sleep(.1)
  assert(interrupted.sealed and interrupted.reason=='status-interrupted')
  local count=#combat.journal.steps;assert(not a:request('fmove','model'));assert(#combat.journal.steps==count,'Rejected move recorded')
  b.effects:clear();assert(a:request('fmove','model'));D.sleep(.1)
  local last=combat.journal.steps[#combat.journal.steps]
  c.withdraw:emit('Tapped');wait(function()return b.phase=='aborted'end)
  assert(last.truncated and not last.sealed,'Exit invented completed movement')
  assert(require('Training.CombatStore').validate(b.combatEpisode))
  for _,step in ipairs(b.combatEpisode.steps)do assert(step.action.weapon=='none' and #step.hits==0 and (step.action.emitted or 0)==0)end
  assert(b.report.evaluation.actors.ninilite.actions==5 and b.report.evaluation.actors.ninilite.shots==0)
  r.steps=#b.combatEpisode.steps;r.exitTruncated=true;r.statusInterrupted=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
