local Proof={}
function Proof.validate(p)
 if type(p)~='table' or p.version~=1 or p.rows~=29 or p.researchers~=3 or not p.doorOpen or (p.playerX or 0)<2150 then return false,'CONTROL_POD_DIALOGUE_REQUIRED'end
 if not p.aim or (p.aim.seconds or 0)<.8 or not p.aim.mentor or not p.aim.nini or p.aim.gunCount~=2 or p.aim.heldPose~='aim' or p.aim.nativeAimFrames~=2 then return false,'CONTROL_POD_AIM_REQUIRED'end
 if not p.warning or (p.warning.seconds or 0)<1.2 or not p.warning.teethExpression or (p.warning.anchorFrames or 0)<30 then return false,'CONTROL_POD_WARNING_REQUIRED'end
 return true
end
return Proof
