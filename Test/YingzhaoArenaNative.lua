local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-arena-result.json';local r={status='RUNNING',scenes={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  for _,virtual in ipairs({true,false})do
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,nil,{virtual=virtual});local boss=b.enemies[1]
   r.initial={min=b.minX,max=b.maxX,boss=boss.enemy.x};save()
   assert(b.minX==200 and b.maxX==3640 and math.abs(boss.enemy.x-1920)<.01)
   assert(b.arena.minX==b.minX and b.wuyun.maxX==b.maxX)
   local samples=0
   for x=b.minX,b.maxX,80 do
    local floor
    b.world:raycast(D.Vec2(x,b.world.offset+80),D.Vec2(x,b.world.offset-80),false,function(body,p)if body.group==D.Platformer.Data.groupTerrain then floor=p.y end;return false end)
    assert(floor and math.abs(floor-b.world.offset)<10,'Missing level floor in arena');samples=samples+1
   end
   assert(not require('Enemy.YingzhaoHero').destination(boss.guard,{x=b.maxX-50}),'Hero can leave combat bounds')
   assert(b:start());boss.guard.nextAttack=math.huge;b.arena.mode='demo';b.wuyun.mode='demo'
   D.sleep(.4)
   for _,right in ipairs({false,true})do
    local edge=right and b.maxX or b.minX
    local sign=right and 1 or -1
    for _,a in ipairs(b.learners)do
     a.student.x=edge+sign*40;a.student.velocityX=sign*200;a:update()
     assert(math.abs(a.student.velocityX)<.01,'Outward velocity escaped clamp')
     a.student.x=edge+sign*40;a.student.velocityX=-sign*200;a:update()
     assert(a.student.velocityX*sign<-190,'Clamp erased inward escape velocity')
     a.student.velocityX=0
    end
    b.mentor.x=edge+(right and 40 or -40);b.arena.student.x=b.mentor.x;b.wuyun.student.x=b.mentor.x
    D.sleep(.1)
    for _,u in ipairs({b.mentor,b.arena.student,b.wuyun.student})do assert(u.x>=b.minX-.1 and u.x<=b.maxX+.1,'Party escaped arena')end
    local camera=b.world.camera.position.x;assert(camera>=b.cameraMinX-.1 and camera<=b.cameraMaxX+.1,'Camera retains patrol clamp')
    -- Let the authored smooth camera reach the requested edge before capture.
    D.sleep(2.5)
    r.edges=r.edges or {};r.edges[#r.edges+1]={scene=b.world.tag,right=right,cameraX=b.world.camera.position.x,mentorX=b.mentor.x,mentorY=b.mentor.y,niX=b.arena.student.x,niY=b.arena.student.y,visible=b.mentor.visible,opacity=b.mentor.opacity};save()
    D.App:saveScreenshot(root..'/Test/yingzhao-arena-'..(virtual and'vr'or'city')..(right and'-right'or'-left')..'.tga');D.sleep(.2)
   end
   local row={scene=virtual and'VRTraining'or'AbandonedCity',floorSamples=samples,width=b.maxX-b.minX,leftRetreat=1920-b.minX,rightRetreat=b.maxX-1920};r.scenes[#r.scenes+1]=row;save()
   b:finish('aborted','Arena geometry fixture');while b.phase=='settling'do D.sleep(.1)end
  end
  local patrol=require('Factory.PatrolBattle').createAsync(models)
  assert(patrol.minX==1200 and patrol.maxX==3300 and patrol.arena.origin==1700 and math.abs(patrol.mentor.x-1900)<.01)
  assert(patrol.cameraMinX==1950 and patrol.cameraMaxX==2500);r.patrolDefaultsPreserved=true;r.directionalClampVerified=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
