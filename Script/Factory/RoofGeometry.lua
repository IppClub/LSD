local G={base=160,stairY=620,top=1070,stairX=350,stairEnd=1000,wallX=1280,climbX=1240,landingX=1700,stairsSeconds=6,width=3900}
function G.stairPoint(t)t=math.max(0,math.min(1,t));return G.stairX+(G.stairEnd-G.stairX)*t,G.base+(G.stairY-G.base)*t end
function G.floorY(stage)return stage==2 and G.top or stage==1 and G.stairY or G.base end
return G
