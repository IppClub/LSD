local Proof={}
function Proof.validate(p)
 if type(p)~='table'or p.version~=1 or p.rows~=8 or type(p.playerX)~='number'or p.playerX~=p.playerX or math.abs(p.playerX-4650)>=180 or p.wardClosed~=true or p.twinsAtExit~=true then return false,'JADE_DISTANCE_REQUIRED'end
 return true
end
return Proof
