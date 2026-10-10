-- Native assembly and full action timing; model events are the impact oracle.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','patrol-guard-result.txt');D.Content:save(out,'LSD_PATROL_GUARD_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  D.Cache:unload('Image/Factory/patrol-guard.model');D.Cache:unload('Image/Factory/patrol-guard.clip')
  local m=assert(D.Model('Image/Factory/patrol-guard.model'));m.position=D.Vec2(ui.width/2,130);m.scaleX=.85;m.scaleY=.85;m.recovery=.2;m:addTo(ui)
  local label=D.Label('SourceHanSansCN-Regular',26);label.text='断网组织 · 巡逻守卫 / 新分件模型';label.position=D.Vec2(ui.width/2,ui.height-60);label:addTo(ui)
  m:play('prepare',true);D.sleep(.4)
  local pairs={{'farLeg','farBoot'},{'nearLeg','nearBoot'}};local joints={}
  for _,pair in ipairs(pairs) do local leg=m:getNodeByName(pair[1]);local foot=m:getNodeByName(pair[2]);local pos=foot:convertToWorldSpace(D.Vec2(foot.width*foot.anchor.x,foot.height*foot.anchor.y));joints[#joints+1]={leg=leg,foot=foot,localAnchor=leg:convertToNodeSpace(pos)} end
  m:play('fmove',true);D.sleep(.3);local seam=0
  for sample=1,24 do for _,j in ipairs(joints) do local expected=j.leg:convertToWorldSpace(j.localAnchor);local actual=j.foot:convertToWorldSpace(D.Vec2(j.foot.width*j.foot.anchor.x,j.foot.height*j.foot.anchor.y));seam=math.max(seam,(expected-actual).length) end;D.sleep(.025) end
  assert(seam<1.6,'Guard boot detached from leg');m:play('prepare',true);D.sleep(.3)
  local ends={};local impacts={};local started=0;m:slot('AnimationEnd',function(name)ends[name]=D.App.runningTime-started end);m:slot('ModelEvent',function(_,name)if name=='guard-shot' then impacts[#impacts+1]=D.App.runningTime-started end end)
  local timings={};local expected={idle=2,prepare=1.5,fmove=1.2,shoot=1.4,hit=.6,lose=1.6}
  for _,name in ipairs({'idle','prepare','fmove','shoot','hit','lose'}) do
   started=D.App.runningTime;local duration=m:play(name,false);assert(duration>0)
   local deadline=started+duration+2;while not ends[name] do assert(D.App.runningTime<deadline,'Guard native end missing '..name);D.sleep(.01) end
   assert(ends[name]>=expected[name]-.05,'Guard cut short '..name);timings[#timings+1]={name=name,duration=duration,actualEnd=ends[name]}
  end
  assert(#impacts==1 and impacts[1]>=.78 and impacts[1]<1.15,'Rifle impact outside authored frame')
  m:play('prepare',true);D.sleep(.4)
  return 'PASS nativeAssembly=true timelines=6 fullAnimationEnd=true impactOnce=true nativeBootJoints=true recovery=.2 '..D.json.encode({timings=timings,impact=impacts[1],maxSeam=seam},false,true)
 end,debug.traceback)
 local report='LSD_PATROL_GUARD_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
