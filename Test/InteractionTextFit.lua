local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local report={status='RUNNING',runId=os.time(),osInput=false};local out=D.Path(root,'Test/interaction-text-fit-result.json')
 D.Content:save(out,D.json.encode(report))
 local ok,err=xpcall(function()
  local cases={}
  for _,flipped in ipairs({false,true})do
  for _,long in ipairs({false,true})do
  local parent=D.Node();parent:addTo(D.Director.ui3D)
  local ui=require('UI.Interaction')({text=long and '研究区撤离通道'or'妮妮莉特',buttons={{long and '重读初次交谈'or'对话',''},{long and '查看救援记录'or'个人信息',''}},fliped=flipped});ui:addTo(parent);ui.y=500
  local authored=ui.x
  local title=ui.children.first;local label=ui.screenBoundsTargets[2]
  assert(label.x+label.width+19<=title.width,'Title exceeds plate')
  ui.menu.children:each(function(button)local text=button.children.last;assert(text.x+text.width+34<=button.width,'Button exceeds plate')end)
  local function measure(n)
   local a,b;n:convertToWindowSpace(D.Vec2.zero,function(p)a=p end);n:convertToWindowSpace(D.Vec2(n.width,n.height),function(p)b=p end)
   local deadline=D.App.runningTime+2;while not(a and b)do assert(D.App.runningTime<deadline);D.sleep()end
   assert(n.width>0 and math.min(a.x,b.x)>=14 and math.max(a.x,b.x)<=D.App.visualSize.width-14,'Screen bounds failed')
  end
  for _,sample in ipairs({{'left',-500},{'middle',0},{'right',D.App.bufferSize.width},{'return',0}})do
   parent.x=sample[2];D.sleep(.4)
   for _,target in ipairs(ui.screenBoundsTargets)do measure(target)end
   if sample[1]=='middle'or sample[1]=='return'then assert(math.abs(ui.x-authored)<.1,'Correction stuck after moving away from edge '..ui.x..' authored '..authored)end
   cases[#cases+1]={position=sample[1],flipped=flipped,long=long}
  end
  parent:removeFromParent()
  end
  end
  report.cases=cases;report.status='PASS';report.releasedCorrection=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
