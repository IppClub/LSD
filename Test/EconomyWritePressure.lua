-- Storage pressure only: four durable firing decisions per rendered frame.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/economy-write-pressure-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local path=D.Content.writablePath..'/economy-pressure-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and not D.Content:exist(path));assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0)
  local S=require('Economy.Store');assert(S.open());assert(D.DB:exec('UPDATE lsd.Game0SupplyWallet SET available=3000 WHERE id=1')>=0)
  local lines={{actor='mentor',item='kinetic',quantity=200},{actor='ninilite',item='emp',quantity=200},{actor='wuyun',item='emp',quantity=200},{actor='wuyun',item='blade',quantity=200}}
  assert(S.beginAsync('pressure',lines,0));local session=assert(require('Economy.CombatSession').open('pressure'))
  local times,blocks,frames={},{},{};local active=false
  local monitor=D.Node();monitor:addTo(D.Director.entry);monitor:schedule(function(dt)if active then frames[#frames+1]=dt*1000 end;return false end)
  D.sleep(.5);active=true
  for index=1,200 do
   local start=D.App.runningTime
   for _,line in ipairs(lines)do local t=D.App.runningTime;assert(session:emit(line.actor,line.item,1,line.actor));times[#times+1]=(D.App.runningTime-t)*1000 end
   blocks[#blocks+1]=(D.App.runningTime-start)*1000;D.sleep(0)
  end
  D.sleep(0);active=false;monitor:removeFromParent()
  local function stats(values)
   local sum,slow=0,0;for _,v in ipairs(values)do sum=sum+v;if v>33.333 then slow=slow+1 end end
   table.sort(values);return {count=#values,meanMs=sum/#values,p95Ms=values[math.ceil(#values*.95)],maxMs=values[#values],over33ms=slow}
  end
  r.commits=stats(times);r.fourShotBlocks=stats(blocks);r.frames=stats(frames)
  local bill=assert(S.settleAsync('pressure','aborted'));assert(bill.cost==2209 and bill.refund==0 and S.wallet().available==791)
  r.events=session.emissions;r.cost=bill.cost;r.database=path
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
