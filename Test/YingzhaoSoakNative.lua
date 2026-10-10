-- Frozen natural Boss pairs; normal GC between rounds, no adoption or formal save access.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-soak-result.json'
local r={status='RUNNING',rounds={},memory={}};local weak=setmetatable({},{__mode='v'})
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local origin='/private/tmp/lsd-combat-qa-3fx1bo45/save/yingzhao-mixed-natural-1791274631.db'
  local db=D.Content.writablePath..'/yingzhao-soak-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(origin,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  require('Data.Config'):loadAsync();local models=assert(require('Training.FlowerPractice').models())
  local frozen=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-close-aim-natural-20261006/result.json'),32);assert(frozen.status=='PASS')
  local economy=require('Economy.Store');assert(economy.open());local wallet=economy.wallet().available
  local function adopted()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun')},false,true)end
  local before=adopted()
  for pair=1,3 do
   local sample
   local report=require('Training.YingzhaoComparison').runAsync(models,frozen.candidate,frozen.report.loadout,function(round)
    local keys={};for k in pairs(sample.bins)do keys[#keys+1]=k end;table.sort(keys);local n,p95,p99=0
    for _,k in ipairs(keys)do n=n+sample.bins[k];if not p95 and n>=sample.count*.95 then p95=k/10000 end;if not p99 and n>=sample.count*.99 then p99=k/10000 end end
    sample.bins=nil;sample.p95=p95;sample.p99=p99;sample.mean=sample.sum/sample.count;sample.sum=nil
    r.rounds[#r.rounds+1]={pair=pair,mode=round.mode,status=round.status,seconds=round.seconds,cost=round.cost,bossHP=round.bossHP,hp=round.hp,hits=#round.trace.hits,performance=sample};save()
   end,{baseline=frozen.old,companion=frozen.companion,onBattle=function(b)
    weak[#r.rounds+1]=b;sample={count=0,sum=0,max=0,over33ms=0,bins={},slow={}}
    local node=D.Node();node:addTo(b.world)
    node:schedule(function(dt)
     if b.phase~='playing'then return false end
     sample.count=sample.count+1;sample.sum=sample.sum+dt;sample.max=math.max(sample.max,dt)
     local bin=math.min(20000,math.ceil(dt*10000));sample.bins[bin]=(sample.bins[bin]or 0)+1
     if dt>1/30 then sample.over33ms=sample.over33ms+1;if #sample.slow<30 then sample.slow[#sample.slow+1]={dt=dt,action=b.enemies[1].guard.currentSkill,at=D.App.runningTime}end end
     return false
    end)
   end})
   assert(require('Training.YingzhaoComparisonStore').validate(report))
   report=nil;D.sleep(.5)
   local retained=0;for _ in pairs(weak)do retained=retained+1 end
   r.memory[#r.memory+1]={pair=pair,at=D.App.runningTime,retained=retained,luaKB=collectgarbage('count'),objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount};save()
  end
  assert(wallet==economy.wallet().available and before==adopted());r.walletAndAdoptionUnchanged=true
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();D.sleep(.5)
  collectgarbage('collect');D.sleep(.2);collectgarbage('collect')
  r.finalRetained=0;for _ in pairs(weak)do r.finalRetained=r.finalRetained+1 end
  assert(r.finalRetained==0,'Closed Boss battles retained after final cleanup')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
