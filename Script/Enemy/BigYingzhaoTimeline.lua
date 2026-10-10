-- Native pose review 2026-10-06. Never shorten the authored recovery tail.
-- punch: both axes descend together at 1.20s; one paired area hit.
-- massive: first downward cut .50s, opposite cut .90s, paired finish 1.70s.
local T={meleeReach=360,meleeVerticalReach=330,massiveMotion={start=.3,finish=1.8,speed=320}}
function T.stages(skill)
 -- hunt: the pointing arm is extended by .80s; summon after the visible cue.
 if skill=='hero'then return {{name='hero'},{name='hero2',impacts={.5}},{name='hero2',impacts={.5}},{name='hero2',impacts={.5}},{name='hero3',impacts={.65}}}end
 if skill=='hunt'then return {{name='hunt',impacts={.8}}}end
 if skill=='wave'then return {{name='wave',impacts={2.3}}}end
 if skill=='punch'then return {{name='punch',impacts={1.2}}}end
 if skill=='massive'then return {{name='massive',impacts={.5,.9,1.7}}}end
 error('Unimplemented big Yingzhao skill: '..tostring(skill))
end
return T
