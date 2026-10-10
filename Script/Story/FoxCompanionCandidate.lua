-- Versioned motion candidates for isolated art/motion review.
local Candidate={asset='Image/Companion/fox-chibi-motion-v5.model',height=300}
function Candidate.create(version)
 local asset=version and ('Image/Companion/fox-chibi-motion-'..version..'.model')or Candidate.asset
 local m=require('Story.FoxCompanionRig').create(asset,Candidate.height);m.candidate=true;return m
end
return Candidate
