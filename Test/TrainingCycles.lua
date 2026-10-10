local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),osInput=false,cycles={}};local out=D.Path(root,'Test/training-cycles-result.json')
local function save()D.Content:save(out,D.json.encode(report))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-cooperation-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-cooperation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-training-cycles-qa-'..report.runId..'.db');report.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true)
  local function wait(f)local limit=D.App.runningTime+35;while not f()do assert(D.App.runningTime<limit,'Training lifecycle timeout');D.sleep(.03)end end
  local weak=setmetatable({},{__mode='v'})
  require('Academy.Navigation').returnToTrainingAsync()
  for i=1,20 do
   local world=D.Platformer.Data.store.world;assert(world.tag=='TrainingRoom')
   local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   local p;wait(function()p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end);return p and not p.busy end)
   hud.move:emit('Left',true);wait(function()return p.unit.x<950 end);hud.move:emit('Left',false);D.sleep(.15)
   local terminal=assert(world:getChildByTag('trainingTerminal'));assert(terminal.visible);terminal:emit('Tapped',1)
   wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
   local ui=D.Director.ui3D:getChildByTag('training-controls');local a=ui.arena;weak[i]=a
   local trainingHUD=assert(D.Director.ui3D:getChildByTag('trainingHUD'));wait(function()return a:available('idle')end)
   trainingHUD.skillArea:getChildByTag('training-wait'):emit('TapBegan');D.sleep(.08);assert(#a.recorder.samples==1,'Duplicate or missing input handler')
   local count=0;D.Director.ui3D.children:each(function(n)if n.tag=='training-controls'or n.tag=='trainingHUD'then count=count+1 end end);assert(count==2)
   local menu=assert(ui:getChildByTag('training-menu'));menu:getChildByTag('返回训练室'):emit('Tapped')
   wait(function()return a.closed and D.Platformer.Data.store.world.tag=='TrainingRoom'end)
   a=nil;ui=nil;trainingHUD=nil;menu=nil;terminal=nil;world=nil;hud=nil;p=nil
   D.sleep(.2);collectgarbage('collect');D.sleep(.1);collectgarbage('collect')
   local retained=0;for _,v in pairs(weak)do if v then retained=retained+1 end end
   report.cycles[i]={objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount,luaKB=collectgarbage('count'),retainedArenas=retained}
   save()
  end
  local first=report.cycles[1];local minObjects,maxObjects=first.objects,first.objects
  for _,row in ipairs(report.cycles)do
   assert(row.luaRefs==first.luaRefs and row.callRefs==first.callRefs and row.retainedArenas<=1,'Unbounded training references')
   minObjects=math.min(minObjects,row.objects);maxObjects=math.max(maxObjects,row.objects)
  end
  assert(maxObjects-minObjects<=2,'Scene object growth')
  save();collectgarbage('collect');local measuredBefore=collectgarbage('count')
  report.cycles=nil;collectgarbage('collect');local measuredAfter=collectgarbage('count')
  local saved=D.json.decode(D.Content:load(out),128);report.cycles=saved.cycles
  report.recordMemoryReleasedKB=measuredBefore-measuredAfter;report.objectRange={minObjects,maxObjects};report.referenceCountsStable=true
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),false,true));report.adoptedDataUnchanged=true;report.status='PASS';report.resourceTrendNeedsReview=false
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;save();print(D.json.encode(report))
end)
