-- Historical evidence is readable; active deployment requires current mechanics.
local R={hitReaction=2}
function R.current(setup)
 return type(setup)=='table' and setup.hitReaction==R.hitReaction and setup.bossScale==1
  and setup.aimPolicy==require('Factory.PartCombat').aimPolicy
end
function R.validReaction(setup,episode)
 local v=setup and setup.hitReaction
 return (v==nil or v==2) and type(episode)=='table' and type(episode.versions)=='table' and episode.versions.hitReaction==v
end
function R.qCurrent(bundle)
 if type(bundle)~='table' or bundle.hitReaction~=R.hitReaction or bundle.qFeatureVersion~=7 then return false end
 local profiles=bundle.assessment and bundle.assessment.review and bundle.assessment.review.profiles
 if not profiles then return false end
 for _,id in ipairs({'near','far','reproduction','field'})do if not profiles[id] or not R.current(profiles[id].setup) or profiles[id].setup.qFeatureVersion~=7 then return false end end
 return true
end
return R
