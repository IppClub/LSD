return function(root)
 local D=require('Dora')
 D.thread(function()
  local report={status='RUNNING',runId=os.time(),cases={},sceneReplaced=false,productionAsset=true,visualAcceptancePending=true};local holder
  local function save()D.Content:save(D.Path(root,'Test/interrogation-choreography-result.json'),D.json.encode(report))end
  save()
  local ok,err=xpcall(function()
   holder=D.Node();holder.x=-5000;holder:addTo(D.Director.ui3D)
   local rt=D.RenderTarget(1200,650);local camera=D.Camera2D();camera.position=D.Vec2(-4550,210);camera.zoom=1.3;rt.camera=camera
   for _,name in ipairs({'charM','charF'})do
    package.loaded['Factory.InterrogationActors']=nil
    local pair=require('Factory.InterrogationActors').new(holder);pair.node.position=D.Vec2(600,30);pair:addCompanions(name)
    assert(pair:coverAsync());D.sleep(.3);assert(pair:releaseAsync());assert(pair:warnAsync());assert(pair:slapAsync())
    assert(pair.phase=='unconscious' and pair.researcher.current=='unconscious')
    assert(#pair.events==4);local log=pair.slapLog;assert(log.impact-log.started>=.3 and log.impact-log.started<.38)
    assert(log.fallEnded-log.impact>=1.3);assert(log.ended-log.started>=.86)
    D.sleep(.25);rt:renderWithClear(holder,D.Color(0xff293341));rt:saveAsync(D.Path(root,'Docs/evidence/2026-10-04/interrogation-full-'..name..'.png'))
    report.cases[#report.cases+1]={mentor=name,events=pair.events};pair.node:removeFromParent()
   end
   report.status='PASS'
  end,debug.traceback)
  if holder then holder:removeFromParent()end
  if not ok then report.status='FAIL';report.error=err end
  save();print(D.json.encode(report))
 end)
end
