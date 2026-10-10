-- Same real mixed lessons and depth limit; only branch-local constants change.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-branch-builder-result.json';local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-finite-wave-natural-v3-20261006/result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mixed%-natural%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-branch-builder-'..os.time()..'.db';r.database=db
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local P=require('Training.YingzhaoPolicy');local S=require('Training.YingzhaoPolicyStore');local equal=require('Training.FlowerIdentity').equal
  for _,actor in ipairs({'ninilite','wuyun'})do
   local old=assert(S.loadLatestAsync(actor));assert(old.model.builderVersion==2)
   assert(equal(old.model,actor=='ninilite'and prior.model or prior.companion))
   local payload=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{old.id})[1][1]
   local source=D.json.decode(payload,32);local data=assert(P.inspect(source.records,actor,3))
   local current=assert(P.buildAsync(source.records,actor,3,3))
   r.actors[actor]={oldAccuracy=old.model.trainingAccuracy,newAccuracy=current.trainingAccuracy,model=current};save()
   assert(current.trainingAccuracy==1,'Branch-local filtering did not recover the real labels')
   for _,rule in ipairs(current.rules)do
    assert(#rule.conditions<=4,'Native historical depth limit changed')
    local subset=data.samples
    for _,c in ipairs(rule.conditions)do
     local values,nextRows={},{};for _,s in ipairs(subset)do values[s.state[c.name]]=true;if s.state[c.name]==c.value then nextRows[#nextRows+1]=s end end
     local count=0;for _ in pairs(values)do count=count+1 end;assert(count>=2,'Constant branch split')
     subset=nextRows
    end
   end
   P.builderVersion=3;P.featureSchemaVersion=3;local fresh=assert(S.learnAsync(actor));assert(equal(fresh.model,current));assert(equal(assert(S.loadLatestAsync(actor)).model,current))
   local saved=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{fresh.id})[1][1]
   local altered=D.json.decode(saved,32);altered.model.builderVersion=99
   assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{D.json.encode(altered),fresh.id})>=0)
   assert(not S.loadLatestAsync(actor));assert(D.DB:exec('UPDATE lsd.Game0YingzhaoCandidates SET payload=? WHERE id=?',{saved,fresh.id})>=0)
   assert(S.loadLatestAsync(actor))
  end
  -- Contradictory indistinguishable labels cannot be repaired by inventing a split.
  local B=require('Training.YingzhaoBranchBuilder')
  local empty,why=B.buildAsync({{state={a='x'},action='idle'},{state={a='x'},action='bmove'}},{'a'})
  assert(not empty and why=='NO_VARIABLE_FEATURES')
  local rows={{state={a='x',b='0'},action='idle'},{state={a='x',b='0'},action='bmove'},{state={a='y',b='1'},action='shoot@head'},{state={a='y',b='1'},action='shoot@head'}}
  local rules,accuracy=B.buildAsync(rows,{'a','b'});assert(rules and accuracy==.75)
  r.conflictNotFabricated=true;r.legacyRebuilt=true;r.newRebuilt=true;r.unknownVersionRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
