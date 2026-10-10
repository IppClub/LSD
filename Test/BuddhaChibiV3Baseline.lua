-- Chibi rig registered to the six visible torso sockets.
local V=require('Dora').Vec2
return {
 texture='Image/Rescue/buddha-guard-chibi.png',rowHeight=576,
 handPoint=V(310,210),torsoY=40,torsoScale=.65,haloScale=.85,haloY=80,
 shoulders={[-1]={V(69,68),V(104,0),V(68,-98)},[1]={V(103,46),V(123,0),V(125,-91)}},
 shoulderAngles={[-1]={-140,-75,-10},[1]={-140,-75,-1}},
 upperAnchor=V(291/512,501/576),elbowOffset=V(-2.25,-101.25),
 forearmAnchor=V(226/512,430/576),wristOffset=V(7.5,-90.25),
 handAnchor=V(260/512,69/448),cupAnchor=V(108/512,206/448)
}
