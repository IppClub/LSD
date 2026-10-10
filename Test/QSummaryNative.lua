local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/q-summary-native-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,why=xpcall(function()
  local Q=require('Training.QModel');local q=Q.new({characterId='ninilite'});q.rewardPolicy='unarmored-v1'
  assert(q:update({state={distance=400,facing='yes',enemyAction='idle',attackReady='yes'},action='laser',reward=1,duration=1,sealed=true,done=true}))
  q=q:snapshot()
  local old={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=7,trainingAccuracy=.75,actions={'laser'},rules={{conditions={},action='laser'}}}
  local fixture={missions={},roster={},finalModel=q,currentModel=old,currentRevision=2,auxiliaryVariant='cargo',evacuation={learner={modelActions=12,hits=3,hp=75},mentorHits=4,fireHits=2,coverBlocks=1,seconds=42,auxiliary={hp=90}}}
  local pages=require('Ending.View').pages(fixture)
  local body=pages[2].body
  assert(body:find('自主训练 1 步',1,true) and body:find('7 条示范',1,true) and not body:find('nil',1,true))
  fixture.finalModel=old;fixture.currentModel=q
  assert(require('Ending.View').pages(fixture)[2].body:find('自主训练 1 步',1,true))
  local label=assert(D.Label('SourceHanSansCN-Regular',27));label.textWidth=1100;label.text=body;label.position=D.Vec2(D.App.bufferSize.width/2,D.App.bufferSize.height/2);label:addTo(D.Director.ui3D)
  D.sleep(.1);assert(label.width>0 and label.height>0)
  -- Production proof functions must reject missing Q identity before accepting
  -- later encounter-specific claims. This fixture is not a completed mission.
  local p={encounter='twins-evacuation',status='won',seconds=10,mentorHP=100,learner={hp=100,modelActions=2}}
  local accepted,reason=require('Rescue.Proof').validate(p,q);assert(not accepted and reason=='RESCUE_PARTY_REQUIRED')
  p.encounter='last-promise';p.mentorX=2000;p.learner.x=2000
  accepted,reason=require('Final.Proof').validate(p,q,'cargo');assert(not accepted and reason=='EVACUATION_PARTY_REQUIRED')
  r.endingBody=body;r.pages=#pages;r.nativeLabel=true;r.invalidProofRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and why or nil;save()
end)
