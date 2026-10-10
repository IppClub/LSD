-- Real original final worlds, controlled ready state; no formal combat/FPS claim.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/final-support-display-result.json';local r={status='RUNNING',controlledFixture=true,osInput=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local meta,oldIndex
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(root..'/Test/fresh-rescue-reactions-current-result.json')),32);assert(prior.status=='PASS')
  local db=D.Path(D.Content.writablePath,'final-support-display.db');assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=db;r.parentDatabase=prior.database
  local tracked=setmetatable({},{__mode='k'})
  local function frames(n)local left=n;local tick=D.Node();tick:addTo(D.Director.ui);tick:schedule(function()left=left-1;return left<=0 end);while left>0 do D.sleep(.005)end;tick:removeFromParent()end
  local model={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}
  for _,variant in ipairs({'before','after'})do
   local module=variant=='before'and assert(load(assert(D.Content:load('/private/tmp/lsd-FinalBattle-before-support-cache-20261009.lua')),'@before-FinalBattle'))()or require('Final.Battle')
   local b=module.createAsync({ninilite=model},'mobility');assert(b.phase=='ready');frames(10)
   local count={text=0,clear=0,segments=0};tracked[b.machineLabel]=count
   if not meta then meta=getmetatable(b.machineLabel);oldIndex=assert(meta.__newindex);meta.__newindex=function(o,k,v)local c=tracked[o];if c and k=='text'then c.text=c.text+1 end;return oldIndex(o,k,v)end end
   local ring=b.ring;local segments={}
   b.ring=setmetatable({}, {__index=function(_,key)
    if key=='clear'then return function()count.clear=count.clear+1;segments={};ring:clear()end end
    if key=='drawSegment'then return function(_,a,z,width,color)count.segments=count.segments+1;segments[#segments+1]={a=a,z=z,width=width,color=color:toARGB()};ring:drawSegment(a,z,width,color)end end
    return ring[key]
   end,__newindex=function(_,k,v)ring[k]=v end})
   -- Warm both versions to capture their authored actual native geometry.
   b.support.active=false;frames(3);b.support.active=true;frames(3)
   count.text=0;count.clear=0;count.segments=0;frames(120)
   local row={variant=variant,frames=120,steady={text=count.text,clear=count.clear,segments=count.segments},states={}};r.cases[#r.cases+1]=row;save()
   if variant=='before'then assert(count.text>=120 and count.clear==count.text and count.segments==count.text*3)else assert(count.text==0 and count.clear==0 and count.segments==0)end
   for _,state in ipairs({{x=800,hp=99.2,active=true},{x=1200,hp=99.1,active=true},{x=1450,hp=98.8,active=false},{x=2090,hp=0,active=false},{x=1730,hp=100,active=true}})do
    count.text=0;count.clear=0;count.segments=0;b.objective.x=state.x;b.support.machineHP=state.hp;b.support.active=state.active;frames(5)
    assert(#segments==3 and b.machineLabel.text=='记录载体  '..math.ceil(state.hp)..' / 100')
    assert(math.abs(b.machineLabel.x-b.objective.x)<.01 and math.abs(b.machineLabel.y-b.world.offset-350)<.01)
    local expected={{-360,8,360,8,4},{-360,8,-360,80,3},{360,8,360,80,3}}
    local points={};for i,s in ipairs(segments)do
     local a=ring:convertToWorldSpace(s.a);local z=ring:convertToWorldSpace(s.z);local e=expected[i]
     local x=b.world:convertToWorldSpace(D.Vec2(b.objective.x+e[1],b.world.offset+e[2]));local y=b.world:convertToWorldSpace(D.Vec2(b.objective.x+e[3],b.world.offset+e[4]))
     assert(math.abs(a.x-x.x)<.01 and math.abs(a.y-x.y)<.01 and math.abs(z.x-y.x)<.01 and math.abs(z.y-y.y)<.01,'Range geometry shifted')
     assert(s.width==e[5]and s.color==(state.active and 0x9952dfcf or 0x99ec936e),'Authored color/width changed')
     points[#points+1]={ax=a.x,ay=a.y,zx=z.x,zy=z.y,width=s.width,color=s.color}
    end
    row.states[#row.states+1]={x=b.objective.x,hp=state.hp,active=state.active,text=b.machineLabel.text,textWrites=count.text,clear=count.clear,segments=count.segments,worldPoints=points};save()
   end
   if variant=='after'then
    assert(row.states[1].textWrites==0 and row.states[2].textWrites==0 and row.states[3].textWrites==1 and row.states[4].textWrites==1 and row.states[5].textWrites==1)
    assert(row.states[1].clear==0 and row.states[2].clear==0 and row.states[3].clear==1 and row.states[4].clear==0 and row.states[5].clear==1)
   end
   tracked[b.machineLabel]=nil;b.ring=ring;b.world:removeFromParent();D.Director.ui3D:removeAllChildren();frames(5)
  end
 end,debug.traceback)
 if meta and oldIndex then meta.__newindex=oldIndex end
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
