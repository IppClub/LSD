local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-cancel-cold-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-q-skill-cancel-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-q%-cancel%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-q-cancel-cold-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local Store=require('Training.YingzhaoQStore');local I=require('Training.FlowerIdentity')
  for _,case in ipairs(prior.cases)do
   if case.id then
    local loaded=assert(Store.loadAsync(case.id));assert(I.equal(loaded.source,case.source))
    r.cases[#r.cases+1]={actor=case.actor,mode=case.mode,id=case.id};save()
   else assert(case.mode=='aborted-before-release'and #case.transitions==0)end
  end
  assert(#r.cases==6 and D.DB:query('SELECT COUNT(*) FROM lsd.Game0YingzhaoQCandidates')[1][1]==6)
  assert(D.DB:query('SELECT COUNT(*) FROM lsd.Config')[1][1]==0);r.noAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
