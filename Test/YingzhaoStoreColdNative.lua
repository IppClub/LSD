local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-store-cold-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/big-yingzhao-practice-result.json'),32)
  assert(prior.status=='PASS'and prior.persisted and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-observations%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-cold-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local store=require('Training.YingzhaoStore');local e=assert(store.loadAsync(1));assert(e.demonstrator=='wuyun'and e.resources.spent==8)
  assert(store.saveAsync(e));assert(D.DB:query('SELECT COUNT(*) FROM lsd.Game0YingzhaoObservations')[1][1]==1)
  local fake=D.json.decode(D.json.encode(e),32);fake.demonstrator='ninilite';assert(not store.saveAsync(fake))
  fake=D.json.decode(D.json.encode(e),32);fake.resources.mode='mission';fake.boss.resources.mode='mission';assert(not store.saveAsync(fake))
  local tables=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");for _,row in ipairs(tables)do assert(row[1]=='Game0YingzhaoObservations'or row[1]=='Config','Unexpected wallet or training table')end
  local samples=assert(require('Training.YingzhaoSamples').extract({e},'wuyun'))
  local shots=0
  for _,sample in ipairs(samples.samples)do
   assert(sample.state.ownX==nil and sample.state.knownArmor==nil and sample.state.at==nil and sample.state.healthDamage==nil)
   if sample.action=='shoot@head'then shots=shots+1;assert(sample.state.part_head=='unknown')end
  end
  assert(shots==1);assert(not require('Training.YingzhaoSamples').extract({e,e},'wuyun'))
  assert(#assert(require('Training.YingzhaoSamples').extract({e},'ninilite')).samples==0)
  assert(not require('Training.YingzhaoSamples').extract({[2]=e},'wuyun'))
  r.samples=#samples.samples;r.shotSamples=shots
  r.episode=e.episode;r.isolated=true;r.cost=e.resources.spent;r.coldRead=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
