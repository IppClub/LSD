-- Keep the original prompt artwork and font size; expand its plate and hit area.
-- Read the native stencil: a child wrapper can be collected along with its mask alias.
local Fit={}
function Fit.button(node)
 local label=node.children.last
 local width=math.max(node.width,label.x+label.width+35)
 local ratio=width/node.children.first.width
 node.children.first.scaleX=ratio
 local moving=node.children:get(2)
 moving.stencil.children.first.scaleX=ratio
 node.width=width
 return node
end
function Fit.title(node,flipped)
 local label=node.children.last
 local width=math.max(node.width,label.x+label.width+20)
 local plate=node.children.first
 local ratio=width/plate.width
 plate.scaleX=(flipped and -1 or 1)*ratio;plate.x=width/2
 local edge=node.children:get(2);edge.x=flipped and 0 or width
 local moving=node.children:get(3)
 moving.stencil.children.first.scaleX=(flipped and -1 or 1)*ratio
 node.width=width
end
return Fit
