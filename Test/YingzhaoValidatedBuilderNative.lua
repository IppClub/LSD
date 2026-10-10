-- Rebuild old archives and verify selection against an independent diagnostic.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-validated-builder-result.json';local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-context-natural-20261006/result.json'),32)
  local expected=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-source-holdout-20261006/result.json'),32)
  assert(prior.status=='PASS'and expected.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mixed%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-validated-'..os.time()..'.db';r.database=db;assert(not D.DB:existDB('lsd'))
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local P=require('Training.YingzhaoPolicy');local S=require('Training.YingzhaoPolicyStore');local equal=require('Training.FlowerIdentity').equal
  for _,actor in ipairs({'ninilite','wuyun'})do
   local old=assert(S.loadLatestAsync(actor));assert(old.model.builderVersion==3)
   assert(equal(old.model,actor=='ninilite'and prior.model or prior.companion))
   local fresh=assert(S.learnAsync(actor));local m=fresh.model;assert(m.builderVersion==4)
   assert(m.validation.depth==(actor=='wuyun'and 6 or 4))
   local oracle=expected.actors[actor].variants[actor=='wuyun'and 2 or 1]
   assert(m.validation.correct==oracle.correct and m.validation.total==oracle.total and math.abs(m.validation.macroAccuracy-oracle.macroEpisodeAccuracy)<1e-10)
   assert(equal(assert(S.loadLatestAsync(actor)).model,m),'Source reconstruction changed selected model')
   local corrupt=D.json.decode(D.json.encode(m),32);corrupt.validation.depth=12;assert(not P.validate(corrupt))
   r.actors[actor]={model=m,oldRebuilt=true,newRebuilt=true};save()
  end
  local B=require('Training.YingzhaoValidatedBuilder')
  local rules,accuracy,v=B.buildAsync({{episode='only',state={a='x'},action='idle'},{episode='only',state={a='y'},action='bmove'}},{'a'})
  assert(rules and accuracy==1 and B.validate(v)and v.depth==4 and v.total==0 and not v.macroAccuracy,'Single episode fabricated validation')
  r.singleSourceHonest=true;r.noAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
