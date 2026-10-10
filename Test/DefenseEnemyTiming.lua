local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local out=D.Path(root,'Test/defense-enemy-timing-result.json');local result={runId=tostring(os.time()),status='RUNNING',cases={}}
D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local a=require('Training.Arena').createAsync({scene='VRTraining',manualUpdate=true,minX=100,maxX=5000})
  a.externalCombat=true;a.externalRound=true
  local controller=require('Academy.DefenseEnemy').new(a)
  local tick=D.Node();tick:addTo(a.world);tick:schedule(function()controller:update(D.App.runningTime);return false end)
  local function wait(f,seconds)local deadline=D.App.runningTime+seconds;while not f()do assert(D.App.runningTime<deadline,'Defense enemy timed out');D.sleep(.01)end end
  for _,kind in ipairs({'blow','swing','butt','roll','bomb'})do
   for _,condition in ipairs({'defeated','withdrawn'})do
    a:beginDemo(190);a.enemy.visible=true;a.enemy.group=2;a.studentHP=1000;a.nextEnemy=math.huge
    controller.dead=false;controller.dying=false;controller.stopping=false
    -- Let the scene-load frame and the prior defeat track finish mixing out.
    D.sleep(.25)
    assert(controller.combat:start(kind));local strike=a.enemyStrike
    D.sleep(.1);assert(not strike.completedAt,'Test missed windup')
    if condition=='defeated'then a.enemyHP=0 else controller:stop()end
    local health=a.studentHP;wait(function()return strike.completedAt and (condition~='defeated' or controller.dead)end,12)
    assert(strike.completedAt-strike.startedAt>=strike.duration-.04,'Native attack cut short: '..kind..' elapsed='..(strike.completedAt-strike.startedAt)..' duration='..strike.duration)
    assert(a.studentHP==health,'Drained attack still damaged its target')
    if kind=='roll'then assert(controller.combat.stage=='rollEnd','Missing rollEnd')end
    if condition=='defeated'then
     assert(a.enemy.group==3,'Defeated enemy still blocks friendly fire')
     assert(controller.loseStarted>=strike.completedAt and controller.loseEnded-controller.loseStarted>=controller.loseDuration-.04,'Lose animation interrupted')
    else assert(not controller.dead and a.enemy.visible and math.abs(a.enemy.playable.recovery-.2)<.001,'Recovery missing')end
    result.cases[#result.cases+1]={skill=kind,condition=condition,attackSeconds=strike.completedAt-strike.startedAt,authoredSeconds=strike.duration,loseSeconds=condition=='defeated' and controller.loseEnded-controller.loseStarted or nil,healthUnchanged=true}
   end
  end
  tick:removeFromParent();result.status='PASS'
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end
 D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
