-- Matched default-supply evaluation, not an earned mission or demonstration.
local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/flower-field-evaluation-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-evidence%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-field-evaluation-'..os.time()..'.db';assert(not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local P=require('Training.FlowerPractice');local Store=require('Training.FlowerTrialStore');local records={}
  local function progress()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks'),D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerPractice')},false,true)end
  local before=progress()
  for _,mode in ipairs({'basic','candidate'})do
   local c=P.openAsync(nil,'ninilite',nil,nil,nil,'field');local b=c.battle
   assert(b.support.gold==45 and b.support.variant=='defence' and c.initialSupportGold==45)
   assert(math.abs(b.roots[3].enemy.x-b.arena.student.x-650)<.01 and math.abs(b.roots[3].enemy.x-b.wuyun.student.x-320)<.01,'Formation was changed')
   assert(not c:start(),'Evaluation accepted demonstration')
   D.sleep(.1);if mode=='basic'then c.basicButton:emit('Tapped')else c.trialButton:emit('Tapped')end
   local started=D.App.totalTime
   while b.phase=='playing' or b.phase=='saving' do assert(D.App.totalTime-started<135,'Field evaluation stalled');D.sleep(.25)end
   assert(c.result and c.result.trialSaved,'Field record not saved')
   local record=assert(Store.latest('ninilite'));assert(record.controller==mode and record.setup.profile.id=='field' and record.setup.supportGold==45 and record.status~='aborted')
   records[mode]=record
   local changed=D.json.decode(D.json.encode(record),32);changed.setup.supportGold=90;assert(not Store.validate(changed),'Wrong supply accepted')
   assert(not require('Training.FlowerPracticeStore').saveAsync('ninilite',record.status,record.episode),'Evaluation leaked into demonstration')
   assert(progress()==before,'Evaluation changed progression or policy')
  end
  r.comparison=assert(require('Training.FlowerComparison').build(records.basic,records.candidate));r.sameFormation=true;r.gold=45;r.naturalRounds=2;r.progressUnchanged=true
  local c=P.openAsync(nil,'ninilite',nil,nil,nil,'field');assert(c.comparison.profile=='field')
  r.readback=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-field-comparison.tga');D.sleep(.1)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
