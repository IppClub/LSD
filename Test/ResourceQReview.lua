package.path='Script/?.lua;'..package.path
local R=require('Training.ResourceQReview')
local function row(id,mode,status,cost,seconds)
 return {record={candidate=1,profile='field',setup={rule=1},mode=mode,status=status,episode={episode=id,resources={quote={priceVersion=1,total=18,deployment=2,lines={{actor='mentor',item='kinetic',quantity=4,unit=2,deploy=1},{actor='ninilite',item='emp',quantity=2,unit=4,deploy=1}}}}}},facts={status=status,cost=cost,telemetry={seconds=seconds}}}
end
local a=row('a','basic','won',10,20);local b=row('b','evaluate','failed',2,5)
local groups=R.build({a,b});assert(#groups==1 and groups[1].basic.winCost==10 and groups[1].evaluate.wins==0)
assert(R.text(groups[1]):find('候选胜利比例较低',1,true))
local c=row('c','evaluate','won',12,30);local s=R.build({a,b,c})[1];assert(s.evaluate.cost/s.evaluate.count==7 and s.evaluate.winCost/s.evaluate.wins==12)
local different=row('d','evaluate','won',10,20);different.record.episode.resources.quote.lines[1].quantity=6;different.record.episode.resources.quote.lines[2].quantity=1
assert(#R.build({a,different})==2,'Equal money is not equal equipment')
local reordered=row('e','evaluate','won',10,20);local ls=reordered.record.episode.resources.quote.lines;ls[1],ls[2]=ls[2],ls[1];assert(#R.build({a,reordered})==1)
local other=row('f','evaluate','won',10,20);other.record.candidate=2;assert(#R.build({a,other})==2)
other.record.candidate=1;other.record.profile='near';assert(#R.build({a,other})==2)
other.record.profile='field';other.record.setup.rule=2;assert(#R.build({a,other})==2)
assert(not pcall(R.build,{a,a}));assert(R.text(R.build({b,row('g','basic','failed',15,20)})[1]):find('两组均未取得胜利',1,true))
assert(R.text(nil):find('尚无',1,true));print('PASS resource review: full loadout/scenario/candidate/rule grouping, order-independent quote, successful-only cost, failures not savings, duplicate rejection')
