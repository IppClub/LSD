-- Explicit current-schema source set. Never silently evict old rows or invent historical fields.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-fresh-corpus-result.json';local r={status='RUNNING',sources={},records={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local P=require('Training.YingzhaoPolicy');local seen={}
  local function read(name)local e=D.json.decode(D.Content:load(root..'/Test/'..name..'-schema6-result.json'),32);assert(e and e.status=='PASS',name);return e end
  local function add(source,label)
   assert(source.demonstrator=='wuyun'and not seen[source.episode]);seen[source.episode]=true
   for _,step in ipairs(source.boss.steps)do assert(step.before.featureSchemaVersion==6 and (not step.after or step.after.featureSchemaVersion==6))end
   local data=assert(P.inspect({source},'wuyun',6,2));local states={}
   for _,sample in ipairs(data.samples)do assert(sample.state.skillState~='unknown');states[sample.state.skillState]=(states[sample.state.skillState]or 0)+1 end
   r.sources[#r.sources+1]={label=label,episode=source.episode,samples=#data.samples,actions=data.actions,skillStates=states};r.records[#r.records+1]=source
  end
  add(read('yingzhao-wuyun-alternating').source,'alternating')
  for _,name in ipairs({'punch-lesson','wave-reach','edge-lesson'})do add(read('yingzhao-'..name).actors.wuyun.source,name)end
  for _,name in ipairs({'summon-melee','hunt-lesson','hit-lesson','spacing-lesson'})do
   for index,case in ipairs(read('yingzhao-'..name).cases)do if case.source.demonstrator=='wuyun'then add(case.source,name..':'..index)end end
  end
  assert(#r.records==14,'Fresh core coverage missing')
  local wind=D.json.decode(D.Content:load(root..'/Test/yingzhao-wind-context-lesson-result.json'),32);assert(wind.status=='PASS')
  for index,case in ipairs(wind.cases)do add(case.source,'wind-context:'..index)end
  assert(#r.records==18 and #r.records<=20)
  local data=assert(P.inspect(r.records,'wuyun',6,2));r.samples=#data.samples;r.actions=data.actions;r.skillStates={}
  for _,s in ipairs(data.samples)do r.skillStates[s.state.skillState]=(r.skillStates[s.state.skillState]or 0)+1 end
  assert(data.actions['wind@left']==4 and data.actions['wind@right']==4 and data.actions.melee and data.actions.fmove and data.actions.bmove)
  assert((r.skillStates.cooldown or 0)>=8 and not r.skillStates.unknown)
  r.notAdopted=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
