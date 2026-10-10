-- Native visual/geometry regression; only attaches a disposable QA database.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/enemy-appearance-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source='/private/tmp/lsd-shan-1791135078/save/lsd-ruins-route-qa-1791013294.db'
  local dest=D.Content.writablePath..'/appearance-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  D.App.winSize=D.Size(1000,700)
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}})
  local b=c.battle;local boss=b.roots[3].enemy
  assert(boss.playable.scaleX==1 and boss.playable.scaleY==1)
  assert(b.roots[1].enemy.playable.look=='white' and b.roots[2].enemy.playable.look=='normal')
  r.view={width=D.View.size.width,height=D.View.size.height,zoom=b.arena.world.camera.zoom};r.scale={flower=boss.playable.scaleX};r.looks=D.Spine:getLooks('xiaohuayao')
  D.sleep(1)
  local evidence=root..'/Docs/evidence/2026-10-05/'
  D.App:saveScreenshot(evidence..'factory-authored-size.tga');D.sleep(.2)
  -- Verify world-space regions double about the authored origin without stale poses.
  local sample=require('Combat.SpineRegions').sample
  local manifest=D.json.decode(D.Content:load(root..'/Docs/artwork/flower-hitboxes/vertex-probes.json'))
  boss.playable:stop()
  -- Compare each model's own local geometry after only changing its scale.
  local full=sample(boss.playable,manifest,b.arena.world)
  boss.playable.scaleX=.5;boss.playable.scaleY=.5
  local small=sample(boss.playable,manifest,b.arena.world)
  local origin=b.arena.world:convertToNodeSpace(boss.playable:convertToWorldSpace(D.Vec2.zero))
  local maxError=0;local count=0
  for i,region in ipairs(full)do for j,v in ipairs(region.vertices)do local h=small[i].vertices[j];maxError=math.max(maxError,math.abs((v.x-origin.x)-2*(h.x-origin.x)),math.abs((v.y-origin.y)-2*(h.y-origin.y)));count=count+1 end end
  boss.playable.scaleX=1;boss.playable.scaleY=1;require('CombatAnimation').rest(boss)
  assert(maxError<.02);r.geometry={vertices=count,maxScaleError=maxError}
  -- Both color skins retain their dress while moving and attacking.
  for _,name in ipairs({'idle','move','leech','pull'})do
   for i=1,2 do assert(require('CombatAnimation').play(b.roots[i].enemy,name,name=='idle' or name=='move')>0)end
   D.sleep(name=='leech' and 1.5 or .7)
   D.App:saveScreenshot(evidence..'flower-two-looks-'..name..'.tga');D.sleep(.15)
  end
  local flower=b.roots[3].enemyCombat
  local strike={};flower:seed(strike)
  assert(strike.spawned==3)
  r.summons={}
  for i,child in ipairs(flower.children)do
   local look=child.enemy.playable.look;assert(look==(i%2==1 and 'white' or 'normal'))
   child.enemyHP=90;child.enemyCombat:updateBud(D.App.runningTime)
   child.enemyCombat:updateBud(D.App.runningTime+5.1)
   D.sleep(child.enemyCombat.budDuration+.1)
   child.enemyCombat:updateBud(D.App.runningTime+6)
   assert(child.enemy.playable.visible and child.enemy.playable.look==look)
   r.summons[i]=look
  end
  D.App.winSize=D.Size(683,384);D.sleep(1)
  D.App:saveScreenshot(evidence..'factory-authored-size-wide.tga');D.sleep(.2)
  c.withdraw:emit('Tapped');D.sleep(.5)
  -- Old half-size adoption is preserved for rollback, never silently deployed.
  local store=require('Training.FlowerAdoptionStore')
  local saved,why=store.load('ninilite');assert(not saved and why=='NOT_ADOPTED')
  assert(D.DB:exec("ATTACH DATABASE '/private/tmp/lsd-shan-1791135078/save/flower-adoption-store-1791155684.db' AS appearance_legacy")>=0)
  assert(D.DB:exec("INSERT INTO lsd.Game0FlowerAdoptions SELECT * FROM appearance_legacy.Game0FlowerAdoptions WHERE id=1 AND learner='ninilite'")>=0)
  assert(D.DB:exec('DETACH DATABASE appearance_legacy')>=0)
  assert(D.DB:exec("UPDATE lsd.Game0FlowerAdoptionState SET current=1 WHERE learner='ninilite'")>=0)
  saved,why=store.load('ninilite');assert(not saved and why=='ENCOUNTER_CHANGED')
  r.legacyDeployment=why
  local rolled,status=store.rollbackAsync('ninilite');assert(rolled and status=='RESTORED_BASIC');r.legacyRollback=status

  local a=require('Training.Arena').createAsync({scene='VRTraining',enemyAsset='dataotie',manualUpdate=true,actionPrefix='appearanceBoss_'})
  assert(a.enemy.playable.scaleX==1 and a.enemy.playable.scaleY==1);r.scale.taotie=a.enemy.playable.scaleX
  a.world.camera.zoom=.65;a.world.camera.position=D.Vec2(950,350);D.sleep(.5)
  D.App:saveScreenshot(evidence..'taotie-authored-size.tga');D.sleep(.2)
  a.closed=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=ok and nil or err;D.Content:save(out,D.json.encode(r,false,true));print('APPEARANCE '..r.status..' '..(err or ''));D.App:shutdown()
end)
