local F=dofile('Script/Combat/Formation.lua')
local function actor(id,x,hp)return {character={id=id},student={x=x},studentHP=hp or 100}end
assert(F.duration({ninilite=500},{actor('ninilite',500)})==3)
assert(F.duration({ninilite=200},{actor('ninilite',2000)})==12)
assert(F.duration({ninilite=200},{actor('ninilite',2000,0)})==3)
local duration=F.duration({ninilite=200},{actor('ninilite',920)})
assert(duration>3 and duration<12 and duration*120>720-F.tolerance)
assert(F.duration({ninilite=200,wuyun=500},{actor('ninilite',920),actor('wuyun',500)})==duration)
print('FormationDuration PASS nearMinimum=true distantBounded=true halfSpeedBudget=true defeatedIgnored=true longestRole=true')
