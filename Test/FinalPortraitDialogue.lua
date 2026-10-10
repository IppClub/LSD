-- Actual Story layout, isolated earned QA copy, candidate portrait injection only in this test.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false,productionIntegrated=false}
local out=D.Path(root,'Test/final-portrait-dialogue-result.json')
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/final-betrayal-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-final%-betrayal%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-portrait-dialogue-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local tables={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do tables[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync();report.source=source;report.database=db
  local file=D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.json')..'|'..D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.atlas')
  local portrait=require('UI.StoryPortrait');local originalCreate,originalAsset=portrait.create,portrait.asset
  local model
  portrait.asset=function(id)if id=='ninilite'then return 'spine:'..file end;return originalAsset(id)end
  portrait.create=function(args)
   if args.char~='ninilite'then return originalCreate(args)end
   local node=D.Node();model=assert(D.Spine(file));model.position=D.Vec2(-102,40);model.scaleX=.46;model.scaleY=.46;model.recovery=.2
   model:play('listenCandidate',true);model:addTo(node);return node
  end
  D.Director.entry:slot('Cleanup',function()portrait.create=originalCreate;portrait.asset=originalAsset end)
  local view=require('UI.Story')(D.Path(root,'Test/FinalPortraitDialogue.yarn'));view:addTo(D.Director.ui3D);view:showAsync()
  local state={view=view,model=model,report=report};package.loaded['Test.PortraitDialogueState']=state
  view:slot('Ended',function()
   for name,value in pairs(tables)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
   report.status='ENDED';report.allTablesPreserved=true;report.rows=#view._reviews;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
  end)
  D.sleep(1);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-portrait-dialogue.tga'));D.sleep(.2)
  report.status='READY_FOR_REVIEW';report.actualScale=.46*view.figure.scaleX;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))end
end)
