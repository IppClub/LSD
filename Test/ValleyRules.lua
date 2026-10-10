package.path='Script/?.lua;'..package.path
local R=require('Story.ValleyRules')
for _,id in ipairs(R.ids) do local s=R.initial(id);assert(R.validate(id,s) and not R.complete(id,s));assert(R.monotonic(id,s,s)) end
local f=R.initial('fish');f.marks={true,true,true};assert(R.complete('fish',f) and not R.monotonic('fish',f,R.initial('fish')))
local farm={plots={3,3,3},watered={1,2,3}};assert(R.complete('farm',farm));assert(not R.validate('farm',{plots={3,3,3},watered={0,2,3}}))
assert(not R.validate('language',{correct=4}) and not R.validate('language',{correct=0/0}))
assert(R.complete('language',{correct=3}) and not R.monotonic('language',{correct=3},{correct=2}))
assert(R.lessons[1].correct==1 and R.lessons[2].correct==2 and R.lessons[3].correct==3)
print('LSD_VALLEY_RULES_PASS fiveStates=true completion=true malformedRejected=true monotonic=true originalLanguageMeanings=true')
