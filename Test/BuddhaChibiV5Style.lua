local D=require('Dora');local V=D.Vec2
local style={}
for k,v in pairs(require('Test.BuddhaChibiV4Style'))do style[k]=v end
local texture='Docs/artwork/buddha-guard-head-torso-v5.png'
style.torsoPart={texture=texture,rect=D.Rect(627,0,627,1254),anchor=V(303/627,746/1254),scale=.38,position=V(0,50)}
style.headPart={texture=texture,rect=D.Rect(0,0,627,1254),anchor=V(320/627,366/1254),scale=.38,position=V(0,32),order=1}
style.haloScale=.88;style.haloY=125
style.shoulders={[-1]={V(69,17),V(76,-27),V(49,-62)},[1]={V(83,17),V(95,-27),V(72,-62)}}
style.upperAnchor=V(295/512,476/576)
return style
