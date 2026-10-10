-- Full fresh profile through original UI events; title/name and controls are scripted, not OS input.
-- Engine event replay supplements native input QA; no HP, completion or model fixture.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-tutorial-precision-result.json")
local directory=D.Path(D.Content.writablePath,'lsd-fresh-tutorial-precision-qa-'..id)
assert(not D.Content:exist(directory)and D.Content:mkdir(directory)and not D.DB:existDB('lsd'))
local store=require('Save.Slots').new(directory);local db
-- No seeded Config fields: Start creates defaults and the original Yarn sets identity.
local result={status='RUNNING',osInput=false,openingTitleAndNameOS=false,scriptedTitleAndName=true,stages={}}
local function report(s)
 result.stage=s;result.status=s:match('^PASS')and'PASS'or s:match('^FAIL')and'FAIL'or'RUNNING'
 if result.status=='FAIL'then result.error=s end
 result.database=db;result.stages[#result.stages+1]={stage=s,time=D.App.runningTime}
 D.Content:save(out,D.json.encode(result,false,true));print('LSD_FRESH_OPENING_SCRIPTED_'..result.status)
end
report("RUNNING phase=start")
local title=require('Save.Title').open({store=store})
D.thread(function()
 local ok,result=xpcall(function()
  title.new:emit('Tapped')
  local startDeadline=D.App.runningTime+120
  while not title.selected do assert(D.App.runningTime<startDeadline,'Actual new journey click required');D.sleep(.05)end
  db=D.Path(directory,title.selected)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,seconds,message)
   local deadline=D.App.runningTime+(seconds or 30)
   while not test() do assert(D.App.runningTime<deadline,message or "Fresh journey timed out"); D.sleep(0.05) end
  end
  local function move(left,right)
   local hud
   D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end)
   assert(hud,'Tutorial HUD missing')
   hud.move:emit('Left',left);hud.move:emit('Right',right)
  end
  local nameSeen=false
  local function advance()
   local story
   if D.Director.ui3D.children then D.Director.ui3D.children:each(function(n) if n._runner and n.visible then story=n end end) end
   local input
   if D.Director.ui3D.children then D.Director.ui3D.children:each(function(n) if n.box and n.label and n.visible then input=n end end) end
   if input then
    if not nameSeen then nameSeen=true; report("RUNNING phase=native-name-input") end
    if not input._qaInputSent then input._qaInputSent=true;input.box:emit('TextInput','旅程QA');input.box:emit('KeyPressed','Return')end
    return true
   end
   if story and not story._advancing then
    if story._options and story.answerList.children and story.answerList.children.count>0 then
     local index=1
     for i,option in ipairs(story._options) do if option.text:find("女",1,true) then index=i end end
     local answer=story.answerList.children:get(index)
     if answer and answer.touchEnabled then answer:emit("Tapped") end
    elseif not story._options then story.confirm:emit("Tapped") end
   end
   return story~=nil
  end
  local openingDeadline=D.App.runningTime+300
  while not player() do
   assert(D.App.runningTime<openingDeadline,"Full opening did not reach tutorial; check native name input")
   advance(); D.sleep(0.15)
  end
  local config=require("Data.Config")
  assert(nameSeen and config.charName=="旅程QA" and config.char=="charF","Native name/gender not preserved")
  assert(config.skipOP==1,"Opening did not finish and persist skipOP")
  assert(not world().data.navigationAttached,"Fresh opening incorrectly skipped tutorial")
  report("RUNNING phase=first-meeting")
  local deadline=D.App.runningTime+90; local enemy
  while not enemy do
   assert(D.App.runningTime<deadline,"First meeting did not reach battle")
   advance(); enemy=D.Group({"monster","unit"}):find(function(e) return e.unit.world==world() end); D.sleep(0.25)
  end
  report("RUNNING phase=tutorial-combat")
  local e=assert(player());move(true,false);D.sleep(.25);move(false,false)
  local hud
  wait(function()
   local talking=advance();D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end)
   if hud and hud.visible and not talking then
    local delta=enemy.unit.x-assert(player()).unit.x;move(delta<220,delta>380)
   elseif hud then move(false,false)end
   if hud and hud.weapon.visible and hud.visible then move(false,false);return true end
   return false
  end,60,'Weapon introduction did not finish')
  D.sleep(.3);assert(hud.aimHint and hud.aimHint.node.parent==hud)
  result.checks={};result.screenshots={};local attacks=0
  -- kinetic create replaces the attack slot. Append the observer only after
  -- that action has started, preserving its production projectile callback.
  local observer=D.Node();observer:addTo(e.unit);local observing=false;local actionStarts=0
  observer:schedule(function()
   local kinetic=e.unit:isDoing('kinetic')
   if kinetic and not observing then
    actionStarts=actionStarts+1
    e.unit.playable:slot('attack',function()attacks=attacks+1 end)
   end
   observing=kinetic;return false
  end)
  local function shotCount()return attacks end
  local function snapshot(name)
   local path=D.Path(D.Content.writablePath,'tutorial-precision-'..name..'.tga')
   D.App:saveScreenshot(path);D.sleep(.1);result.screenshots[#result.screenshots+1]={name=name,path=path,size={width=D.App.bufferSize.width,height=D.App.bufferSize.height}}
  end
  local originalSize=D.App.winSize
  for _,size in ipairs({{960,540,'1920'},{683,384,'1366'}})do
   D.App.winSize=D.Size(size[1],size[2]);D.sleep(.3)
   local before=shotCount();D.emit('Skill.Began');D.sleep(.3)
   assert(e.keySkill and hud.aimHint.phase=='aiming' and hud.aimHint.node.visible)
   snapshot(size[3]..'-aiming');D.sleep(.9)
   assert(e.keySkill and hud.aimHint.phase=='precision' and hud.aimHint.label.text:find('精瞄中',1,true))
   local line=e.unit:getChildByTag('aim');assert(line and line.visible)
   local startAngle=line.angle;D.sleep(.1);assert(math.abs(line.angle-startAngle)<4,'Tutorial precision sweep too fast')
   snapshot(size[3]..'-precision')
   D.emit('Skill.Ended',true);D.sleep(.2)
   assert(not e.keySkill and not line.visible and hud.aimHint.phase=='idle' and shotCount()==before,'Cancellation fired or left stale aim')
   snapshot(size[3]..'-cancelled')
  end
  local before=shotCount();D.emit('Skill.Began');D.sleep(.05);D.emit('Skill.Ended');D.sleep(1.3)
  assert(shotCount()==before+1,'Normal quick-release tutorial shot missing')
  D.App.winSize=originalSize;D.sleep(.2)
  result.checks={actualNewJourney=true,originalTutorial=true,precisionBothSizes=true,cancelNoShot=true,releaseOneShot=true,hintLifecycle=true}
  result.character=require('Data.Config').char;result.attackEvents=attacks;result.kineticStarts=actionStarts
  report('PASS fresh tutorial precision UI and cancellation, no injected profile or HP')
 end,debug.traceback)
 if not ok then report('FAIL '..tostring(result))end
end)
