local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-range-version-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-attack-teaching-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-attack%-teaching%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-range-version-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local P=require('Training.DisarmPolicy');local Store=require('Training.DisarmPolicyStore');local equal=require('Training.FlowerIdentity').equal
  local rows=assert(D.DB:query('SELECT id,payload FROM lsd.Game0DisarmCandidates ORDER BY id'));local frozen=D.json.encode(rows,false,true);local max=rows[#rows][1]
  for _,actor in ipairs({'ninilite','wuyun'})do local c=assert(Store.loadLatestAsync(actor));assert(c.model.featureSchemaVersion==1)end;r.legacyColdRead=true
  local source=D.json.decode(rows[#rows][2],32);local observation
  for _,record in ipairs(source.records)do for _,step in ipairs(record.source.trace.executions)do if step.actor=='wuyun'then observation=D.json.decode(D.json.encode(step.before),32);break end end;if observation then break end end
  assert(observation);observation.enemyDistance=300
  local old=assert(P.project(observation,'wuyun',1));local inside=assert(P.project(observation,'wuyun',2));assert(old.distance=='mid'and old.meleeRange==nil and inside.meleeRange=='within')
  observation.enemyDistance=300.001;local outside=assert(P.project(observation,'wuyun',2));assert(outside.distance=='mid'and outside.meleeRange=='outside')
  observation.enemyDistance=nil;assert(P.project(observation,'wuyun',2).meleeRange=='none');assert(not P.project(observation,'wuyun',3));r.boundary=true
  local c,why=Store.learnAsync('wuyun');assert(c,why);assert(c.model.featureSchemaVersion==2);assert(equal(Store.loadLatestAsync('wuyun').model,c.model));r.newSourceRebuilt=true
  assert(frozen==D.json.encode(D.DB:query('SELECT id,payload FROM lsd.Game0DisarmCandidates WHERE id<=? ORDER BY id',{max}),false,true));r.legacyUnchanged=true
  local fixture=D.json.decode(D.json.encode(c.model),32);fixture.rules={{action='melee',conditions={{name='meleeRange',op='==',value='within'}}}}
  observation.enemyDistance=300;assert(P.predict(fixture,observation,function()return true end)=='melee')
  observation.enemyDistance=300.001;local action,why=P.predict(fixture,observation,function()return true end);assert(not action and why=='NO_MATCH')
  fixture.featureSchemaVersion=1;assert(not P.validate(fixture));r.legacyRuleRejected=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
