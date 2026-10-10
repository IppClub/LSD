local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/factory-summon-cleanup-result.json','{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db';local dest=D.Content.writablePath..'/flower-cleanup-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  local b=require('Factory.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}})
  local rootEnemy=b.roots[3];local strike={};rootEnemy.enemyCombat:seed(strike)
  assert(strike.spawned==3 and #b.enemies==6 and b.summonsCreated==3)
  local children={};for _,child in ipairs(rootEnemy.enemyCombat.children)do children[#children+1]=child end
  b:finish('aborted','QA')
  assert(#b.enemies==3 and #rootEnemy.enemyCombat.children==0 and b.report.summonsCreated==3)
  for _,child in ipairs(children)do assert(child.closed and not child.enemy.parent)end
  D.sleep(.2);assert(b.phase=='aborted' and #b.enemies==3)
  r.hostCleanup=true;r.reportRetainsSummonCount=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil
 D.Content:save(root..'/Test/factory-summon-cleanup-result.json',D.json.encode(r))
end)
