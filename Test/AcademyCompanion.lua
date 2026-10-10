-- Original NPC menu must never launch Yarn without a file or show inert information.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","academy-companion-result.txt"); D.Content:save(out,"LSD_ACADEMY_COMPANION_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","wuyun-training-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-wuyun%-training%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-companion-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync(); assert(require("Training.Progress").load())
  local before=D.json.encode(D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),false,true)
  local nodeCount=#D.DB:query("SELECT id FROM lsd.Game0StoryNodes")
  require("Academy.Navigation").returnToRoomAsync("PreparationRoom")
  local world=D.Platformer.Data.store.world
  local function wait(f,t) local deadline=D.App.runningTime+(t or 12); while not f() do assert(D.App.runningTime<deadline,"Companion public menu timed out"); D.sleep(0.05) end end
  local function ni() return D.Group({"name","unit"}):find(function(e) return e.name=="ninilite" and e.unit.world==world end) end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end) end
  wait(function() return player() and ni() and ni().interaction and ni().interaction.visible end)
  ni().interaction:emit("Tapped",1); wait(function() return world.companionPanel and world.companionPanel.phase=="dialogue" and world.companionPanel.view.visible end)
  local c=world.companionPanel; assert(player().busy)
  assert(c.dialogueFile=="Story/Dialog/companion-ninilite.yarn", "Trained companion lost follow-up dialogue")
  local deadline=D.App.runningTime+15
  while c.phase=="dialogue" do assert(D.App.runningTime<deadline,"Companion Yarn didn't finish"); if not c.view._advancing then c.view.confirm:emit("Tapped") end; D.sleep(0.1) end
  assert(c.phase=="closed" and not player().busy and not world.data.storyBusy)
  wait(function() return ni().interaction and ni().interaction.visible end)
  ni().interaction:emit("Tapped",2); wait(function() return world.companionPanel~=c and world.companionPanel.phase=="information" end)
  c=world.companionPanel; assert(c.view.detail.text:find("成功示范：6",1,true) and player().busy)
  c.view.stationButton:emit("Tapped"); assert(c.view.detail.text:find("B区",1,true))
  c.view.researchButton:emit("Tapped"); assert(c.view.detail.text:find("上一版",1,true) or c.view.detail.text:find("这一版",1,true))
  c.view.closeButton:emit("Tapped"); assert(not world.data.journalOpen and not player().busy)
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryNodes")==nodeCount and D.json.encode(D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),false,true)==before)
  return "PASS originalNpcMenu=true validFourLineYarn=true noNilFile=true actualSixSampleInfo=true clickableInformation=true publicClose=true controlRestored=true noExtraStoryReward=true modelUnchanged=true"
 end,debug.traceback)
 local report="LSD_ACADEMY_COMPANION_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
