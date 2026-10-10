local Proof={}
function Proof.validate(p)
 if type(p)~='table'or p.version~=1 or p.rows~=12 or type(p.playerX)~='number'or p.playerX~=p.playerX or math.abs(p.playerX-3760)>=180 or not p.barrierWasSolid or not p.barrierRemoved or not p.wardActive or not p.twinsProtected then return false,'JADE_ARRIVAL_REQUIRED'end
 if type(p.openSeconds)~='number'or p.openSeconds~=p.openSeconds or p.openSeconds<1.2 or p.openSeconds>10 then return false,'JADE_PASSAGE_REQUIRED'end
 return true
end
return Proof
