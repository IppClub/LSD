-- Verify the shared inputName/async-command contract, without editing a user save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','story-first-command-result.txt');D.Content:save(out,'LSD_STORY_FIRST_COMMAND_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local db=D.Path(D.Content.writablePath,'lsd-story-first-command-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local commands=require('System.Command');local old=rawget(commands,'qaStoryFirstCommand')
  commands.qaStoryFirstCommand=function() coroutine.yield('Command') end
  D.Director.entry:slot('Cleanup',function() commands.qaStoryFirstCommand=old end)
  local view=require('UI.Story')(D.Path(root,'Test','StoryFirstCommand.yarn'));view.tag='story-first-command-qa';view:addTo(D.Director.ui3D);view:showAsync()
  local function wait(f) local deadline=D.App.runningTime+8;while not f() do assert(D.App.runningTime<deadline,'First command UI stalled');D.sleep(.03) end end
  assert(view._advancing and view._current==nil and #view._reviews==0)
  for i=1,20 do view.confirm:emit('Tapped') end;D.sleep(.1);assert(#view._reviews==0,'Confirmation bypassed command')
  D.emit('Story.Advance');wait(function() return #view._reviews==1 and not view._advancing end)
  for i=1,20 do view.confirm:emit('Tapped') end;wait(function() return #view._reviews==2 and not view._advancing end)
  assert(view._reviews[2].text=='连续点击不能跳过的第二句。','Burst skipped a text row')
  view.confirm:emit('Tapped');wait(function() return #view._reviews==3 and not view._advancing end)
  local ended=false;view:slot('Ended',function() ended=true end);view.confirm:emit('Tapped');wait(function() return ended end)
  return 'PASS firstCommandBlocksConfirmation=true realAdvanceResumes=true burstDoesNotSkipText=true threeRows=true'
 end,debug.traceback)
 local report='LSD_STORY_FIRST_COMMAND_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
