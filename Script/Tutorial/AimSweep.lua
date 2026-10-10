-- Shared tutorial/combat hold gesture: fast first sweep, then precision aim.
-- The curve is time based and continuous; no target data or hit assistance.
local S={fastPeriod=1,precisionPeriod=6,precisionAfter=1}
function S.angle(elapsed)
 elapsed=math.max(0,elapsed)
 local precise=elapsed>=S.precisionAfter
 local period=precise and S.precisionPeriod or S.fastPeriod
 local phase=(precise and elapsed-S.precisionAfter or elapsed)%period
 local speed=180/period
 if phase<=period/2 then return 45-phase*speed,precise end
 return -45+(phase-period/2)*speed,precise
end
return S
