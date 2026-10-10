local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-spacing-model-result.json';local r={status='RUNNING',probes={}}
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
  local data=assert(P.inspect(records,'wuyun',8,2));local candidate=assert(P.buildAsync(records,'wuyun',8,4,2));assert(P.validate(candidate))
  r.model=candidate;r.samples=#data.samples;r.sources=#records;r.correct=0;r.trainingProbesOnly=true
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
