local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-trials-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local fixture=D.json.decode(D.Content:load(root..'/Test/flower-q-store-result.json'),32);assert(fixture.status=='PASS')
  assert(fixture.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-store%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-trials-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(fixture.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local T=require('Training.FlowerQTrials');local Store=require('Training.FlowerQStore');local before=Store.loadAsync();assert(before.id==2)
  local function fixture(name)return D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/flower-q-'..name..'-session.json'),32)end
  local basic=fixture('basic');local candidate=fixture('evaluate');local explore=fixture('explore')
  local yes,why,detail=T.saveAsync(basic,2);assert(yes,tostring(why)..':'..tostring(detail))
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_trial BEFORE INSERT ON Game0FlowerQTrials BEGIN SELECT RAISE(ABORT,'QA trial save'); END")>=0)
  yes,why=T.saveAsync(candidate,2);assert(not yes and why=='WRITE_FAILED');assert(#T.loadAsync(2)==1);r.atomicFailure=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_trial')>=0)
  local sourceRaw=D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=2')[1][1]
  assert(D.DB:exec("CREATE TRIGGER lsd.change_q_trial_source BEFORE INSERT ON Game0FlowerQTrials BEGIN UPDATE Game0FlowerQSources SET payload='{}' WHERE id=2; END")>=0)
  yes,why=T.saveAsync(candidate,2);assert(not yes and why=='WRITE_FAILED')
  assert(D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=2')[1][1]==sourceRaw and #T.loadAsync(2)==1);r.sourceRaceRollback=true
  assert(D.DB:exec('DROP TRIGGER lsd.change_q_trial_source')>=0);assert(T.saveAsync(candidate,2));assert(T.saveAsync(candidate,2));assert(#T.loadAsync(2)==2);r.idempotent=true
  assert(not T.saveAsync(explore,2));assert(not T.saveAsync(candidate,1));r.wrongModeAndVersionRejected=true
  local old=candidate.models.ninilite.updates;candidate.models.ninilite.updates=old+1;assert(not T.saveAsync(candidate,2));candidate.models.ninilite.updates=old
  local status=candidate.status;candidate.status='aborted';assert(not T.saveAsync(candidate,2));candidate.status=status
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=1 WHERE singleton=1')>=0)
  local rows=assert(T.loadAsync(2));assert(#rows==2 and rows[1].mode=='evaluate' and rows[2].mode=='basic');r.historicalRead=true
  local raw=D.DB:query('SELECT payload FROM lsd.Game0FlowerQTrials WHERE id=?',{rows[1].id})[1][1]
  assert(D.DB:exec("UPDATE lsd.Game0FlowerQTrials SET payload='{}' WHERE id="..rows[1].id)>=0);local records,reason=T.loadAsync(2);assert(not records and reason=='INVALID_Q_TRIAL');r.corruptionRejected=true
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQTrials SET payload=? WHERE id=?',{raw,rows[1].id})>=0)
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=2 WHERE singleton=1')>=0)
  assert(Store.loadAsync().id==before.id and #D.DB:query('SELECT id FROM lsd.Game0FlowerQSources')==before.depth)
  r.records=#assert(T.loadAsync(2));r.candidate=2;r.sourceUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
