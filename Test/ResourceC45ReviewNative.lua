local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-c45-review-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local source='/private/tmp/lsd-combat-qa-f5y_kicg/save/resource-demo-player-1791219994.db'
  local manifest=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-06/resource-c45-trials/run.json'),32)
  assert(manifest.status=='PASS' and source:sub(1,#manifest.workDirectory)==manifest.workDirectory)
  local dest=D.Content.writablePath..'/resource-c45-review-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local legacy=D.DB:query('SELECT payload FROM lsd.Game0FlowerTrials');local teams=D.DB:query('SELECT payload FROM lsd.Game0FlowerTeamTrials')
  for _,row in ipairs(legacy)do assert(require('Training.FlowerTrialStore').validate(D.json.decode(row[1],32)))end
  for _,row in ipairs(teams)do assert(require('Training.FlowerTrialStore').validateTeam(D.json.decode(row[1],32)))end
  r.legacyTrials=#legacy;r.legacyTeamTrials=#teams
  local rows=assert(require('Training.ResourceC45Trials').history('ninilite'));assert(#rows==2)
  local C=require('Training.ResourceC45Comparison');local pair=assert(C.build(rows[2],rows[1]))
  assert(pair.basic.status=='won' and pair.basic.cost==109 and pair.candidate.status=='failed' and pair.candidate.cost==148)
  local bad=D.json.decode(D.json.encode(rows[1]),32);bad.status='aborted';assert(not C.build(rows[2],bad))
  bad=D.json.decode(D.json.encode(rows[1]),32);bad.resourceSource.policy.rules={{conditions={},action='idle'}}
  assert(not require('Training.ResourceC45Trials').saveAsync(bad))
  local values={};for _,line in ipairs(rows[1].episode.resources.quote.lines)do values[#values+1]={actor=line.actor,item=line.item,quantity=line.quantity}end
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,rows[1].setup.models,nil,nil,nil,values);D.sleep(.2)
  assert(c.resourceComparison and c.label.text:find('同配装资源对照',1,true))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-c45-comparison.tga');D.sleep(.2)
  r.checks={'frozen trials reread and source rebuild','same setup comparison','aborted excluded','source policy tampering rejected','player comparison displayed'};r.pair=pair
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
