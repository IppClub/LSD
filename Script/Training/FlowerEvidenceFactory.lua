-- Preserve the exact source episodes independently of the rolling practice log.
-- Native rebuilding binds declarative rules to these inputs before a new save.
return function(resourceMode)
local E={maxBytes=33554432};local P=require(resourceMode and 'Training.ResourcePolicy' or 'Training.FlowerPolicy');local equal=require('Training.FlowerIdentity').equal
local function array(t,limit)
 if type(t)~='table' or #t<1 or #t>limit then return false end
 local n=0;for k in pairs(t)do if type(k)~='number' or k%1~=0 or k<1 or k>#t then return false end;n=n+1 end;return n==#t
end
function E.validate(e,actor)
 if type(e)~='table' or e.schemaVersion~=1 or (resourceMode and e.builder~='flower-resource-c45-v1' or not resourceMode and e.builder~='flower-c45-v1' and e.builder~='flower-c45-v2') or not array(e.episodes,20) then return false,'INVALID_EVIDENCE'end
 local ok,why=P.validate(e.policy,actor);if not ok then return false,why end
 if e.builder~=(resourceMode and 'flower-resource-c45-v1' or e.policy.featureSchemaVersion==7 and 'flower-c45-v2'or'flower-c45-v1')then return false,'BUILDER_VERSION_MISMATCH'end
 if #e.episodes~=#e.policy.sourceEpisodes then return false,'SOURCE_COUNT_MISMATCH'end
 local seen={}
 for i,episode in ipairs(e.episodes)do
  if type(episode)~='table' or seen[episode.episode] or episode.episode~=e.policy.sourceEpisodes[i]then return false,'SOURCE_ID_MISMATCH'end
  seen[episode.episode]=true
 end
 local data,why=P.collect(e.episodes,e.policy.characterId,e.policy.featureSchemaVersion);if not data then return false,why end
 if #data.samples~=e.policy.sampleCount or not equal(data.sources,e.policy.sourceEpisodes)then return false,'SAMPLE_COUNT_MISMATCH'end
 return true
end
function E.make(policy,history)
 local ok,why=P.validate(policy);if not ok then return nil,why end
 if type(history)~='table'then return nil,'MISSING_SOURCES'end
 local byId={}
 for _,episode in ipairs(history)do
  if type(episode)~='table' or type(episode.episode)~='string' or byId[episode.episode]then return nil,'INVALID_SOURCE_HISTORY'end
  byId[episode.episode]=episode
 end
 local episodes={};for _,id in ipairs(policy.sourceEpisodes)do if not byId[id]then return nil,'MISSING_SOURCE_EPISODE'end;episodes[#episodes+1]=byId[id]end
 local e={schemaVersion=1,builder=resourceMode and 'flower-resource-c45-v1' or policy.featureSchemaVersion==7 and 'flower-c45-v2'or'flower-c45-v1',policy=policy,episodes=episodes}
 local ok,why=E.validate(e);if not ok then return nil,why end
 return e
end
function E.verifyAsync(e,actor)
 local ok,why=E.validate(e,actor);if not ok then return false,why end
 local rebuilt,why=P.buildAsync(e.episodes,e.policy.characterId,e.policy.featureSchemaVersion);if not rebuilt then return false,why end
 if rebuilt.actionSetVersion~=e.policy.actionSetVersion or not equal(rebuilt.rules,e.policy.rules) or not equal(rebuilt.sourceEpisodes,e.policy.sourceEpisodes) or rebuilt.sampleCount~=e.policy.sampleCount or math.abs(rebuilt.trainingAccuracy-e.policy.trainingAccuracy)>1e-8 then return false,'REBUILD_MISMATCH'end
 return true
end
return E
end
