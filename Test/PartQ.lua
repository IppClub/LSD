package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local Q=require('Training.PartQ')
local function state(head,leg)return {distance=500,facing='yes',enemyAction='idle',attackReady='yes',part_head=head,part_front_leg=leg}end
local q=Q.new('ninilite');local a=state('armored','exposed');local b=state('exposed','armored')
assert(Q.key(a)~=Q.key(b))
assert(q:update({state=a,action='head',reward=1,duration=1,done=true,sealed=true}))
assert(q:update({state=b,action='front_leg',reward=1,duration=1,done=true,sealed=true}))
assert(q:choose(a,function()return true end,false)=='head')
assert(q:choose(b,function()return true end,false)=='front_leg')
assert(not q:choose(a,function(label)return label~='head'end,false))
local before=q.updates;assert(not q:update({state=a,action='laser',reward=100,duration=1,done=true,sealed=true}))
assert(not q:update({state=a,action='head',reward=100,duration=1,done=true,sealed=true,truncated=true}));assert(q.updates==before)
local snapshot=q:snapshot();snapshot.values[Q.key(a)].head=999;assert(q.values[Q.key(a)].head~=999)
assert(not require('Training.Model').validate(q:snapshot()))
assert(not pcall(Q.new,'fox'))
print('PASS separate part Q state/action scope, legal masking, truncation, snapshot isolation, no fox')
local saved=q:snapshot();assert(Q.validate(saved,'ninilite'));assert(not Q.validate(saved,'wuyun'))
assert(Q.predict(saved,a,function()return true end)=='head');assert(saved.updates==q.updates)
local restored=assert(Q.restore(saved));restored.values[Q.key(a)].head=88;assert(saved.values[Q.key(a)].head~=88)
saved.featureSchemaVersion=99;assert(not Q.validate(saved));saved.featureSchemaVersion=4
saved.values['bad']={head=1};assert(not Q.validate(saved));saved.values['bad']=nil
saved.values[Q.key(a)].laser=1;assert(not Q.validate(saved));saved.values[Q.key(a)].laser=nil
saved.values[Q.key(a)].head=math.huge;assert(not Q.validate(saved))
print('PASS part Q serialized validation, read-only prediction, restore isolation, unknown versions/keys/actions/values')
