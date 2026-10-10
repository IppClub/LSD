-- Check present-day text against three earned saves without rewriting history.
-- Run only once the active training soak reaches terminal status.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={runId=os.time(),status='RUNNING',osInput=false,cases={}}
local out=D.Path(root,'Test/academy-roster-current-result.json')
D.Content:save(out,D.json.encode(report))
D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
D.thread(function()
 local ok,why=xpcall(function()
  for _,case in ipairs({
   {fixture='male-current-academy-loss',rescued=false,betrayed=false},
   {fixture='male-current-twins-evacuation',rescued=true,betrayed=false},
   {fixture='male-current-final-betrayal',rescued=true,betrayed=true},
  })do
   local source=assert(D.Content:load(D.Path(root,'Test/'..case.fixture..'-resume-fixture.txt')))
   assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-'))
   local db=D.Path(D.Content.writablePath,'lsd-roster-current-qa-'..report.runId..'-'..#report.cases..'.db')
   assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db))
   assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
   local before={}
   for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do before[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
   local Records=require('Story.AcademyLossRecords');local rows=assert(Records.current());local found={}
   for _,r in ipairs(rows)do found[r.role]=r end
   for _,role in ipairs({'vika','vivi'})do assert(found[role].status==(case.rescued and 'rescued'or'awaiting-rescue'))end
   assert(found.sunborn.status==(case.betrayed and 'betrayed'or'active'))
   local hint=Records.rescueHint(rows)
   assert(hint==(case.rescued and '研究区的双子已获救，救援记录已保存。'or'研究区仍有同伴等待救援。'))
   for _,r in ipairs(assert(Records.saved()))do
    if r.role=='vika'or r.role=='vivi'then assert(r.status=='awaiting-rescue')end
    if r.role=='sunborn'then assert(r.status=='active')end
   end
   if case.betrayed then
    local ending=assert(require('Ending.Records').read());local seen=false
    for _,r in ipairs(ending.roster)do if r.role=='sunborn'then assert(r.status=='betrayed');seen=true end end
    assert(seen)
   end
   for name,value in pairs(before)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed historical data '..name)end
   report.cases[#report.cases+1]={source=source,database=db,hint=hint,linStatus=found.sunborn.status,allTablesUnchanged=true}
   assert(D.DB:exec('DETACH DATABASE lsd')>=0)
  end
  report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
