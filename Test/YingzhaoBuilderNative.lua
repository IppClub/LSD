-- Real old QA database, real source rebuild and current native C4.5.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-builder-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-punch-companion-natural-20261006/result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mixed%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-builder-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local S=require('Training.YingzhaoPolicyStore');local P=require('Training.YingzhaoPolicy');P.builderVersion=2 -- Explicit regression for archived builder v2.
  local equal=require('Training.FlowerIdentity').equal
  assert(equal(assert(S.loadLatestAsync('ninilite')).model,prior.model))
  assert(equal(assert(S.loadLatestAsync('wuyun')).model,prior.companion));r.legacyRebuild=true
  local fresh=assert(S.learnAsync('wuyun'));assert(fresh.model.builderVersion==2 and fresh.model.trainingAccuracy==1 and fresh.model.sampleCount==13)
  assert(equal(assert(S.loadLatestAsync('wuyun')).model,fresh.model));r.newRebuild=true;r.model=fresh.model;r.previousAccuracy=prior.companion.trainingAccuracy
  local payload=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{fresh.id})[1][1]
  local source=D.json.decode(payload,32)
  for _,value in ipairs({false,99})do
   source.model.builderVersion=value or nil
   assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{D.json.encode(source),fresh.id})>=0)
   assert(not S.loadLatestAsync('wuyun'),'Altered builder accepted')
  end
  assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{payload,fresh.id})>=0)
  assert(S.loadLatestAsync('wuyun'));r.tamperRejected=true
  -- Synthetic all-constant input exercises the boundary only, never stored as
  -- a demonstration. Source validation above uses the actual archive path.
  local inspect=P.inspect
  P.inspect=function()
   local samples={};for i=1,6 do local state={};for _,name in ipairs(P.names)do state[name]='same'end;samples[i]={state=state,action=i<=3 and'idle'or'bmove'}end
   return {samples=samples,actions={idle=3,bmove=3},sources={'synthetic-boundary'}}
  end
  local empty,why=P.buildAsync({},'wuyun');P.inspect=inspect
  assert(not empty and why=='NO_VARIABLE_FEATURES');r.constantBoundary=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
