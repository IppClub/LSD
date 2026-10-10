local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local out=D.Path(root,'Test/input-button-mouse-result.json');local report={status='RUNNING',runId=os.time(),osInput=false};D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local button=require('UI.InputButton')({text='旅程回顾与署名',textBG=''})
  button:addTo(D.Director.ui3D);button.scaleX=.8;button.scaleY=.8
  local label=button.children.last;assert(label.x+label.width+35<=button.width)
  assert(button.width>309);report.width=button.width
  local clicked=false;button:slot('Tapped',function()clicked=true end)
  D.sleep(.2)
  button:convertToWindowSpace(D.Vec2(button.width-20,button.height/2),function(p)report.target={x=p.x,y=p.y}end)
  local deadline=D.App.runningTime+5;while not report.target do assert(D.App.runningTime<deadline);D.sleep()end
  report.awaitingMouse=true;D.Content:save(out,D.json.encode(report))
  deadline=D.App.runningTime+120;while not clicked do assert(D.App.runningTime<deadline,'Actual mouse click required');D.sleep(.05)end
  report.osInput=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
