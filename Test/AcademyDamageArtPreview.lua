-- Run after the live training soak finishes. No database is opened.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),visualAcceptancePending=true,scenes={}}
local out=D.Path(root,'Test/academy-damage-art-preview-result.json')
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  for _,name in ipairs({'PassageA','RDRoom','RestRoom'})do
   local Scene=require('Scene.'..name);Scene:loadAsync()
   D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear()
   local world=Scene();world:addTo(D.Director.entry)
   world.camera.position=D.Vec2(world.sceneWidth*.5,world.offset+300)
   local damage=require('Story.AcademyLoss').damageWorld(world)
   local art,dust=damage.damageNode,damage.smoke
   assert(art.children.count==12,'Expected dim layer and eleven damage sprites')
   assert(dust.children.count==3,'Expected three reused dust sprites')
   D.sleep(2)
   D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-damage-v1-'..name..'.tga'))
   report.scenes[#report.scenes+1]={name=name,width=world.sceneWidth,offset=world.offset}
  end
  report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
