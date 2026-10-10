-- Offline native-builder diagnosis using archived real samples; no adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-depth-diagnostic-result.json';local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-context-natural-20261006/result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mixed%-natural%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-depth-'..os.time()..'.db';r.database=db
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local P=require('Training.YingzhaoPolicy');local S=require('Training.YingzhaoPolicyStore');local F=require('Training.YingzhaoFeatures')
  local native=require('Training.YingzhaoBranchBuilder')
  for _,actor in ipairs({'ninilite','wuyun'})do
   local stored=assert(S.loadLatestAsync(actor))
   local payload=D.json.decode(D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{stored.id})[1][1],32)
   local data=assert(P.inspect(payload.records,actor,4));local row={actions=data.actions,samples=#data.samples,variants={}};r.actors[actor]=row
   for _,depth in ipairs({4,6,8,12})do
    local builder={buildAsync=function(samples,fields)return native.buildAsync(samples,fields,depth)end}
    local rules,accuracy=builder.buildAsync(data.samples,F.fields(4));assert(rules,accuracy)
    local actions={};for _,rule in ipairs(rules)do actions[rule.action]=(actions[rule.action]or 0)+1 end
    local v={depth=depth,accuracy=accuracy,rules=rules,actions=actions,folds={},correct=0,total=0,unmatched=0,byAction={}}
    row.variants[#row.variants+1]=v
    for _,episode in ipairs(data.sources)do
     local train,held={},{}
     for _,sample in ipairs(data.samples)do local list=sample.episode==episode and held or train;list[#list+1]=sample end
     assert(#held>0 and #train>0)
     local learned,why=builder.buildAsync(train,F.fields(4));assert(learned,why)
     local fold={episode=episode,correct=0,total=#held,unmatched=0}
     for _,sample in ipairs(held)do
      local prediction
      for _,rule in ipairs(learned)do
       local match=true;for _,c in ipairs(rule.conditions)do if sample.state[c.name]~=c.value then match=false;break end end
       if match then prediction=rule.action;break end
      end
      local counts=v.byAction[sample.action]or{correct=0,total=0};v.byAction[sample.action]=counts;counts.total=counts.total+1
      if prediction==sample.action then fold.correct=fold.correct+1;counts.correct=counts.correct+1 end
      if not prediction then fold.unmatched=fold.unmatched+1 end
     end
     v.folds[#v.folds+1]=fold;v.correct=v.correct+fold.correct;v.total=v.total+fold.total;v.unmatched=v.unmatched+fold.unmatched
    end
    v.heldAccuracy=v.correct/v.total
    local sum=0;for _,f in ipairs(v.folds)do sum=sum+f.correct/f.total end;v.macroEpisodeAccuracy=sum/#v.folds
    if depth==4 then assert(accuracy==stored.model.trainingAccuracy or math.abs(accuracy-stored.model.trainingAccuracy)<1e-10)end
    save()
   end
  end
  r.diagnosticOnly=true;r.noAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
