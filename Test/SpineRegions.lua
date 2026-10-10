local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/spine-regions-result.json';local report={status='RUNNING',frames=0,checks=0,hits=0,cases={}}
 local function save()D.Content:save(out,D.json.encode(report))end;save()
 local ok,err=xpcall(function()
  local base=root..'/Docs/artwork/boss-hitboxes'
  local manifest=assert(D.json.decode(D.Content:load(base..'/vertex-probes.json')))
  local skel=base..'/export/dataotie-hitboxes.skel';local atlas=root..'/Spine/dataotie.atlas'
  D.Cache:loadAsync('spine:'..skel..'|'..atlas)
  local m=assert(D.Spine(skel,atlas));m.look='default';m.hitTestEnabled=true;m.recovery=.2;m.scaleX=.4;m.scaleY=.4;m.position=D.Vec2(700,250);m:addTo(D.Director.entry)
  local R=require('Combat.SpineRegions');local G=require('Combat.HitGeometry')
  for _,flip in ipairs({false,true})do
   m.fliped=flip
   for _,clip in ipairs({'idle','fmove','pounce','swing','rush3'})do
    local duration=m:play(clip,false);assert(duration>0)
    local row={clip=clip,flipped=flip,duration=duration};report.cases[#report.cases+1]=row
    for frame=1,6 do
     D.sleep(duration/7)
     local parts=R.sample(m,manifest);assert(#parts==7)
     local frameHits=0
     for x=-1200,1200,53 do for y=-200,1000,47 do
      local ours=false;for _,p in ipairs(parts)do if G.contains({x=x,y=y},p.vertices)then ours=true;break end end
      local found=m:containsPoint(x,y);local native=found~=nil and found~=''
      assert(ours==native,'Hull mismatch '..clip..' '..x..','..y)
      report.checks=report.checks+1;if native then frameHits=frameHits+1 end
     end end
     assert(frameHits>0,'Empty animated hit regions');report.hits=report.hits+frameHits;report.frames=report.frames+1
     -- Validate model->world->container transform with non-uniform scale/rotation.
     m.angle=13;m.scaleY=.55
     local world=R.sample(m,manifest,D.Director.entry)
     local localP=parts[1].vertices[1];local expected=D.Director.entry:convertToNodeSpace(m:convertToWorldSpace(D.Vec2(localP.x,localP.y)))
     assert(math.abs(world[1].vertices[1].x-expected.x)<.01 and math.abs(world[1].vertices[1].y-expected.y)<.01)
     m.angle=0;m.scaleY=.4
    end
    save()
   end
  end
  m:removeFromParent()
 end,debug.traceback)
 report.status=ok and 'PASS' or 'FAIL';report.error=not ok and err or nil;save()
end)
