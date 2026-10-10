local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/boss-distance-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local a=require('Training.Arena').createAsync({scene='AbandonedCity',manualUpdate=true,enemyAsset='dataotie',enemyMaxHP=320,enemySpeed=150,minX=0,maxX=3000,distance=1500})
  local c=a.enemyCombat;D.sleep(.3);local target={unit=a.student}
  r.choices={}
  for _,item in ipairs({{180,'trample'},{480,'pounce'},{850,'shot'},{1500,false}})do
   a.student.x=a.enemy.x-item[1];c.index=0;a.enemy.faceRight=false
   local selected=c:chooseSkill(target,item[1]);assert(selected==(item[2] or nil),'Wrong range choice');r.choices[tostring(item[1])]=selected or 'approach'
  end
  a.student.x=a.enemy.x+220;c.index=1;a.enemy.faceRight=false
  assert(c:chooseSkill(target,220)=='swing');r.rearSwipe=true
  local extra=a.spawnUnit('ninilite',1,a.enemy.x-100,{});local alive=false
  a.extraEnemyTargets={{unit=extra,alive=function()return alive end,damage=function()end}}
  local nearest=c:nearestMobileTarget();assert(nearest.unit==a.student);alive=true
  nearest=c:nearestMobileTarget();assert(nearest.unit==extra);a.extraEnemyTargets={};extra:removeFromParent()
  a:beginDemo(1500);D.sleep(.2);a.nextEnemy=D.App.runningTime
  local start=a.enemy.x;local deadline=D.App.totalTime+7
  while not a.enemyStrike do
   c:update(D.App.runningTime);assert(D.App.totalTime<deadline,'Boss did not close distance');D.sleep(.02)
  end
  local strike=a.enemyStrike;r.approachDistance=start-a.enemy.x;r.firstSkill=strike.kind;r.selectedDistance=strike.selectedDistance
  assert(r.approachDistance>150 and strike.kind=='shot' and strike.selectedDistance<=1250 and strike.selectedDistance>1000)
  local direction=strike.direction;a.student.x=a.enemy.x+650
  deadline=D.App.totalTime+6
  while not strike.completedAt do
   c:update(D.App.runningTime);assert(a.enemyStrike==strike and strike.direction==direction,'Retargeted active windup')
   assert(D.App.totalTime<deadline,'Attack animation stalled');D.sleep(.02)
  end
  assert(strike.shots==3 and strike.completedAt-strike.startedAt>=strike.duration-.04)
  r.fullLockedBurst=true
  a.enemyPhase='idle';a.enemy.x=a.minX+3;a.student.x=a.minX-800
  c:approach(target,803);assert(a.enemy.velocityX==0);r.boundaryStop=true
  a.enemy.x=1500;a.student.x=900;c.approaching=false;c:approach(target,600);assert(a.enemy.velocityX<0)
  a.student.x=1000;c:approach(target,500);assert(a.enemy.velocityX<0)
  a.student.x=1030;c:approach(target,470);assert(a.enemy.velocityX==0)
  a.student.x=1000;c:approach(target,500);assert(a.enemy.velocityX==0);r.hysteresis=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
