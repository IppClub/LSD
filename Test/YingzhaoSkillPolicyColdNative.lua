local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-skill-policy-cold-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-skill-policy-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-skill%-policy%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-skill-cold-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local store=require('Training.YingzhaoPolicyStore');local I=require('Training.FlowerIdentity');r.actors={}
  for _,row in ipairs(prior.actors)do
   local loaded=assert(store.loadLatestAsync(row.actor));assert(loaded.id==row.candidateId and I.equal(loaded.model,row.model))
   local payload=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{loaded.id})[1][1]
   local altered=D.json.decode(payload,32);altered.model.actionSetVersion=1
   assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{D.json.encode(altered),loaded.id})>=0)
   assert(not store.loadLatestAsync(row.actor),'Skill candidate relabelled as old version accepted')
   assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{payload,loaded.id})>=0)
   assert(store.loadLatestAsync(row.actor));r.actors[#r.actors+1]=row.actor
  end
  -- A real older snapshot must rebuild using its stored feature/action/builder versions.
  local old=D.json.decode(D.Content:load(root..'/Test/yingzhao-policy-result.json'),32);assert(old.status=='PASS'and old.model.actionSetVersion==1)
  local payload=D.json.encode({schemaVersion=1,model=old.model,records={old.source}},false,true)
  assert(D.DB:exec('INSERT INTO lsd.Game0YingzhaoCandidates(actor,identity,payload) VALUES(?,?,?)',{old.model.characterId,'legacy-skill-compat',payload})>=0)
  local restored=assert(store.loadLatestAsync(old.model.characterId));assert(I.equal(restored.model,old.model));r.legacyRebuilt=true
  local tables=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
  for _,row in ipairs(tables)do assert(row[1]=='Config'or row[1]=='Game0YingzhaoObservations'or row[1]=='Game0YingzhaoCandidates','Unexpected adoption or wallet table')end
  assert(D.DB:query('SELECT COUNT(*) FROM lsd.Config')[1][1]==0,'Runtime config gained adopted state')
  r.noAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
