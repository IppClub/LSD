local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-expanded-sources-result.json';local r={status='RUNNING',predictions={}}
D.Content:save(out,D.json.encode(r,false,true));D.thread(function()
 local ok,err=xpcall(function()
  local function read(path)return D.json.decode(D.Content:load(path),32)end
  local prior=read('/private/tmp/lsd-yingzhao-edge-counter-expanded-20261006/result.json');assert(prior.status=='PASS')
  local records=read('/private/tmp/lsd-yingzhao-fresh-corpus-20261006/result.json').records
  for _,case in ipairs(read('/private/tmp/lsd-yingzhao-range-lesson-20261006/result.json').cases)do records[#records+1]=case.source end
  local P=require('Training.YingzhaoPolicy')
  for _,case in ipairs(read('/private/tmp/lsd-yingzhao-boundary-melee-direction-20261006/result.json').cases)do if case.distance==350 and case.response=='wind'then
   records[#records+1]=case.source;local observation
   for _,step in ipairs(case.source.boss.steps)do if step.actor=='wuyun'and step.action=='wind'then observation=step.before;break end end
   local action,why=P.predict(prior.candidate,assert(observation));assert(why~='INVALID_OBSERVATION')
   r.predictions[#r.predictions+1]={skill=case.skill,side=case.side,action=action,reason=why,expected=case.side<0 and'wind@right'or'wind@left'}
  end end
  assert(#records==24 and P.validate(prior.candidate));local data=assert(P.inspect(records,'wuyun',6,2));assert(#data.samples==201)
  local db=D.Content.writablePath..'/expanded-sources.db';assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local store=require('Training.YingzhaoStore');for _,source in ipairs(records)do assert(store.saveAsync(source))end
  assert(#assert(store.listAsync('wuyun'))==24);assert(#assert(store.listAsync())==20)
  local overflow={};for i=1,33 do overflow[i]=records[1]end;local invalid,why=P.inspect(overflow,'wuyun',6,2);assert(not invalid and why=='INVALID_SOURCES')
  r.sources=24;r.samples=201;r.historyPage=20;r.overflowRejected=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
