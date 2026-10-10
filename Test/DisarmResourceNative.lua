-- Real enemy steal/fire lifecycle; fixture idle models isolate ownership accounting.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-resource-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/disarm-resource-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd'));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config');r.database=db
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Training.DisarmPractice').createAsync({ninilite=model('ninilite'),wuyun=model('wuyun')})
  assert(b.supplies.isVirtual and b.supplies.ledger.quote.total==293)
  local function wait(fn,seconds)local stop=D.App.runningTime+(seconds or 15);while not fn()do assert(D.App.runningTime<stop,'Disarm resource timeout');D.sleep(.02)end end
  assert(b:start())
  wait(function()return #b.disarmTrace.consumption>0 or b.phase~='playing'end,65)
  assert(b.phase=='playing','Enemy failed to fire stolen weapon before battle ended')
  local row=b.disarmTrace.consumption[1]
  assert(row.performer:match('^enemy:') and row.owner~='unknown','Stolen shot lost owner')
  assert(row.before.ammo[row.item]-row.after.ammo[row.item]==1,'Stolen shot did not spend original stock')
  local owner=row.owner=='mentor' and b.mentor or row.owner=='ninilite' and b.arena.student or b.wuyun.student
  assert(owner.data.weaponDisarmed)
  local before=b.supplies.emissions
  if owner==b.mentor then assert(not b:command('shoot'))else
   local arena=owner==b.arena.student and b.arena or b.wuyun;assert(not arena:request('laser','test'))
  end
  assert(b.supplies.emissions==before,'Rejected disarmed shot consumed ammo')
  assert(#b.disarmTrace.rejected>0)
  local rejected=b.disarmTrace.rejected[#b.disarmTrace.rejected];assert(rejected.reason=='WEAPON_DISARMED' and rejected.before.resources)
  assert(b:finish('aborted','资源归属专项结束'))
  wait(function()return b.disarmTrace.resourcesFinalizedAt end)
  assert(require('Training.ResourceEvidence').validate(b.disarmTrace.resources))
  assert(b.disarmTrace.virtualResult.cost==b.supplies.ledger.spent)
  assert(b.disarmTrace.schemaVersion==2 and b.disarmTrace.trainable==false)
  wait(function()return not owner.data.weaponDisarmed end)
  assert(not D.DB:exist('lsd.Game0SupplyWallet'),'Practice created a real wallet')
  r.trace=b.disarmTrace;r.virtualOnly=true;r.originalOwnerCharged=true;r.rejectedNoCost=true;r.weaponReturned=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
