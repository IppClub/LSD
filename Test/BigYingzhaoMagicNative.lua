local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-magic-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/big-yingzhao-magic-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config');r.database=db
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')});assert(b:start());local boss=b.enemies[1];boss.guard.nextAttack=math.huge
  local function wait(fn)local stop=D.App.runningTime+9;while not fn()do assert(D.App.runningTime<stop,'Magic timeout');D.sleep(.01)end end
  D.sleep(.5)
  for _,case in ipairs({'wind','hidden-wind','covered-wind','fire','hidden-fire','enhanced-fire'})do
   boss.guard.nextAttack=math.huge;boss.guard.nextReaction=math.huge
   b.mentor.x=2250;b.mentor.faceRight=true;b.wuyun.student.x=2100;b.arena.student.x=1800
   boss.enemy.x=2500;boss.enemy.opacity=case:find('hidden')and 0 or 1
   b.magic.ready.fire=0;b.magic.ready.wind=0;D.sleep(.1)
   local wall
   if case=='covered-wind'then local def=D.BodyDef();def.type='Static';def:attachPolygon(30,1600);wall=D.Body(def,b.world,D.Vec2(2200,b.world.offset+800));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world);D.sleep(.05)end
   if case=='enhanced-fire'then b.magic.gust={x=1900,y=b.world.offset+350,direction=1,untilTime=D.App.runningTime+3}end
   local hp=boss.enemyHP;local count=#b.bossTrace.hits;local skill=case:find('wind')and'wind'or'fire'
   assert(b:command(skill));wait(function()return not b.magic:busy(skill)and next(b.bossCombat.shots)==nil end)
   local n=#b.bossTrace.hits-count;local delta=hp-boss.enemyHP
   if case:find('hidden')or case=='covered-wind'then assert(n==0 and delta==0,'Invisible/covered target damaged')
   elseif skill=='wind'then assert(n==1 and math.abs(delta-1.8)<.001,'Wind bypassed armor or hit repeatedly')
   else assert(n>0 and n<=3 and delta>0,'Feathers missed fixture');for i=count+1,#b.bossTrace.hits do local e=b.bossTrace.hits[i];assert(e.weapon==(case=='enhanced-fire'and'wind-fire'or'fire'));assert(math.abs(e.healthDamage-(case=='enhanced-fire'and 2.7 or 1.8))<.001,'Fire ignored armor')end end
   if wall then wall:removeFromParent()end
   assert(boss.enemyHP==b.bossCombat.armor.target.damage.hp,'Split HP authorities')
   r.cases[#r.cases+1]={case=case,hits=n,damage=delta};save()
  end
  D.sleep(.1);assert(#b.magic.arrows==0,'Expired feathers retained');r.feathersReleased=true
  assert(b.magic.synergyHits>0);r.synergyHits=b.magic.synergyHits
  assert(b:finish('aborted','QA complete'));wait(function()return b.settled end);r.cleanup=b.bossCombat.closed
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
