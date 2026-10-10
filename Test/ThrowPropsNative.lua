local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING'};local out=root..'/Test/throw-props-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline);D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  b.mentorHP=10000;wait(function()return b.mentor.onSurface end)
  local e=b.enemies[1];local item=b.props.items[1];local spec=B.attackSpecs.dashanxiao[1]
  assert(b:enemyStrike(e,spec));assert(item.state=='reserved');assert(not b.props:reserve(e.unit))
  D.sleep(.6);assert(item.state=='carried');e.attackSequence:cancel('QA_INTERRUPT');wait(function()return not e.busy end);e.nextAttack=math.huge
  assert(item.state=='ready' and not item.owner and math.abs(item.node.x-item.home.x)<.01);r.returned=true
  local hp=b.mentorHP;assert(b:enemyStrike(e,spec));local strike=e.strikes[#e.strikes]
  wait(function()return strike.propReleased end);assert(item.state=='thrown' and not item.node.parent)
  wait(function()return not e.busy end);e.nextAttack=math.huge
  wait(function()return item.state=='spent'end)
  assert(strike.hits==1 and hp-b.mentorHP==14);r.productionHit=true
  e.unit.position=D.Vec2(10400,b.world.offset+155);D.sleep(.1)
  local accepted,why=b:enemyStrike(e,spec);assert(not accepted and why=='NO_PROP');r.noPropRejected=true
  -- Real unit contacts with a single thrown body; each target may be reported once.
  e.unit.position=D.Vec2(8500,b.world.offset+155);e.unit.faceRight=true
  local t1=b.arena.spawnUnit('charM',1,8850,{});local t2=b.arena.spawnUnit('charM',1,8950,{})
  D.sleep(.2);local prop=assert(b.props:reserve(e.unit));local origin=e.unit.position+D.Vec2(80,120)
  b.props:carry(prop,origin);local hits={}
  local bullet=assert(b.props:throw(prop,origin,D.Vec2(8900,t1.y),function(target)hits[target]=(hits[target]or 0)+1 end))
  wait(function()return not bullet.parent end);assert(hits[t1]==1 and hits[t2]==1);r.multiTarget=true
  e.unit.position=D.Vec2(9450,b.world.offset+155);D.sleep(.1)
  local last=assert(b.props:reserve(e.unit));b.props:carry(last,e.unit.position+D.Vec2(80,120))
  local lateHits=0;local flying=assert(b.props:throw(last,last.node.position,D.Vec2(9900,t1.y),function()lateHits=lateHits+1 end))
  assert(flying.parent and next(b.props.flying));b:finish('aborted','QA');assert(not flying.parent,'Active bullet retained');assert(b.props.closed,'Props not closed: '..b.phase);assert(not next(b.props.flying),'Flying entries remain');for _,p in ipairs(b.props.items)do assert(p.state=='closed','Item state: '..p.id..' '..p.state);assert(not p.owner,'Owner retained');assert(not p.node.parent,'Sprite retained')end;D.sleep(.2);assert(lateHits==0);for _,p in ipairs(b.props.items)do assert(p.state=='closed','Delayed cleanup changed closed state')end;b.props:close();r.cleaned=true;r.inFlightExit=true;r.delayedCleanupSafe=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
