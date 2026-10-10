local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-backstep-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local u=b.mentor;local enemy=b.enemies[1].unit
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge;e.stunUntil=math.huge;e.unit:stop();e.unit.velocityX=0 end
  for i=2,#b.enemies do b.enemies[i].hp=0;b.enemies[i].unit.visible=false end
  D.sleep(.5)
  local function pose(side,distance)
   assert(b:command('idle'));u.position=D.Vec2(8000,b.world.offset+155);u.velocity=D.Vec2.zero
   enemy.position=D.Vec2(8000+side*distance,b.world.offset+155);enemy.velocity=D.Vec2.zero;D.sleep(.1)
  end
  for _,side in ipairs({-1,1})do
   for _,back in ipairs({false,true})do
    pose(side,400);local direction=back and -side or side
    assert(b:command(direction>0 and 'right'or'left'));D.sleep(.25)
    assert(u.faceRight==(side>0),'Near enemy facing incorrect')
    assert(u.playable.current==(back and 'bmove'or'fmove'),'Wrong locomotion clip')
    assert(math.abs(u.velocityX-direction*(back and 135 or 270))<1,'Wrong locomotion speed')
    r.cases[#r.cases+1]={side=side,backward=back,clip=u.playable.current,speed=u.velocityX};save()
   end
   pose(side,1100);assert(b:command(side>0 and 'left'or'right'));D.sleep(.2)
   assert(u.faceRight==(side<0)and u.playable.current=='fmove'and math.abs(math.abs(u.velocityX)-270)<1,'Far travel should run forward')
   pose(side,790);assert(b:command(side>0 and 'left'or'right'));D.sleep(.3)
   assert(u.playable.current=='fmove'and u.faceRight==(side<0),'Held movement did not cross detection boundary')
   pose(side,400);u.faceRight=side<0;D.sleep(.1);assert(u.faceRight==(side>0),'Idle failed to face target')
  end
  assert(b:command('idle'));assert(u.velocityX==0)
  assert(b.mentorAim:begin());local facing=u.faceRight;enemy.x=u.x+(facing and -200 or 200);D.sleep(.1);assert(u.faceRight==facing,'Auto face changed held aim');b.mentorAim:cancel()
  pose(1,400);assert(b:command('left'));assert(b.mentorAim:begin());local movingFace=u.faceRight;enemy.x=u.x-200;D.sleep(.15);assert(u.faceRight==movingFace,'Moving aim changed facing');b.mentorAim:cancel();assert(b:command('idle'))
  b:finish('aborted','Backstep QA');D.sleep(.2)
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear()
  for _,character in ipairs({'ninilite','wuyun'})do
   local a=require('Training.Arena').createAsync({manualUpdate=true,characterId=character});assert(a.character.id==character);D.sleep(.3)
   assert(a:request('fmove','demo'));D.sleep(.2);assert(math.abs(math.abs(a.student.velocityX)-240)<1)
   a.student:stop();assert(a:request('bmove','demo'));D.sleep(.2)
   assert(a.student.playable.current=='bmove'and math.abs(math.abs(a.student.velocityX)-120)<1)
   r.cases[#r.cases+1]={characterId=character,backward=true,speed=a.student.velocityX,clip=a.student.playable.current};save()
  end

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
