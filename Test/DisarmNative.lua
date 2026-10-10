local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  D.Cache:loadAsync('spine:zhongyingzhao-weapon.skel|zhongyingzhao.atlas')
  local function holder()
   local n=D.Node();n.playable=D.Spine('zhongyingzhao-weapon.skel|zhongyingzhao.atlas');n.playable:addTo(n);n:addTo(b.world);n.playable:play('gunidle',true);return n
  end
  local h=holder();local M=require('Combat.Disarm')
  local function wait(fn)local stop=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<stop,'Disarm timeout');D.sleep(.01)end end
  wait(function()return b.mentor.onSurface end)
  local owner=b.mentor;local gun=owner.playable:getSlot('pistol');local originalX=gun.scaleX
  assert(b.mentorAim:begin());local lease=assert(M.take(owner,h,{leftAuthored=true,duration=1}))
  D.sleep(.05);assert(not b.mentorAim.held and not b.mentorAim:release());assert(owner.data.weaponDisarmed and gun.scaleX==0 and h.playable:getSlot('pistol'))
  assert(not b:command('shoot'));assert(not M.take(owner,holder()));assert(not M.take(owner,h));r.aimCancelled=true;r.exclusive=true
  wait(function()return not lease.active end);assert(lease.reason=='EXPIRED' and gun.scaleX==originalX and owner.playable:getSlot('pistol')==gun and not owner.data.weaponDisarmed)
  assert(not M.release(lease));r.expiredRestoredSameNode=true
  local count=#b.projectiles;assert(b:command('shoot'));lease=assert(M.take(owner,h,{leftAuthored=true,duration=4}))
  wait(function()return not owner:isDoing('groundMentorShot')end);assert(#b.projectiles==count,'In-flight mentor attack emitted after disarm')
  assert(M.release(lease));r.pendingMentorShotCancelled=true
  b.nextMentorShot=0;assert(b:command('shoot'));lease=assert(M.take(owner,h,{leftAuthored=true,duration=.05}))
  wait(function()return not lease.active and not owner:isDoing('groundMentorShot')end)
  assert(#b.projectiles==count,'Returned weapon revived cancelled old shot');r.earlyReturnDoesNotReviveShot=true
  b.nextMentorShot=0;assert(b:command('shoot'));wait(function()return #b.projectiles>count end);wait(function()return not owner:isDoing('groundMentorShot')end);r.mentorResumed=true
  lease=assert(M.take(owner,h,{leftAuthored=true,valid=function()return b.phase=='playing'end}));b.phase='ready';wait(function()return not lease.active end);assert(lease.reason=='ENCOUNTER_ENDED' and gun.scaleX==originalX);r.exitRestored=true
  b.phase='playing';lease=assert(M.take(owner,h,{leftAuthored=true}));h:removeFromParent();wait(function()return not lease.active end);assert(gun.scaleX==originalX and not owner.data.weaponDisarmed);r.holderRemovalRestored=true
  local a=require('Training.Arena').createAsync({world=b.world,manualUpdate=true,characterId='wuyun',origin=6500,actionPrefix='disarmWu_'})
  a.mode='demo';wait(function()return a.student.onSurface end);h=holder();local studentGun=a.student.playable:getSlot('pistol');local energy=a.studentEnergy
  count=#a.projectiles;assert(a:request('laser','demo'));lease=assert(M.take(a.student,h,{leftAuthored=true}))
  assert(lease.asset=='empgun' and not a:available('laser'))
  wait(function()return not a:isAttacking()end);assert(#a.projectiles==count and a.studentEnergy==energy,'Disarmed shot emitted or spent energy')
  assert(a:available('melee') and a:available('fmove'),'Disarm disabled non-gun actions');M.release(lease);assert(a.student.playable:getSlot('pistol')==studentGun)
  a.nextShot=0;assert(a:request('laser','demo'));wait(function()return #a.projectiles>count end);wait(function()return not a:isAttacking()end);r.learnerResumed=true;r.nonGunActionsAvailable=true
  lease=assert(M.take(a.student,h,{leftAuthored=true}));a.student:removeFromParent();wait(function()return not lease.active end);assert(not h.playable:getSlot('pistol'));r.ownerRemovalCleared=true
  b.phase='ready'
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
