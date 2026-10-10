-- Diagnostic replay of authentic observations; never trains, relabels or adopts.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-coverage-audit-result.json';local r={status='RUNNING',models={},notValidationSet=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local P=require('Training.YingzhaoPolicy');local F=require('Training.YingzhaoFeatures')
  local function read(path)local t=D.json.decode(D.Content:load(path),32);assert(t.status=='PASS');return t end
  local corpus=read('/private/tmp/lsd-yingzhao-fresh-corpus-20261006/result.json')
  local extra=read('/private/tmp/lsd-yingzhao-range-lesson-20261006/result.json')
  for _,c in ipairs(extra.cases)do corpus.records[#corpus.records+1]=c.source end
  local data=assert(P.inspect(corpus.records,'wuyun',6,2));assert(#data.samples==197 and #data.sources==20)
  r.samples=#data.samples;r.sources=#data.sources;r.actions=data.actions
  local grouped={};r.conflicts={}
  for _,s in ipairs(data.samples)do
   local k=D.json.encode(s.state,false,true);local g=grouped[k]or{state=s.state,actions={},examples={}};grouped[k]=g
   g.actions[s.action]=(g.actions[s.action]or 0)+1;g.examples[#g.examples+1]={episode=s.episode,firstStep=s.firstStep,action=s.action}
  end
  for _,g in pairs(grouped)do local n=0;for _ in pairs(g.actions)do n=n+1 end;if n>1 then r.conflicts[#r.conflicts+1]=g end end
  local paths={'/private/tmp/lsd-yingzhao-fresh-natural-snapshot-20261006/result.json','/private/tmp/lsd-yingzhao-exposed-natural-187-20261006/result.json','/private/tmp/lsd-yingzhao-return-natural-20261006/result.json','/private/tmp/lsd-yingzhao-range-natural-20261006/result.json'}
  local reports={};for _,path in ipairs(paths)do reports[#reports+1]=read(path)end
  for _,source in ipairs(reports)do
   local m=source.candidate;assert(P.validate(m));local row={sampleCount=m.sampleCount,demonstrations={},replay={}};r.models[#r.models+1]=row
   for _,sample in ipairs(data.samples)do
    local e;for _,record in ipairs(corpus.records)do if record.episode==sample.episode then e=record;break end end;assert(e)
    local predicted,why=P.predict(m,e.boss.steps[sample.firstStep].before);local label=predicted or why
    local c=row.demonstrations[sample.action]or{total=0,correct=0,predicted={}};row.demonstrations[sample.action]=c
    c.total=c.total+1;c.correct=c.correct+(predicted==sample.action and 1 or 0);c.predicted[label]=(c.predicted[label]or 0)+1
   end
   for _,observed in ipairs(reports)do
    local batch={sourceSamples=observed.candidate.sampleCount,total=0,predicted={},groups={},missingExamples={}};row.replay[#row.replay+1]=batch
    for _,decision in ipairs(observed.report.rounds[2].decisions)do
     local s=decision.observation;assert(F.validate(s));local predicted,why=P.predict(m,s);local label=predicted or why
     batch.total=batch.total+1;batch.predicted[label]=(batch.predicted[label]or 0)+1
     local key=table.concat({s.bossAction,s.target,s.targetDistance,s.targetArmor,s.skillState},'/')
     local g=batch.groups[key]or{total=0,predicted={}};batch.groups[key]=g;g.total=g.total+1;g.predicted[label]=(g.predicted[label]or 0)+1
     if not predicted and not batch.missingExamples[key]then batch.missingExamples[key]=s end
    end
   end
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
