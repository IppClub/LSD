local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-edge-conserve-learning-result.json';local r={status='RUNNING',replay={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-companion-observations-20261006/result.json'),32)
  assert(prior.saved and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mixed%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/edge-conserve-learning-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local equal=require('Training.FlowerIdentity').equal
  local function adopted()return D.DB:query('SELECT * FROM lsd.Game0Training_wuyun')end
  local before=adopted();local economy=require('Economy.Store');assert(economy.open());local wallet=economy.wallet().available
  local lessons=D.json.decode(D.Content:load(root..'/Test/yingzhao-edge-conserve-result.json'),32);assert(lessons.status=='PASS');local added=0
  for _,case in ipairs(lessons.cases)do assert(require('Training.YingzhaoStore').saveAsync(case.source));added=added+case.samples end
  local store=require('Training.YingzhaoPolicyStore');local entry=assert(store.learnAsync('wuyun'));r.model=entry.model;r.id=entry.id
  assert(entry.model.sampleCount==prior.companion.sampleCount+added)
  assert(equal(assert(store.loadLatestAsync('wuyun')).model,entry.model))
  local P=require('Training.YingzhaoPolicy');local counts={};local oldCount=0
  for _,d in ipairs(prior.report.rounds[2].companionDecisions)do
   local s=d.observation
   if d.reason=='NO_MATCH'and s.bossAction=='wave'and s.target=='boss'and s.targetDistance=='far'then
    local old,why=P.predict(prior.companion,s);assert(not old and why=='NO_MATCH');oldCount=oldCount+1
    local action,reason=P.predict(entry.model,s);counts[action or reason]=(counts[action or reason]or 0)+1
    r.replay[#r.replay+1]={at=d.at,action=action,reason=reason,waveReach=s.waveReach,arenaEdge=s.arenaEdge}
   end
  end
  assert(oldCount==51);r.counts=counts;r.total=oldCount;r.lessonPredictions={}
  for _,case in ipairs(lessons.cases)do local action,why=P.predict(entry.model,case.before);r.lessonPredictions[#r.lessonPredictions+1]={side=case.side,action=action,reason=why}end
  assert(equal(before,adopted())and wallet==economy.wallet().available);r.adoptionUnchanged=true;r.walletUnchanged=true;r.notNaturalVictory=true;r.frozenObservationReplay=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
