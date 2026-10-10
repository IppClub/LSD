-- One complete revolution per floor. Front/rear depth follows the same path as the treads.
local G={floors=7,rise=620,base=160,center=1020,radius=500,duration=6,steps=32,doorX=1740}
function G.point(progress)
 local angle=math.pi+progress*math.pi*2
 local depth=math.sin(angle)
 return G.center+G.radius*math.cos(angle),G.base+progress*G.rise+45*depth,depth
end
function G.floorY(floor)return G.base+(floor-1)*G.rise end
return G
