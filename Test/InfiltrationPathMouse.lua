-- Prepare a real earned checkpoint; only native mouse taps trigger hide and withdrawal.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/infiltration-path-mouse-result.txt');D.Content:save(out,'LSD_INFILTRATION_PATH_MOUSE_PREPARING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/infiltration-path-mid-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-infiltration%-path%-mid%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-infiltration-path-mouse-qa-'..id..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local function wait(fn,t,msg)local deadline=D.App.runningTime+(t or 20);while not fn()do assert(D.App.runningTime<deadline,msg or 'Mouse path stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.path and w.infiltration.path.phase=='walking'end,40)
  local w=D.Platformer.Data.store.world;local c=w.infiltration.path;local p=c.player;local g=c.guards[1]
  local deadline=D.App.runningTime+300
  while not c.hidden do
   assert(D.App.runningTime<deadline,'Native hide tap missing')
   wait(function()return g.sign==1 and g.unit.x>2700 end,15)
   p.keyRight=true;wait(function()return p.unit.x>2536 or c.hidden end,8);p.keyRight=false;p.unit:stop();p.unit.velocityX=0
   D.Content:save(out,'LSD_INFILTRATION_PATH_MOUSE_READY runId='..id..' db='..db..'\n')
   while not c.hidden and p.unit.x>2530 do assert(D.App.runningTime<deadline,'Native hide tap missing');D.sleep(.02)end
  end
  local hiddenAt=D.App.runningTime
  assert(p.busy and c.action.visible and c.visited[1]and not c.store:load().completed)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/infiltration-path-mouse-hidden.tga'))
  wait(function()return D.Platformer.Data.store.world~=w and D.Platformer.Data.store.world.tag=='OperationRoom'end,90,'Native withdrawal tap missing')
  local main=assert(require('Story.InfiltrationStore').open()):load();local saved=c.store:load();assert(not main.active and main.firstPatrol and saved.started and not saved.completed,'Withdrawal changed earned path/combat')
  assert(D.App.runningTime-hiddenAt>=.4,'Hide/withdrawal unexpectedly instant')
  return 'PASS preparedPhysicalApproach=true earnedPathMidpointCopy=true actualMouseHide=true originalSkillButton=true actualMouseWithdrawal=true originalOperationRoom=true firstPatrolRetained=true unfinishedPathNotCompleted=true userDatabaseUntouched=true'
 end,debug.traceback)
 local report='LSD_INFILTRATION_PATH_MOUSE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
