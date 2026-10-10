-- Recreate Lua wrappers while native prompt nodes remain alive in the scene.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={runId=os.time(),status='RUNNING',cases=0};local out=D.Path(root,'Test/interaction-gc-result.json')
D.thread(function()
 local ok,err=xpcall(function()
  local Fit=require('UI.FitInteraction')
  for _,flipped in ipairs({false,true})do
   for i=1,50 do
    local node=require('UI.View.Interaction')({text='虚拟训练场：进入训练与查看训练成果',fliped=flipped})
    D.Director.entry:addChild(node)
    collectgarbage('collect');collectgarbage('collect')
    local title=node.children.first;local clip=title.children:get(3)
    if clip.mask==nil then report.collectedAlias=true end
    assert(clip.stencil and clip.stencil.children.first,'Native stencil lost')
    Fit.title(title,flipped)
    assert(title.width>=title.children.last.x+title.children.last.width+20)
    assert(math.abs(clip.stencil.children.first.scaleX-title.children.first.scaleX)<.001)
    local button=require('UI.InputButton')({text='进入训练并查看所有示范记录'})
    node:addChild(button);collectgarbage('collect');collectgarbage('collect');Fit.button(button)
    assert(button.width>=button.children.last.x+button.children.last.width+35)
    node:removeFromParent();report.cases=report.cases+1
    D.sleep(.01)
   end
  end
  report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
