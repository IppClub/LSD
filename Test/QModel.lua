package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local Q=require('Training.QModel')
local function state(armor)return {distance=400,facing='yes',enemyAction='idle',attackReady='yes',armorState=armor}end
local q=Q.new({characterId='ninilite',actions={'laser','bmove'},alpha=.5,gamma=.5})
local nextState=state('broken');local initial=state('intact')
assert(q:update({state=nextState,action='laser',reward=20,duration=1,done=true,sealed=true}))
-- Q(next,laser)=10. Bootstrap from NEXT state, with gamma^2=.25.
local ok,v=q:update({state=initial,action='laser',reward=2,duration=2,done=false,sealed=true,nextState=nextState,nextActions={'laser'}})
assert(ok and math.abs(v-2.25)<1e-9)
-- Masked successor actions exclude the good but unavailable laser.
local _,masked=q:update({state=initial,action='bmove',reward=2,duration=1,done=false,sealed=true,nextState=nextState,nextActions={'bmove'}});assert(masked==1)
local _,terminal=q:update({state=initial,action='laser',reward=0,duration=1,done=true,sealed=true});assert(terminal==1.125)
assert(q:choose(initial,function(a)return a=='bmove'end,false)=='bmove')
assert(not q:choose(initial,function()return true end,false,.5))
assert(q:choose(initial,function(a)return a=='bmove'end,true,1,function()return .1 end)=='bmove')
local count=q.updates;assert(not q:update({truncated=true}));assert(q.updates==count)
assert(not q:choose(state('unknown'),function()return true end,false))
local snap=q:snapshot();snap.values[Q.key(initial)].laser=999;assert(q.values[Q.key(initial)].laser==1.125)
-- Negative future returns must remain negative, not be clamped to zero.
local negative=Q.new({characterId='ninilite',actions={'laser'},alpha=1,gamma=1})
assert(negative:update({state=nextState,action='laser',reward=-4,duration=1,done=true,sealed=true}))
local _,n=negative:update({state=initial,action='laser',reward=-1,duration=1,done=false,sealed=true,nextState=nextState,nextActions={'laser'}});assert(n==-5)
print('PASS next-state bootstrap, duration discount, terminal zero bootstrap, legal mask, no implicit exploration, truncation, snapshot isolation, negative returns')
-- Failed updates leave state counts, existing values and update counts untouched.
assert(not q:update(nil))
for _,mask in ipairs({{}, {[2]='laser'}, {'laser','laser'}, {'melee'}, {laser=true}})do
 local updates=q.updates;local states=q.states
 assert(not q:update({state=initial,action='laser',reward=2,duration=1,done=false,sealed=true,nextState=nextState,nextActions=mask}))
 assert(q.updates==updates and q.states==states)
end
local overflow=Q.new({characterId='ninilite',actions={'laser'},alpha=1,gamma=1})
assert(overflow:update({state=nextState,action='laser',reward=1e308,duration=1,done=true,sealed=true}))
local accepted,reason=overflow:update({state=initial,action='laser',reward=1e308,duration=1,done=false,sealed=true,nextState=nextState,nextActions={'laser'}})
assert(not accepted and reason=='VALUE_OVERFLOW' and overflow.states==1 and overflow.updates==1 and overflow.values[Q.key(initial)]==nil)
print('PASS malformed successor masks and overflow reject without mutation')
q.rewardPolicy='unarmored-v1'
local serialized=q:snapshot();assert(Q.validate(serialized,'ninilite'))
local restored=assert(Q.restore(serialized));assert(restored:choose(initial,function()return true end,false)=='laser')
restored.values[Q.key(initial)].laser=500;assert(serialized.values[Q.key(initial)].laser==1.125)
local Model=require('Training.Model');assert(Model.validate(serialized,'ninilite'))
assert(Model.predict(serialized,initial,function(a)return a=='bmove'end)=='bmove')
local function clone(t)local c={};for k,v in pairs(t)do c[k]=type(v)=='table' and clone(v)or v end;return c end
for _,mutate in ipairs({
 function(m)m.rewardPolicy='future-v2'end,
 function(m)m.discountTimeUnit='frames'end,
 function(m)m.algorithm='future'end,
 function(m)m.values['unknown|garbage']={laser=1}end,
 function(m)m.values[Q.key(initial)].laser=0/0 end,
 function(m)m.actions={'laser','laser'}end,
 function(m)m.values[Q.key(initial)].teleport=100 end,
 function(m)m.updates=0 end,
 function(m)m.characterId='fox'end,
})do local bad=clone(serialized);mutate(bad);assert(not Model.validate(bad));assert(not Model.predict(bad,initial))end
print('PASS serialized Q policy validation, dispatch, copy isolation, unknown versions, invalid keys/actions/values, no fox training')
