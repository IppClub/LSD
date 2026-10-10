local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/combat-features-native-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local Recorder=require('Training.Recorder');local Model=require('Training.Model')
  local rec=Recorder.new({characterId='ninilite',actions={'laser','bmove'}})
  for i=1,12 do for _,armor in ipairs({'intact','broken'})do
   assert(rec:record({distance=400,facing='yes',enemyAction='idle',attackReady='yes',enemyKind='taotie',armorState=armor,observedPart='head',healthBand='healthy',energyReady='yes'},armor=='intact' and 'laser' or 'bmove',true))
  end end
  local model,why=Model.buildAsync(rec);assert(model,why);assert(model.featureSchemaVersion==3 and Model.validate(model))
  local split=false;for _,rule in ipairs(model.rules)do for _,c in ipairs(rule.conditions)do if c.name=='armorState'then split=true end end end
  assert(split,'Tree ignored only differentiating feature')
  local state={distance=500,facing='yes',enemyAction='idle',attackReady='yes',armorState='intact'}
  assert(Model.predict(model,state)=='laser');state.armorState='broken';assert(Model.predict(model,state)=='bmove')
  state.armorState=nil;assert(not Model.predict(model,state),'Unknown armor was invented')
  for _,v in ipairs({1,2})do
   local old={schemaVersion=1,featureSchemaVersion=v,actionSetVersion=1,characterId='ninilite',sampleCount=6,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}
   assert(Model.validate(old) and Model.predict(old,state)=='laser')
  end
  model.featureSchemaVersion=2;assert(not Model.validate(model));model.featureSchemaVersion=3
  assert(not rec:record({distance=1,facing='yes',enemyAction='idle',attackReady='yes',armorState='secret'},'laser',true))
  local a=require('Training.Arena').createAsync({enemySpeed=0})
  local observed=a:snapshot();assert(observed.enemyKind=='taotie' and observed.armorState=='unarmored' and observed.energyReady=='unlimited')
  a.partObservation=function()return nil,'unknown'end;assert(a:snapshot().armorState=='unknown' and a:snapshot().observedPart=='unknown')
  r.accuracy=model.trainingAccuracy;r.samples=#rec.samples;r.rules=model.rules;r.schema=3;r.legacySupported=true;r.nativeArena=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
