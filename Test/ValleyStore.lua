-- Explicit progress fixtures test durability; physical activity gameplay is separate.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));D.Content:insertSearchPath(1,D.Path(root,'Script'))
local id=tostring(os.time());local out=D.Path(root,'Test','valley-store-result.txt');D.Content:save(out,'LSD_VALLEY_STORE_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','valley-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-valley%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-valley-store-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  require('Data.Config'):loadAsync();local R=require('Story.ValleyRules');local S=require('Story.ValleyService');local s=assert(S.open());local story=assert(require('Story.Service').open())
  local can,why=story:canRead('valley-days','OuterHeaven');assert(not can and why=='ACTIVITY_REQUIRED')
  local farm=R.initial('farm');farm.plots[1]=1;assert(s:saveAsync('farm',farm));farm.plots[1]=2;farm.watered[1]=os.time();assert(s:saveAsync('farm',farm))
  s=assert(S.open());assert(s:load('farm').plots[1]==2 and s:load('farm').watered[1]==farm.watered[1])
  assert(#D.DB:query('SELECT id FROM lsd.Game0ValleyRewards')==0,'Partial farming rewarded')
  assert(not s:saveAsync('farm',R.initial('farm')),'Progress regressed')
  assert(not s:saveAsync('language',{correct=9}))
  local complete={plots={3,3,3},watered={farm.watered[1],os.time(),os.time()}}
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_valley_store BEFORE INSERT ON Game0ValleyRewards BEGIN SELECT RAISE(ABORT,'QA valley store reward fault'); END")>=0)
  assert(not s:saveAsync('farm',complete));assert(s:load('farm').plots[1]==2 and #D.DB:query('SELECT id FROM lsd.Game0ValleyRewards')==0)
  D.DB:exec('DROP TRIGGER lsd.fail_valley_store');assert(s:saveAsync('farm',complete));assert(s:saveAsync('farm',complete));assert(#D.DB:query('SELECT id FROM lsd.Game0ValleyRewards')==1)
  D.DB:exec('UPDATE lsd.Game0ValleyMeta SET schemaVersion=2 WHERE id=1')
  local before={};for _,name in ipairs({'Game0ValleyMeta','Game0ValleyActivities','Game0ValleyRewards'}) do before[name]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..name),false,true) end
  local future,err=S.open();assert(not future and err=='INCOMPATIBLE_VALLEY_SAVE');assert(not s:saveAsync('farm',complete))
  for name,value in pairs(before) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name),false,true),'Future valley schema mutated '..name) end
  return 'PASS earnedInitialValleyCopy=true languageGate=true actualPartialPersistence=true partialNoReward=true monotonic=true malformedRejected=true completeRewardAtomic=true idempotent=true futureReadOnly=true explicitProgressFixtures=true'
 end,debug.traceback)
 local report='LSD_VALLEY_STORE_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
