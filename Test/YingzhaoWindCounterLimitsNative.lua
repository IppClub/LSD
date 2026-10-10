-- Controlled counterexamples: actual prior fire damage, or real terrain cover.
-- No reaction timer edits, HP edits, skill cooldown resets or training imports.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-wind-counter-limits-result.json';local r={status='RUNNING',cases={},notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Counter limits timeout');D.sleep(.02)end end
  for _,direction in ipairs({1,-1})do for _,mode in ipairs({'fresh','reaction-cooldown','covered'})do
   local supplies=assert(require('Economy.CombatSession').virtual('wind-limits:'..D.App.runningTime,{{actor='wuyun',item='emp',quantity=2}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true})
   local boss=b.enemies[1];local g=boss.guard;local update=g.update
   g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review'
   local edge=direction==1 and b.minX or b.maxX;local bx=edge+direction*700
   b.wuyun.student.position=D.Vec2(edge,b.world.offset+155);boss.enemy.position=D.Vec2(bx,b.world.offset+255)
   b.mentor.x=bx-direction*240;b.mentor.faceRight=direction==1;b.arena.student.x=bx+direction*600
   D.sleep(.4);wait(function()return b.wuyun.student.onSurface and boss.enemy.onSurface end)
   local row={direction=direction,mode=mode};r.cases[#r.cases+1]=row
   if mode=='reaction-cooldown'then
    assert(b.magic:request('fire',{source='qa-prior-damage',noQueue=true,faceRight=direction==1}))
    wait(function()return not b.magic:busy('fire')and not b.bossCombat:pendingActor('ninilite')and not g.reacting end)
    assert(boss.enemyHP<1000 and #g.hits>0 and g.hits[1].reacted,'Prior actual fire failed to trigger reaction')
    assert(g.nextReaction>D.App.runningTime+.6,'Reaction cooldown fixture expired')
    row.priorDamage=1000-boss.enemyHP;row.nextReaction=g.nextReaction
   end
   b.mentor.x=bx+direction*500
   local wall
   if mode=='covered'then
    local def=D.BodyDef();def.type='Static';def:attachPolygon(30,1600)
    wall=D.Body(def,b.world,D.Vec2(edge+direction*350,b.world.offset+800));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world);D.sleep(.05)
   end
   row.hpBefore=b.wuyun.studentHP;row.bossBefore=boss.enemyHP
   assert(g:attack('wave',b.wuyun.student));local strike=g.strike
   D.sleep(.1);assert(b.magic:request('wind',{source='qa-counter',noQueue=true,faceRight=direction==1}))
   wait(function()return not g.busy and #g.waves==0 and not b.magic:busy('wind')end)
   row.damage=row.hpBefore-b.wuyun.studentHP;row.bossDamage=row.bossBefore-boss.enemyHP;row.windHits=b.magic.windHits;row.strike=strike;row.reactions=g.hits;row.magic=b.magic.logs
   if mode=='fresh'then assert(strike.cancelled=='HIT'and not strike.wave and row.windHits==1 and row.damage==0)
   else
    assert(not strike.cancelled and strike.completed-strike.started>=3.95 and strike.wave and strike.wave.ended,'Wave must fully release and finish')
    if mode=='reaction-cooldown'then
     assert(row.windHits==1 and math.abs(row.bossDamage-1.8)<.001 and row.damage==16)
     assert(g.hits[#g.hits].reacted==false,'Cooldown hit unexpectedly cancelled Boss')
    else assert(row.windHits==0 and row.bossDamage==0 and row.damage==0 and strike.wave.reason=='WALL')end
   end
   assert(b:finish('aborted','Counter limits fixture'));wait(function()return b.phase=='aborted'end);save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
