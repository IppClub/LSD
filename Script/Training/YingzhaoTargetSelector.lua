local D=require('Dora');local M={}
function M.attach(c)
 local b=c.battle;local node=D.Node();node.tag='yingzhao-target-selector';node:addTo(D.Director.ui3D)
 local entries={{'head','头部'},{'torso','上身'},{'flank','躯干'},{'arms','手臂'},{'forelegs','前腿'},{'hindlegs','后腿'},{'summon','援军'}}
 local buttons,holders={},{};c.targetButtons=buttons
 for _,entry in ipairs(entries)do
  local holder=D.Node();holder.scaleX=.4;holder.scaleY=.4;holder:addTo(node);holders[entry[1]]=holder
  local v=require('UI.InputButton')({text=entry[2],textBG=''});v:addTo(holder);buttons[entry[1]]=v
  v:slot('Tapped',function()b:command('aim-part',entry[1])end)
 end
 local lastWidth,lastHeight,lastTextHeight
 local function layout()
  node.size=D.App.bufferSize;local width=D.App.bufferSize.width;local columns=math.max(1,math.min(7,math.floor((width-40)/135)))
  local textHeight=c.status and c.status.height or 0
  local top=math.max(295,25+textHeight+24)
  local rows=math.ceil(#entries/columns)
  c.targetSelectorHeaderHeight=top+(rows-1)*42+40
  for i,entry in ipairs(entries)do holders[entry[1]].position=D.Vec2(85+((i-1)%columns)*135,D.App.bufferSize.height-top-math.floor((i-1)/columns)*42)end
  lastWidth,lastHeight,lastTextHeight=width,D.App.bufferSize.height,textHeight
 end
 layout();node:gslot('AppChange',function(name)if name=='Size'then layout()end end)
 node:schedule(function()
  if b.phase~='ready'and b.phase~='playing'then node:removeFromParent();return true end
  if lastWidth~=D.App.bufferSize.width or lastHeight~=D.App.bufferSize.height or lastTextHeight~=(c.status and c.status.height or 0)then layout()end
  for id,v in pairs(buttons)do v.opacity=id==b.demonstrationTarget and 1 or .6 end
  return false
 end)
 c.targetSelector=node;return node
end
return M
