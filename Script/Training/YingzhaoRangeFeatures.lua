-- Present visible geometry only. Outside this corridor is not globally safe:
-- waves, summons, reentry and future movement remain separate observations.
local T=require('Enemy.BigYingzhaoTimeline')
local R={names={'bossFrontRange'},categories={bossFrontRange='unknown rear vertical immediate advance outside'}}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function R.capture(owner,boss,visible)
 if not visible then return {schemaVersion=1,present=false}end
 return {schemaVersion=1,present=true,ownX=owner.x,ownY=owner.y,bossX=boss.x,bossY=boss.y,faceRight=boss.faceRight}
end
function R.project(raw)
 if type(raw)~='table'or raw.schemaVersion~=1 or type(raw.present)~='boolean'then return end
 if not raw.present then
  if raw.ownX~=nil or raw.ownY~=nil or raw.bossX~=nil or raw.bossY~=nil or raw.faceRight~=nil then return end
  return {bossFrontRange='unknown'}
 end
 if not finite(raw.ownX)or not finite(raw.ownY)or not finite(raw.bossX)or not finite(raw.bossY)or type(raw.faceRight)~='boolean'then return end
 local dx=(raw.ownX-raw.bossX)*(raw.faceRight and 1 or -1)
 local motion=T.massiveMotion;local reach=T.meleeReach+motion.speed*(motion.finish-motion.start)
 return {bossFrontRange=dx<0 and'rear'or math.abs(raw.ownY-raw.bossY)>T.meleeVerticalReach and'vertical'or dx<=T.meleeReach and'immediate'or dx<=reach and'advance'or'outside'}
end
function R.validate(s)
 local raw=s.bossRange;local state=R.project(raw)
 if not state or state.bossFrontRange~=s.bossFrontRange or raw.present~=s.bossVisible then return false end
 if not finite(s.ownY)then return false end
 if raw.present and(raw.ownX~=s.ownX or raw.ownY~=s.ownY or raw.bossX~=s.bossX or raw.bossY~=s.bossY or raw.faceRight~=s.bossFaceRight)then return false end
 if not raw.present and(s.bossY~=nil or s.bossFaceRight~=nil)then return false end
 return true
end
return R
