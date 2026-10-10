return function(root)
 local D=require('Dora')
 D.thread(function()
  local holder;local report={status='RUNNING',sceneReplaced=false,runId=os.time()}
  local ok,err=xpcall(function()
   holder=D.Node();holder.x=-5000;holder:addTo(D.Director.ui3D)
   require('Story.FoxCompanion').loadAsync();local fox=require('Story.FoxCompanion').create();fox.position=D.Vec2(320,30);fox:addTo(holder)
   package.loaded['Story.FoxThreat']=nil;local face=require('Story.FoxThreat').attach(fox);face:show(true);D.sleep(.1)
   local portrait=fox:getNodeByName('original-art');report.portrait={width=portrait.width,height=portrait.height,anchorX=portrait.anchor.x,anchorY=portrait.anchor.y}
   local rt=D.RenderTarget(800,650);local camera=D.Camera2D();camera.position=D.Vec2(-4680,185);camera.zoom=1.8;rt.camera=camera
   rt:renderWithClear(holder,D.Color(0xff293341));rt:saveAsync(D.Path(root,'Docs/evidence/2026-10-03/fox-threat-native.png'))
   face:show(false);assert(face:warnAsync());assert(not face.patch.visible);report.status='PASS';report.visualAcceptancePending=true
  end,debug.traceback)
  if holder then holder:removeFromParent()end
  if not ok then report.status='FAIL';report.error=err end
  D.Content:save(D.Path(root,'Test/fox-threat-result.json'),D.json.encode(report));print(D.json.encode(report))
 end)
end
