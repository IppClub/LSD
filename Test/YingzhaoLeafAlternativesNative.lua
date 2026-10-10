local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-leaf-alternatives-result.json';local r={status='RUNNING',probes={}}
D.Content:save(out,D.json.encode(r,false,true));D.thread(function()
 local ok,err=xpcall(function()
  local function read(name)local v=D.json.decode(D.Content:load('/private/tmp/'..name..'/result.json'),32);assert(v.status=='PASS');return v end
  local records=read('lsd-yingzhao-fresh-corpus-20261006').records
  for _,c in ipairs(read('lsd-yingzhao-range-lesson-20261006').cases)do records[#records+1]=c.source end
  local P=require('Training.YingzhaoPolicy');local probes={}
  for _,c in ipairs(read('lsd-yingzhao-impact-counter-20261006').cases)do
   if c.response=='early'and c.lessonEligible then records[#records+1]=c.source;probes[#probes+1]={case=c,expected=c.side<0 and'wind@right'or'wind@left'}end
  end
  for _,c in ipairs(read('lsd-yingzhao-melee-spacing-20261006').cases)do
   if c.response=='bmove'and c.damage==0 and (c.skill=='punch'and c.distance==350 or c.skill=='massive'and c.distance==650)then records[#records+1]=c.source;probes[#probes+1]={case=c,expected='bmove'}end
  end
  assert(#records==28 and #probes==8)
  local extra=read('lsd-yingzhao-empty-ammo-lesson-20261006');for _,c in ipairs(extra.cases)do records[#records+1]=c.source end;assert(#records==32)
  local data=assert(P.inspect(records,'wuyun',8,2));local candidate=assert(P.buildAsync(records,'wuyun',8,5,2));assert(P.validate(candidate))
  local old=read('lsd-yingzhao-empty-ammo-model-20261006').model;assert(old.builderVersion==4)
  local db=D.Content.writablePath..'/leaf-alternatives.db';assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  assert(D.DB:exec('CREATE TABLE lsd.Game0YingzhaoCandidates(id INTEGER PRIMARY KEY AUTOINCREMENT,actor TEXT NOT NULL,identity TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0)
  local payload=D.json.encode({schemaVersion=1,model=candidate,records=records},false,true)
  assert(D.DB:exec('INSERT INTO lsd.Game0YingzhaoCandidates(actor,identity,payload) VALUES(?,?,?)',{'wuyun','leaf-fixture',payload})>=0)
  local loaded,why=require('Training.YingzhaoPolicyStore').loadLatestAsync('wuyun');assert(loaded,why);assert(require('Training.FlowerIdentity').equal(loaded.model,candidate));r.sourceRebuilt=true
  local bad=D.json.decode(D.json.encode(candidate),32);bad.rules[1].choices[1].count=bad.rules[1].choices[1].count+1;assert(not P.validate(bad))
  bad=D.json.decode(D.json.encode(candidate),32);bad.rules[1].choices[1]=42;assert(not P.validate(bad))
  bad=D.json.decode(D.json.encode(candidate),32);bad.builderVersion=4;assert(not P.validate(bad));r.forgeryRejected=true
  r.masked={};r.alternatives=0
  for _,sample in ipairs(data.samples)do
   local state=records[1] -- locate the original observation via the episode identity
   for _,record in ipairs(records)do if record.episode==sample.episode then state=record.boss.steps[sample.firstStep].before;break end end
   local primary=P.predict(candidate,state);assert(primary==P.predict(old,state),'Unmasked primary changed')
   local alternate,reason=P.predict(candidate,state,function(action)return action~=primary end)
   assert(P.predict(old,state,function(action)return action~=primary end)==nil,'Legacy model gained fallback')
   if alternate then r.alternatives=r.alternatives+1;assert(alternate~=primary)else assert(reason=='ACTION_UNAVAILABLE'or reason=='NO_MATCH')end
   assert(P.predict(candidate,state,function()return false end)==nil,'All-blocked state produced action')
   if sample.state.empAmmo=='empty'then local action=P.predict(candidate,state,function(a)return not a:match('^shoot@')end);r.masked[#r.masked+1]={primary=primary,action=action};assert(not action or not action:match('^shoot@'))end
  end
  assert(r.alternatives>0)

  r.model=candidate;r.samples=#data.samples;r.sources=#records;r.correct=0;r.trainingProbesOnly=true
  r.emptyProbes={};r.emptyCorrect=0;r.emptyShots=0
  for _,c in ipairs(extra.cases)do
   local samples=assert(P.inspect({c.source},'wuyun',8,2))
   for _,sample in ipairs(samples.samples)do if sample.state.empAmmo=='empty'then
    local observation=c.source.boss.steps[sample.firstStep].before;local action,why=P.predict(candidate,observation)
    if action==sample.action then r.emptyCorrect=r.emptyCorrect+1 end
    if action and action:match('^shoot@')then r.emptyShots=r.emptyShots+1 end
    r.emptyProbes[#r.emptyProbes+1]={expected=sample.action,action=action,reason=why,side=c.side,response=c.response}
   end end
  end
  for _,probe in ipairs(probes)do
   local c=probe.case;local observed
   for _,step in ipairs(c.source.boss.steps)do if step.actor=='wuyun'and(step.action=='wind'or step.action=='bmove')then observed=step.before;break end end
   local action,why=P.predict(candidate,assert(observed));assert(why~='INVALID_OBSERVATION')
   if action==probe.expected then r.correct=r.correct+1 end
   r.probes[#r.probes+1]={skill=c.skill,distance=c.distance,side=c.side,expected=probe.expected,action=action,reason=why,before=observed}
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
