-- Native geometry invariants for the assembled joints and closed cargo hatches.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,'Test','auxiliary-joints-result.txt');D.Content:save(out,'LSD_AUXILIARY_JOINTS_RUNNING\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local m=assert(require('Ground.AuxiliaryModel').create('cargo'));m.position=D.Vec2(ui.width/2,ui.height*.3);m:addTo(ui)
  D.sleep(.5);m:play('idle',true);D.sleep(.5)
  local rear=m:getNodeByName('lid');local side=m:getNodeByName('crateLid');local body=m:getNodeByName('body');local box=m:getNodeByName('rightCrate')
  assert(rear.y<body.y+60,'Rear hatch remains visibly raised in idle')
  assert(side.y<box.y,'Right hatch remains visibly raised in idle')
  local closed={rear.y,side.y};local ends={};m:slot('AnimationEnd',function(name) ends[name]=D.App.runningTime end)
  for _,name in ipairs({'collect','carry'}) do
   local began=D.App.runningTime;local duration=m:play(name,false)
   D.sleep(.2+(duration-.2)/2)
   assert(rear.y>closed[1]+80 and side.y>closed[2]+65,'Hatches did not open for '..name)
   while not ends[name] do D.sleep(.01);assert(D.App.runningTime-began<duration+.5,'Hatch animation stalled') end
   assert(ends[name]-began>=duration-.05,'Hatch action cut short')
   assert(math.abs(rear.y-closed[1])<.02 and math.abs(side.y-closed[2])<.02,'Hatches did not close on native animation end')
   m:play('idle',true);D.sleep(.3)
   assert(math.abs(rear.y-closed[1])<.02 and math.abs(side.y-closed[2])<.02,'Recovery reopened closed hatch')
  end
  local pairs={{'leftLeg','leftFoot'},{'rightLeg','rightFoot'},{'rearLeft','rearLeftFoot'},{'rearRight','rearRightFoot'}}
  local joints={}
  for i,p in ipairs(pairs) do
   local leg=m:getNodeByName(p[1]);local foot=m:getNodeByName(p[2]);local anchor=foot:convertToWorldSpace(D.Vec2(foot.width*foot.anchor.x,foot.height*foot.anchor.y))
   joints[i]={leg=leg,foot=foot,localAnchor=leg:convertToNodeSpace(anchor),angle=leg.angle}
  end
  m:play('move',true);D.sleep(.3)
  local maxError=0;local moved=false
  for sample=1,36 do
   for _,j in ipairs(joints) do
    local expected=j.leg:convertToWorldSpace(j.localAnchor);local actual=j.foot:convertToWorldSpace(D.Vec2(j.foot.width*j.foot.anchor.x,j.foot.height*j.foot.anchor.y))
    local error=(expected-actual).length;maxError=math.max(maxError,error)
    assert(error<1.6,'Foot detached from moving leg: '..tostring(error));moved=moved or math.abs(j.leg.angle-j.angle)>4
   end
   D.sleep(.03)
  end
  assert(moved,'Walking test did not observe a moving joint');m:play('idle',true)
  return string.format('PASS nativeClosedIdle=true rearAndRightHatchesOpenOnlyInCollectCarry=true fullNativeEnd=true bothCloseBeforeRecovery=true fourFeetFollowNativeJoints=true maxSeamError=%.4f recovery=.2',maxError)
 end,debug.traceback)
 local report='LSD_AUXILIARY_JOINTS_'..(ok and result or 'FAIL '..tostring(result));print(report);D.Content:save(out,report..'\n')
end)
