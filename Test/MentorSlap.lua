return function(root)
 local D=require('Dora')
 D.thread(function()
  local report={status='RUNNING',runId=os.time(),cases={},sceneReplaced=false};local holder
  local function save()D.Content:save(D.Path(root,'Test/mentor-slap-result.json'),D.json.encode(report))end
  save()
  local ok,err=xpcall(function()
   holder=D.Node();holder.x=-5000;holder:addTo(D.Director.ui3D)
   local rt=D.RenderTarget(1000,700);local camera=D.Camera2D();camera.position=D.Vec2(-4650,205);camera.zoom=1.8;rt.camera=camera
   for _,name in ipairs({'charM','charF'})do
    holder:removeAllChildren()
    local asset=D.Path(root,'Docs/artwork/interrogation/'..name..'/export/actions.skel')..'|'..D.Path(root,'Spine/'..name..'.atlas');D.Cache:unload('spine:'..asset)
    local mentor=assert(D.Spine(asset));mentor.position=D.Vec2(300,30);mentor.order=1;mentor:addTo(holder)
    local research=assert(D.Spine(D.Path(root,'Docs/artwork/researcher/export/actions.skel')..'|'..D.Path(root,'Spine/shujuyuan.atlas')));research.position=D.Vec2(400,30);research.fliped=true;research:addTo(holder);research.recovery=0;research:play('restrained',true)
    local floor=D.DrawNode();floor:drawSegment(D.Vec2(0,30),D.Vec2(900,30),1,D.Color(0xff8999a9));floor:addTo(holder);floor.order=-1
    local case={name=name,samples={}};report.cases[#report.cases+1]=case
    local fit=D.json.decode(D.Content:load(D.Path(root,'Docs/artwork/interrogation/'..name..'/hand-fit.json')))
    D.sleep(.03);research.speed=0;local mouth=research:getKey('contact:mouth/mouth');mentor.x=research.x+mouth.x-fit.palmX
    for _,t in ipairs({.01,.22,.32,.43,.9})do
     mentor.recovery=0;mentor.speed=1;mentor:play('interrogationSlap',false);D.sleep(t);mentor.speed=0
     local p=mentor:getKey('item/s:item');local m=research:getKey('contact:mouth/mouth')
     local path=D.Path(root,'Docs/evidence/2026-10-03/mentor-slap-'..name..'-'..t..'.png');rt:renderWithClear(holder,D.Color(0xff293341));rt:saveAsync(path)
     case.samples[#case.samples+1]={time=t,path=path,palm={x=p.x,y=p.y},distance=math.sqrt((mentor.x+p.x-research.x-m.x)^2+(p.y-m.y)^2)}
    end
    local started;local active=false;local impact,mentorEnd,researchEnd
    mentor:slot('interrogationSlap',function()
     if not active then return end
     impact=D.App.runningTime-started;research.speed=1;research.recovery=.15;research:play('knockout',false)
    end)
    mentor:slot('AnimationEnd',function(n)if active and n=='interrogationSlap' and D.App.runningTime-started>.85 then mentorEnd=D.App.runningTime-started end end)
    research:slot('AnimationEnd',function(n)if active and n=='knockout' then researchEnd=D.App.runningTime-started end end)
    mentor.speed=1;mentor.recovery=0;mentor:play('interrogationSlap',false);started=D.App.runningTime;active=true
    while not(mentorEnd and researchEnd)do assert(D.App.runningTime-started<4,'slap chain did not finish');D.sleep(.02)end
    active=false;case.impact=impact;case.mentorEnd=mentorEnd;case.researchEnd=researchEnd
    assert(impact>=.30 and impact<.38,'wrong attack frame');assert(researchEnd-impact>=1.3,'fall cut short')
    mentor.recovery=.15;mentor:play('idle',true);research.recovery=0;research:play('unconscious',true);D.sleep(.15)
    local path=D.Path(root,'Docs/evidence/2026-10-03/mentor-slap-'..name..'-settled.png');rt:renderWithClear(holder,D.Color(0xff293341));rt:saveAsync(path);case.settled=path
   end
   report.status='PASS';report.visualAcceptancePending=true
  end,debug.traceback)
  if holder then holder:removeFromParent()end
  if not ok then report.status='FAIL';report.error=err end
  save();print(D.json.encode(report))
 end)
end
