-- Real Platformer bullets: broad body collision disabled for this geometry fixture.
-- Tests current-pose sweep, not moving-shape CCD, terrain or gameplay integration.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-projectile-native-result.json';local report={status='RUNNING',shots={}}
 local function save()D.Content:save(out,D.json.encode(report))end;save()
 local ok,err=xpcall(function()
  local arena=require('Training.Arena').createAsync({enemySpeed=0})
  arena.externalCombat=true;arena.enemy.visible=false;arena.enemy.group=D.Platformer.Data.groupHide
  local base=root..'/Docs/artwork/boss-hitboxes'
  local skel=base..'/export/dataotie-hitboxes.skel';local atlas=root..'/Spine/dataotie.atlas'
  D.Cache:loadAsync('spine:'..skel..'|'..atlas)
  local m=assert(D.Spine(skel,atlas));m.look='default';m.scaleX=.4;m.scaleY=.4;m.position=D.Vec2(1100,arena.world.offset+20);m:addTo(arena.world)
  m:play('idle',true);D.sleep(.2);m.speed=0
  local manifest=D.json.decode(D.Content:load(base..'/vertex-probes.json'))
  local parts={};for _,p in ipairs(manifest)do parts[p.id]={maxAP=20,armoredMultiplier=0,exposedMultiplier=1,armoredResponse='stop'}end
  local Journal=require('Training.CombatJournal');local j=Journal.new('native-part-fixture',{observation=3,action=2},10)
  local view
  local target=require('Combat.PartTarget').new(m,manifest,arena.world,{id='taotie',maxHP=100,parts=parts},function(event)assert(j:hit(event));if view then view:hit(event,arena.world)end end)
  view=require('Combat.StatusView').new(target.damage,'大饕餮 · 部位验证',{tail='尾部'});view.node.position=D.Vec2(600,600);view.node:addTo(D.Director.ui3D)
  local bounds={minX=math.huge,maxX=-math.huge,minY=math.huge,maxY=-math.huge}
  for _,p in ipairs(target.regions)do for _,v in ipairs(p.vertices)do bounds.minX=math.min(bounds.minX,v.x);bounds.maxX=math.max(bounds.maxX,v.x);bounds.minY=math.min(bounds.minY,v.y);bounds.maxY=math.max(bounds.maxY,v.y)end end
  local y
  for candidate=bounds.minY,bounds.maxY,7 do if target:probe({x=bounds.minX-100,y=candidate},{x=bounds.maxX+100,y=candidate})then y=candidate+1;break end end
  assert(y,'No shootable silhouette')
  local function fire(id,height,weapon)
   local step=assert(j:begin({armor='observed',distance=500},{name='shoot',intendedPart='unknown'},D.App.runningTime,true));assert(j:attach(step,id))
   local def=D.Platformer.BulletDef();def.lifeTime=1;def.gravity=D.Vec2.zero;def.highSpeedFix=true;def:setAsCircle(1);def:setVelocity(0,5000)
   def.face=D.Platformer.Face(function()local n=D.DrawNode();n:drawDot(D.Vec2.zero,4,D.Color(0xffffffff));return n end)
   arena.student.faceRight=true;local bullet=D.Platformer.Bullet(def,arena.student);bullet.targetAllow=0
   bullet.position=D.Vec2(bounds.minX-100,height);bullet:addTo(arena.world)
   local previous={x=bullet.x,y=bullet.y};local event;local deadline=D.App.runningTime+1.5;local ticks=0
   while bullet.parent do
    assert(D.App.runningTime<deadline,'Bullet did not expire');D.sleep(.001);ticks=ticks+1
    if bullet.parent then
     target:sample();local current={x=bullet.x,y=bullet.y};local hit=target:probe(previous,current)
     if hit then event=assert(target:apply(hit,{id=id,contactId='contact',source='nini',weapon=weapon}));bullet:removeFromParent();break end
     previous=current
    end
   end
   target:expire(id);assert(j:expire(id));assert(j:finish(step,{hp=target.damage.hp},D.App.runningTime,false))
   local transition=assert(j:transition(step));report.shots[#report.shots+1]={id=id,ticks=ticks,event=event,totals=transition.totals}
   return event
  end
  local a=assert(fire('break',y,{id='emp',armorDamage=25,healthDamage=0}));assert(a.armorBroken and a.armorDamage==20 and a.healthDamage==0)
  local b=assert(fire('damage',y,{id='kinetic',armorDamage=0,healthDamage=15}));assert(b.part==a.part and b.healthDamage==15)
  local hp=target.damage.hp;assert(not fire('miss',bounds.maxY+100,{id='kinetic',armorDamage=0,healthDamage=15}));assert(target.damage.hp==hp)
  report.display={actualHP=view.hpBar.scaleX,actualAP=view.apBar.scaleX,text=view.armor.text};assert(math.abs(view.hpBar.scaleX-.85)<.00001 and view.apBar.scaleX==0 and view.armor.text:find('已破甲'),'BAR_STATE');D.sleep(.8);report.effectCount=#view.effects;assert(#view.effects==0,'EFFECT_LEAK');view.node:removeFromParent();D.sleep(.05);assert(view.closed,'VIEW_CLEANUP')
  report.display.feedbackCleaned=true;report.hp=hp;report.part=a.part;report.noSaveTouched=not D.DB:existDB('lsd');target:close();j:close('COMPLETE')
 end,debug.traceback)
 report.status=ok and 'PASS' or 'FAIL';report.error=not ok and err or nil;save()
end)
