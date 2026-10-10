local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Font'),D.Path(root,'Image')})do D.Content:insertSearchPath(1,p)end
local r={status='RUNNING',runId=os.time(),osInput=false};local out=D.Path(root,'Test/academy-door-companion-priority-result.json');D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-academy-loss-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-academy%-loss%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-door-companion-priority-qa-'..r.runId..'.db');assert(D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local function wait(f,t)local limit=D.App.runningTime+t;while not f()do assert(D.App.runningTime<limit,'Interaction timeout');D.sleep(.03)end end
  require('Start');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.tag=='PassageA'end,40);D.sleep(1)
  local w=D.Platformer.Data.store.world;local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end))
  local npc=assert(D.Group({'name','unit'}):find(function(e)return e.name=='ninilite'and not e.player and e.unit.world==w end))
  assert(p.moveTargets and p.interaction.menu.enabled);assert(not npc.interaction,'NPC menu overlaps elevator');r.doorOnly=true
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-door-priority.tga'))
  local hud;for i=1,D.Director.ui3D.children.count do local n=D.Director.ui3D.children:get(i);if n.move then hud=n end end;assert(hud)
  hud.move:emit('Right',true);wait(function()return not p.moveTargets and npc.interaction and npc.interaction.menu.enabled end,8);hud.move:emit('Right',false);D.sleep(.4)
  assert(not p.interaction and npc.interaction.menu.enabled);r.companionRestored=true
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-companion-restored.tga'))
  hud.move:emit('Left',true);wait(function()return p.moveTargets and p.interaction and p.interaction.menu.enabled end,8);hud.move:emit('Left',false);D.sleep(.5);assert(not npc.interaction);r.doorRestored=true
  local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)=='PassageC'then index=i end end;assert(index);p.interaction:emit('Tapped',index)
  wait(function()return D.Platformer.Data.store.world~=w and D.Platformer.Data.store.world.tag=='PassageC'end,20);r.travelWorked=true;r.status='PASS'
 end,debug.traceback)
 if not ok then r.status='FAIL';r.error=err end;D.Content:save(out,D.json.encode(r));print(D.json.encode(r))
end)
