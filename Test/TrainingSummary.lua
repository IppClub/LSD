package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local S=require('Training.Summary');local Q=require('Training.QModel')
local old={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId='ninilite',sampleCount=7,trainingAccuracy=.75,actions={'laser'},rules={{conditions={},action='laser'}}}
local q=Q.new({characterId='ninilite'});q.rewardPolicy='unarmored-v1'
assert(q:update({state={distance=400,facing='yes',enemyAction='idle',attackReady='yes'},action='laser',reward=1,duration=1,sealed=true,done=true}))
q=q:snapshot()
assert(S.short(old)=='7 条示范' and S.detail(old):find('75%%'))
assert(S.short(q)=='自主训练 1 步' and not S.detail(q):find('准确率',1,true))
assert(S.matches({samples=7},old))
assert(not S.matches({},q),'nil samples must not match a Q model')
assert(not S.matches({samples=1},q),'Q steps are not demonstrations')
assert(S.matches({training=S.record(q)},q))
assert(not S.matches({training=S.record(old)},q))
local evidence=S.record(q);evidence.rewardPolicy='future';assert(not S.matches({training=evidence},q))
evidence=S.record(q);evidence.characterId='wuyun';assert(not S.matches({training=evidence},q))
local forged={sampleCount=7};assert(not S.matches({samples=7},forged))
assert(S.short(forged)=='训练记录不可用')
print('PASS algorithm-specific display, legacy report compatibility, Q report identity, no nil-equality acceptance, malformed models')
