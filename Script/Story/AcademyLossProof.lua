local Proof={}
function Proof.validate(p)
 if type(p)~='table'or p.version~=1 or p.rows~=8 or p.scene~='PassageA'or not p.damageVisible or type(p.impactSeconds)~='number'or p.impactSeconds~=p.impactSeconds or p.impactSeconds<1.2 or p.impactSeconds>10 or type(p.roster)~='table'or #p.roster<3 then return false,'ACADEMY_LOSS_REQUIRED'end
 local seen={};for _,r in ipairs(p.roster)do if type(r)~='table'or type(r.role)~='string'or seen[r.role]or type(r.name)~='string'or type(r.detail)~='string'then return false,'INVALID_RESIDENT_RECORD'end;seen[r.role]=true end
 return true
end
return Proof
