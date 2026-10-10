local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-skills-cold-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-q-skills-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-q%-skills%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-q-skills-cold-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local Store=require('Training.YingzhaoQStore');local Q=require('Training.YingzhaoQ');local I=require('Training.FlowerIdentity')
  for _,case in ipairs(prior.cases)do
   local loaded=assert(Store.loadAsync(case.id));assert(I.equal(loaded.source,case.source));assert(I.equal(assert(Q.restore(loaded.model)):snapshot(),loaded.model))
   local altered=D.json.decode(D.json.encode(loaded.source),32);local t=altered.transitions[1];local step=altered.combat.boss.steps[t.sourceStep]
   t.ended=step.started+.2;t.duration=t.ended-t.started
   local valid,why=Store.validate(altered);assert(not valid and why=='Q_SKILL_INCOMPLETE','Early skill transition accepted: '..tostring(why))
   r.cases[#r.cases+1]={actor=case.actor,direction=case.direction,id=case.id,exactReplay=true};save()
  end
  local tables=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
  for _,row in ipairs(tables)do assert(row[1]=='Config'or row[1]=='Game0YingzhaoQCandidates')end
  assert(D.DB:query('SELECT COUNT(*) FROM lsd.Config')[1][1]==0);r.noAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
