local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-gain-probe-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local a=D.json.decode(D.Content:load(root..'/Test/yingzhao-wuyun-alternating-result.json'),32)
  local b=D.json.decode(D.Content:load(root..'/Test/yingzhao-punch-lesson-result.json'),32)
  assert(a.status=='PASS'and b.status=='PASS')
  local data=assert(require('Training.YingzhaoPolicy').inspect({a.source,b.actors.wuyun.source},'wuyun'));assert(#data.samples==13)
  r.constant={}
  for _,filtered in ipairs({false,true})do
   local fields={}
   for _,name in ipairs(require('Training.YingzhaoFeatures').names)do
    local first=data.samples[1].state[name];local varied=false
    for _,s in ipairs(data.samples)do if s.state[name]~=first then varied=true;break end end
    if not filtered or varied then fields[#fields+1]=name else r.constant[#r.constant+1]=name end
   end
   local header,types={},{};for _,name in ipairs(fields)do header[#header+1]=name;types[#types+1]='C'end;header[#header+1]='action';types[#types+1]='C'
   local rows={table.concat(header,','),table.concat(types,',')}
   for _,s in ipairs(data.samples)do local row={};for _,name in ipairs(fields)do row[#row+1]=s.state[name]end;row[#row+1]=s.action;rows[#rows+1]=table.concat(row,',')end
   local nodes={};local fit,why=D.ML.BuildDecisionTreeAsync(table.concat(rows,'\n'),5,function(depth,name,op,value)nodes[#nodes+1]={depth=depth,name=name,op=op,value=value}end)
   assert(fit,why);r[filtered and 'varied' or 'all']={fit=fit,nodes=nodes,fields=fields}
  end
  assert(r.varied.fit>=r.all.fit)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
