local Proof={}
function Proof.validate(p)
 if type(p)~='table' or p.version~=1 or p.rows~=11 or p.stage~=2 or math.abs((p.playerX or 0)-2520)>160 then return false,'ROOF_DIALOGUE_REQUIRED'end
 local b=p.beacon
 if not b or (b.seconds or 0)<1.7 or (b.anchorFrames or 0)<60 or not b.beamVisible or not b.anchor or not b.axis then return false,'ROOF_BEACON_REQUIRED'end
 local dx,dy=b.axis.x-b.anchor.x,b.axis.y-b.anchor.y
 if dx*dx+dy*dy<1 then return false,'ROOF_BEACON_ANCHOR_REQUIRED'end
 return true
end
return Proof
