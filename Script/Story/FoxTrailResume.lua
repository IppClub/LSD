local Resume={}
function Resume.options(facts)
 if not facts.completed['valley-friends'] then return end
 local store,err=require('Story.FoxTrailStore').open();if not store then return nil,err end
 local state,why=store:load();if not state then return nil,why end
 if not state.departed then return end
 if facts.completed['fox-trail-return'] then return {scene='OperationRoom',foxParty=true} end
 return {scene='Factory',foxTrail=true,spawn=facts.completed['fox-trail-scout'] and 4100 or facts.completed['fox-trail-rest'] and 2600 or 600}
end
return Resume
