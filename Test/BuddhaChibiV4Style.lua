-- Chibi rig registered to the six visible torso sockets.
local V=require('Dora').Vec2
return {
 texture='Docs/artwork/buddha-guard-chibi-v4.png',rowHeight=576,
 handPoint=V(310,210),torsoY=40,torsoScale=.65,haloScale=.85,haloY=80,
 shoulders={[-1]={V(62,65),V(94,4),V(61,-84)},[1]={V(93,45),V(111,4),V(113,-78)}},
 shoulderAngles={[-1]={-140,-75,-10},[1]={-140,-75,-1}},
 upperAnchor=V(291/512,501/576),elbowOffset=V(-2.25,-101.25),
 forearmAnchor=V(226/512,430/576),wristOffset=V(7.5,-90.25),
 handAnchor=V(260/512,69/448),cupAnchor=V(108/512,206/448)
}
