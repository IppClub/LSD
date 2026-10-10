local _,capture=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-lane-stability-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-hud-performance-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync())
  local support=require('Ground.LifeSupport').new(45,'defence');support.hp={100,100,100}
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models=saved.source.baseModels},support);local b=c.battle
  local K=require('Combat.Displacement');D.sleep(.2)
  for i,u in ipairs({b.mentor,b.arena.student,b.wuyun.student})do
   local lane=i-2;u.order=lane;b.arena.world:moveChild(u,lane);D.sleep(.05)
   local layer=u.parent;local offset=b.arena.world:getLayerOffset(lane)
   local x=u.x;local y=u.y
   assert(K.apply({unit=u,alive=function()return true end},-900,650,{kind='QA-lane-hit'}))
   local start=D.App.runningTime;local moved=false;local lifted=false
   repeat
    D.sleep(.02)
    assert(u.order==lane and u.parent==layer,'Hit reaction changed visual lane')
    local current=b.arena.world:getLayerOffset(lane)
    assert(current.x==offset.x and current.y==offset.y,'Path offset changed')
    moved=moved or math.abs(u.x-x)>20;lifted=lifted or u.y-y>20
    assert(D.App.runningTime-start<9,'Recovery stuck')
   until not K.blocked(u)
   assert(moved and lifted,'Physical knockback/lift lost')
   assert(u.order==lane and u.parent==layer,'Recovery changed visual lane')
   r.cases[#r.cases+1]={lane=lane,offsetY=offset.y,moved=moved,lifted=lifted}
   K.clear(u);assert(u.order==lane and u.parent==layer,'Clear changed lane')
  end
  b:finish('aborted','Lane stability regression complete')

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
