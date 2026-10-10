package.path='Script/?.lua;'..package.path
local L=require('Economy.Ledger');local E=require('Training.ResourceEvidence')
local ledger=assert(L.new('mixed',{{actor='mentor',item='kinetic',quantity=5},{actor='ninilite',item='emp',quantity=5}},100,0))
assert(L.consume(ledger,'ni','ninilite','emp',1,'ninilite',2))
assert(L.consume(ledger,'mentor','mentor','kinetic',1,'mentor',1))
assert(L.consume(ledger,'stolen','mentor','kinetic',1,'enemy:1'))
local ok,why=L.consume(ledger,'mentor','mentor','kinetic',1,'mentor',2);assert(not ok and why=='EVENT_CONFLICT')
local steps={{id=1,action={actor='mentor',weapon='kinetic',name='shoot'}},{id=2,action={actor='ninilite',weapon='emp',name='shoot'}}}
local evidence={schemaVersion=1,trainable=false,attempt=ledger.attempt,quote=ledger.quote,stock=ledger.stock,spent=ledger.spent,events=ledger.events}
local costs=assert(E.attribute(evidence,steps));assert(costs.byStep['1'].cost==2 and costs.byStep['2'].cost==4 and costs.unattributed==2 and costs.deployment==5 and costs.total==13)
ledger.events.ni.step=1;assert(not E.attribute(evidence,steps));ledger.events.ni.step=2
ledger.events.stolen.step=1;assert(not E.attribute(evidence,steps));ledger.events.stolen.step=nil
assert(E.attribute(evidence,steps))
print('PASS: overlapping actors, wrong actor/step rejection, stolen cost separate, deployment separate, step replay conflict')
