local P={}
function P.validate(proof)
 if type(proof)~='table' or proof.version~=1 or proof.rows~=12 or type(proof.events)~='table' or #proof.events~=4 then return false,'INTERROGATION_PRESENTATION_REQUIRED'end
 local names={'coverReach','coverRelease','foxWarning','mentorSlap'};local minimum={.54,.39,1.19,.89};local previous=-math.huge
 for i,e in ipairs(proof.events)do
  if e.name~=names[i] or type(e.started)~='number' or type(e.ended)~='number' or type(e.duration)~='number' or e.duration<minimum[i] or e.ended-e.started<e.duration-.04 or e.started<previous then return false,'FULL_INTERROGATION_ACTIONS_REQUIRED'end
  previous=e.ended
 end
 local slap=proof.events[4]
 if (slap.mentor~='charM' and slap.mentor~='charF') or not slap.impact or slap.impact-slap.started<.30 or slap.impact-slap.started>.40 or not slap.fallEnded or not slap.fallDuration or slap.fallDuration<1.34 or slap.fallEnded-slap.impact<slap.fallDuration-.04 then return false,'FULL_INTERROGATION_FALL_REQUIRED'end
 return true
end
return P
