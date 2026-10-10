local V=dofile('Script/Enemy/BigYingzhaoFlightEvidence.lua')
local function trace()
 return {flightVersion=1,steps={{actor='mentor',action='shoot',started=1,emitted=1}},hits={{attackId='yingzhao-shot-1',source='mentor',step=1,target='big-yingzhao',part='head',at=2}},flights={{id='yingzhao-shot-1',actor='mentor',step=1,started=1.1,ended=2,origin={x=0,y=0},position={x=100,y=0},velocity={x=2400,y=0},reason='contact',target='big-yingzhao',part='head'}}}
end
assert(V.validate(trace()));assert(V.validate({}))
local t=trace();t.flights[1].reason='terrain';assert(not V.validate(t))
t=trace();t.flights[1].part='torso';assert(not V.validate(t))
t=trace();t.flights[1].ended=1.5;assert(not V.validate(t))
t=trace();t.flights={};assert(not V.validate(t))
t=trace();t.flights[1].velocity.x=0/0;assert(not V.validate(t))
t=trace();t.steps[1].actor='wuyun';assert(not V.validate(t))
t=trace();t.hits={};t.flights[1].target=nil;t.flights[1].part=nil;t.flights[1].reason='removed';assert(V.validate(t))
print('BigYingzhaoFlightEvidence PASS compatibility contactIdentity hitTime emittedCompleteness finiteGeometry actorOwnership removal')

local fire={flightVersion=1,steps={{actor='ninilite',action='fire',started=1,emitted=1,skill={releaseAt=1.1}}},hits={},flights={}}
for i=1,3 do fire.flights[i]={id='yingzhao-shot-'..i,kind='fire',actor='ninilite',step=1,started=1.1,ended=2,origin={x=i,y=0},position={x=i,y=100},velocity={x=260,y=-900},reason='removed'}end
assert(V.validate(fire));fire.flights[3]=nil;assert(not V.validate(fire))
print('BigYingzhaoFlightEvidence PASS authoredTripleFeather=true missingFeatherRejected=true')
