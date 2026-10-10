-- Native animated geometry and damage adapter; no fabricated part selection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-armor-result.json';local r={status='RUNNING',poses={},parts={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  local E=require('Enemy.BigYingzhao');E.loadAsync()
  local record={enemy=E.create(b.world,7800),enemyHP=1000};local unit=record.enemy
  local Armor=require('Enemy.BigYingzhaoArmor');local a=Armor.new(record,b.world)
  local contacts={};local colors={head=0xffff6666,torso=0xffeeee55,flank=0xff55ddff,arms=0xffaa88ff,forelegs=0xff55ee77,hindlegs=0xffffaa55}
  local overlay=D.DrawNode();overlay.order=100;overlay:addTo(b.world)
  b.world.camera.zoom=.75;b.world.camera.position=D.Vec2(7800,400)
  D.sleep(.5)
  for _,flip in ipairs({false,true})do
   unit.faceRight=flip
   for _,clip in ipairs({'idle','idle1','move','move2','punch','massive','wave','hunt','hero','hero2','hero3','hit','lose','dizzy','dizzy1'})do
    unit.playable.speed=1;assert(unit.playable:play(clip,false)>0);D.sleep(.18);unit.playable.speed=0;a:sample();a:sample()
    assert(#a.target.regions==41,'Missing hulls');overlay:clear()
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    for _,p in ipairs(a.target.regions)do
     local v=p.vertices
     for i,q in ipairs(v)do
      assert(q.x==q.x and q.y==q.y)
      minX=math.min(minX,q.x);maxX=math.max(maxX,q.x);minY=math.min(minY,q.y);maxY=math.max(maxY,q.y)
      local n=v[i%#v+1];overlay:drawSegment(overlay:convertToNodeSpace(b.world:convertToWorldSpace(D.Vec2(q.x,q.y))),overlay:convertToNodeSpace(b.world:convertToWorldSpace(D.Vec2(n.x,n.y))),1,D.Color(colors[p.id]))
     end
    end
    assert(maxX-minX>200 and maxY-minY>250,'Degenerate native probes')
    -- Sweep from outside the entire model in four directions. First boundary
    -- decides the part, including occlusion by another limb.
    for i=0,80 do
     local x=minX+(maxX-minX)*i/80;local y=minY+(maxY-minY)*i/80
     for _,ray in ipairs({{{x=minX-10,y=y},{x=maxX+10,y=y}},{{x=maxX+10,y=y},{x=minX-10,y=y}},{{x=x,y=minY-10},{x=x,y=maxY+10}},{{x=x,y=maxY+10},{x=x,y=minY-10}}})do
      local c=a:probe(ray[1],ray[2]);if c then contacts[c.part]=c end
     end
    end
    r.poses[#r.poses+1]={clip=clip,flip=flip,width=maxX-minX,height=maxY-minY,centerX=(minX+maxX)/2,unitX=unit.x,unitOrder=unit.order}
    if clip=='idle'then D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-armor-'..tostring(flip)..'.tga');D.sleep(.1)end
   end
  end
  local weapons=require('Combat.WeaponProfiles');local serial=0
  local function hit(c,w)
   serial=serial+1;local shot={id='armor-'..serial,contactId='contact',source='mentor',weapon=w}
   local e=assert(a:apply(c,shot));local duplicate,why=a:apply(c,shot);assert(not duplicate and why=='INVALID_OR_DUPLICATE_HIT');a:expire(shot.id)
   local late,reason=a:apply(c,shot);assert(not late and reason=='INACTIVE_ATTACK');return e
  end
  for id in pairs(Armor.partNames)do
   local c=assert(contacts[id],'No externally reachable '..id);local p=a.target.damage.parts[id];local other={}
   for k,v in pairs(a.target.damage.parts)do other[k]=v.ap end
   local armored=hit(c,weapons.mentor);assert(math.abs(armored.healthDamage-2.25)<.001 and armored.armorDamage==0)
   local count=0;while p.ap>0 do local e=hit(c,weapons.laser);assert(e.healthDamage==0 and e.armorDamage>0);count=count+1 end
   local exposed=hit(c,weapons.mentor);assert(math.abs(exposed.healthDamage-(id=='head'and 22.5 or 15))<.001)
   for k,v in pairs(a.target.damage.parts)do if k~=id then assert(v.ap==other[k],'Cross-part armor loss')end end
   r.parts[id]={empShots=count,armoredDamage=armored.healthDamage,exposedDamage=exposed.healthDamage}
  end
  local c=contacts.head;unit.opacity=0;a:sample();assert(not a:probe({x=0,y=0},{x=10000,y=0}) and #a.target.regions==0)
  local e,why=a:apply(c,{id='hidden',contactId='contact',source='mentor',weapon=weapons.mentor});assert(not e and why=='TARGET_UNAVAILABLE')
  unit.x=unit.x+500;unit.opacity=1;a:sample();assert(not a.previous,'Invisible teleport swept old body');r.hiddenExcluded=true
  assert(record.enemyHP==a.target.damage.hp);a:close();assert(not a:available());r.cleanup=true
  overlay:removeFromParent();unit:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
