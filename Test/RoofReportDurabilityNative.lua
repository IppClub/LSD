-- Actual original roof entry and paid withdrawal; no HP/model/wallet injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/roof-report-durability-result.json'
local r={status='RUNNING',osInput=false,scope='Original roof report persistence after late rejected input'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(root..'/Test/roof-dialogue-resume-fixture.txt'))
  assert(source:match('^/Users/Jin/Workspace/Dora/lsd%-roof%-dialogue%-qa%-%d+%.db$'))
  local db=D.Content.writablePath..'/roof-report-durability-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.source=source;r.database=db
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 45);while not fn()do assert(D.App.runningTime<deadline,'Roof durability stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.roof and w.roof.phase=='ready'end)
  local roof=D.Platformer.Data.store.world.roof;assert(roof:act());wait(function()return roof.supplyPanel end)
  assert(roof.supplyPanel.quote.total<=E.wallet().available);roof.supplyPanel.saveButton:emit('Tapped')
  wait(function()return roof.world.patrolLevel end);local level=roof.world.patrolLevel;local b=level.battle
  assert(b.supplies and not b.supplies.isVirtual);wait(function()return b.mentor.onSurface and b.arena.student.onSurface end)
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  b:command('stop');level.withdraw:emit('Tapped');wait(function()return level.phase=='result'end)
  assert(b.phase=='aborted'and level.result.resultLayout=='MissionFail'and not E.active())
  local attempt=assert(tonumber(b.supplies.attempt:match('(%d+)$')));r.attempt=attempt
  local rows=assert(D.DB:query('SELECT report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt}))
  local stored=D.json.decode(rows[1][1],32);r.stored=stored;r.before=D.json.decode(D.json.encode(b.report,false,true),32)
  local accepted,why=b:command('stop');assert(not accepted and why=='NOT_PLAYING')
  r.after=D.json.decode(D.json.encode(b.report,false,true),32);r.lateInputRejected=true;r.balanceAfter=E.wallet().available;save()
  assert(D.json.encode(r.before.commands,false,true)==D.json.encode(r.after.commands,false,true),'Settled report command counts changed after rejected input')
  local function same(a,b)
   if type(a)~=type(b)then return false end
   if type(a)=='userdata'then return D.json.encode(a,false,true)==D.json.encode(b,false,true)end
   if type(a)~='table'then return a==b end
   for k,v in pairs(a)do if not same(v,b[k])then return false end end
   for k in pairs(b)do if a[k]==nil then return false end end;return true
  end
  assert(same(stored,r.after),'Displayed roof report differs from actual saved report')
  assert(r.balanceAfter==r.balanceBefore-stored.economy.cost and stored.economy.income==0)
  assert(D.DB:query('SELECT report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]==rows[1][1])
  r.reportAndLedgerStable=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_ROOF_REPORT_DURABILITY_'..r.status)
end)
