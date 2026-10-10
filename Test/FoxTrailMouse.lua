-- Earned midpoint and real unit input prepare an ordinary mouse-playable scout checkpoint.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','fox-trail-mouse-result.txt');D.Content:save(out,'LSD_FOX_MOUSE_PREPARING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','fox-trail-mid-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fox%-trail%-mid%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fox-mouse-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20);while not f() do assert(D.App.runningTime<deadline,'Mouse preparation stalled');D.sleep(.03) end end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.foxTrail and w.foxTrail.phase=='walk2' end,30)
  local w=D.Platformer.Data.store.world;local c=w.foxTrail;local p=c.player
  wait(function() p.keyRight=p.unit.x<4075;return p.unit.x>=4075 end,25);p.keyRight=false;p.unit:stop();p.unit.velocityX=0
  wait(function() return c.phase=='checkpoint' end)
  return 'READY earnedMidpointCopy=true actualStart=true originalUnitTravel=true scoutUnrecorded=true mouseInputRequired=true'
 end,debug.traceback)
 local report='LSD_FOX_MOUSE_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
