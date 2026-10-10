-- Separate actor profiles; authored combat effects are extended per actor.
local Characters={
 ninilite={id="ninilite",name="妮妮莉特",actions={"laser","fmove","bmove","idle"},tableSuffix=""},
 wuyun={id="wuyun",name="乌云",actions={"melee","laser","fmove","bmove","idle"},tableSuffix="_wuyun",requiresStory="energy-plan"},
}
for _,c in pairs(Characters) do c.legal={}; for _,action in ipairs(c.actions) do c.legal[action]=true end end
return Characters
