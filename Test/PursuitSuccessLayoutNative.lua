local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',scope='Normal pursuit victory via public preparation and scripted HUD; actual success controller button bounds at two resolutions and original continuation',osInput=false,originalUnlockAlreadyEarned=true}
 local function save()D.Content:save(root..'/Test/pursuit-success-layout-result.json',D.json.encode(r,false,true))end;save()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-ambush-warning-ruins-route-20261008/result.json'),32);assert(prior.status=='PASS' and prior.stage=='valley-arrival' and prior.outcome=='won')
  local db=D.Path(D.Content.writablePath,'pursuit-current-retry-'..os.time()..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=prior.database;save()
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();local S=assert(require('Mission.Service').open());assert(S:recoverAsync());local story=assert(require('Story.Service').open());local E=require('Economy.Store');assert(E.open()and not E.active())
  local before=E.wallet().available;assert(before==prior.balance);r.balanceBefore=before
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local originalModels=models();assert(story:summary().mission.unlocks['ruins-diversion-complete'])
  local function wait(fn,t)local untilAt=D.App.runningTime+(t or 20);while not fn()do assert(D.App.runningTime<untilAt,'Retry wait timed out');D.sleep(.03)end end
  local c;local panel=assert(require('Economy.Preparation').openAsync('c0-m06',nil,nil,function(service,attempt)c=require('Ruins.PursuitLevel').openAsync(service,attempt)end))
  local function setBudget(p,values)
   for i,key in ipairs({'mentor:kinetic','mentor:smoke','mentor:flare'})do while p.values[key]~=values[i]do p.buttons[i][p.values[key]<values[i] and 1 or -1]:emit('Tapped')end end
  end
  setBudget(panel,{4,6,2});assert(panel.quote.total==62);panel.saveButton:emit('Tapped');wait(function()return c end,30)
  local c=D.Platformer.Data.store.world.pursuitLevel;local b=c.battle
  wait(function() return b.mentor.onSurface end)
  local hud=assert(D.Director.ui3D:getChildByTag('pursuit-hud'))
  hud.move:emit('Right',true)
  local shot=false;local initialFlare=false;local deadline=D.App.runningTime+100;r.controlLog={}
  while b.phase=='playing'or b.phase=='saving'do
   local now=D.App.runningTime;assert(now<deadline,'Pursuit escape stalled')
   if b.phase=='playing'then
    local nearest,lastEnemy
    for _,e in ipairs(b.enemies)do if e.hp>0 and not e.untargetable then local distance=math.abs(e.unit.x-b.mentor.x);nearest=math.min(nearest or math.huge,distance);lastEnemy=math.max(lastEnemy or -math.huge,e.unit.x)end end
    local busy=b.stamina.down or b.mentor:isDoing('groundMentorShot')or b.mentor:isDoing('pursuitTool')
    if not shot and b.mentor.x>=7350 and not busy then
     hud.weapon:emit('TapBegan');D.sleep(.04);hud.weapon:emit('TapEnded');shot=true;r.controlLog[#r.controlLog+1]={kind='shot',x=b.mentor.x,at=now-b.started}
    elseif shot and b.mentorHits>0 and not initialFlare and not busy then
     c.toolButtons.flare:emit('TapBegan');initialFlare=true;r.controlLog[#r.controlLog+1]={kind='first-flare',x=b.mentor.x,at=now-b.started}
    elseif not busy and nearest and nearest<800 and b.mentor.x>7800 and (not lastEnemy or lastEnemy<b.mentor.x or b.mentorHP<65)and not b:inSmoke(b.mentor.x)and now>=(b.toolReady.smoke or 0)and b.supplies:canSpend('mentor','smoke')then
     c.toolButtons.smoke:emit('TapBegan');r.controlLog[#r.controlLog+1]={kind='smoke',x=b.mentor.x,hp=b.mentorHP,at=now-b.started}
    elseif not busy and nearest and nearest<500 and b.mentor.x>8200 and now>=(b.toolReady.flare or 0)and b.supplies:canSpend('mentor','flare')then
     c.toolButtons.flare:emit('TapBegan');r.controlLog[#r.controlLog+1]={kind='flare',x=b.mentor.x,hp=b.mentorHP,at=now-b.started}
    end
    if b.mentorHP<=65 and not b.medicineBusy and (require('Story.Supplies').count('mentor','first-aid-water')or 0)>0 then c.toolButtons.medicine:emit('TapBegan');r.controlLog[#r.controlLog+1]={kind='medicine',x=b.mentor.x,at=now-b.started}end
   end
   D.sleep(.04)
  end
  r.report=b.report;r.outcome=b.phase;r.mentorHP=b.mentorHP;r.finalX=b.mentor.x;save()
  assert(b.phase=='won',b.reason..' HP='..b.mentorHP..' x='..b.mentor.x)
  wait(function() return c.result end)
  assert(not c.result.baseButton.visible and not c.result.baseButton.touchEnabled)
  r.layoutCases={};save()
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.4);c.result:alignLayout();D.sleep(.1)
   local buffer=D.App.bufferSize;local button=c.result.againButton
   local low=button:convertToWorldSpace(D.Vec2.zero)+D.Vec2(buffer.width/2,buffer.height/2)
   local high=button:convertToWorldSpace(D.Vec2(button.width,button.height))+D.Vec2(buffer.width/2,buffer.height/2)
   r.layoutCases[#r.layoutCases+1]={resolution={buffer.width,buffer.height},low={low.x,low.y},high={high.x,high.y},buttonX=button.x};save()
   D.App:saveScreenshot(D.Path(D.Content.writablePath,'pursuit-success-'..size.width..'x'..size.height..'.tga'));D.sleep(.1)
   assert(button.visible and button.touchEnabled and low.x>=0 and low.y>=0 and high.x<=buffer.width and high.y<=buffer.height,'Pursuit continue button outside viewport')
  end
  assert(models()==originalModels and not E.active());r.balance=E.wallet().available;r.report=b.report
  c.result.againButton:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='OuterHeaven' and w.valleyVisit end,30);r.returnScene=D.Platformer.Data.store.world.tag
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and tostring(err)or nil;save()
end)
