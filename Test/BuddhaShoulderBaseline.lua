-- Historical pre-socket registration retained for visual comparison.
local V=require('Dora').Vec2
return {
 texture='Image/Rescue/buddha-guard-chibi.png',rowHeight=576,
 handPoint=V(310,210),torsoY=40,torsoScale=.65,haloScale=.85,haloY=80,
 shoulders={[-1]={V(45,35),V(70,5),V(45,-50)},[1]={V(75,35),V(115,5),V(75,-50)}},
 upperAnchor=V(278/512,473/576),elbowOffset=V(4.5,-95.5),
 forearmAnchor=V(226/512,430/576),wristOffset=V(7.5,-90.25),
 handAnchor=V(260/512,69/448),cupAnchor=V(108/512,206/448)
}
