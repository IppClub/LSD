-- Chibi rig registered to the six visible torso sockets.
local D=require('Dora');local V=D.Vec2
local style={
 texture='Image/Rescue/buddha-guard-limbs-v6.png',rowHeight=576,
 handPoint=V(310,210),torsoY=40,torsoScale=.65,haloScale=.85,haloY=80,
 shoulders={[-1]={V(62,65),V(94,4),V(61,-84)},[1]={V(93,45),V(111,4),V(113,-78)}},
 shoulderAngles={[-1]={-140,-75,-10},[1]={-140,-75,-1}},
 upperAnchor=V(291/512,501/576),elbowOffset=V(-2.25,-101.25),
 forearmAnchor=V(226/512,430/576),wristOffset=V(7.5,-90.25),
 handAnchor=V(260/512,69/448),cupAnchor=V(108/512,206/448)
}

local texture='Image/Rescue/buddha-guard-head-torso-v6.png'
style.torsoPart={texture=texture,rect=D.Rect(627,0,627,1254),anchor=V(303/627,746/1254),scale=.38,position=V(0,50)}
style.headPart={texture=texture,rect=D.Rect(0,0,627,1254),anchor=V(320/627,366/1254),scale=.323,position=V(0,32),order=1}
style.haloScale=.88;style.haloY=125
style.shoulders={[-1]={V(69,17),V(76,-27),V(49,-62)},[1]={V(83,17),V(95,-27),V(72,-62)}}
style.upperAnchor=V(295/512,476/576)
return style
