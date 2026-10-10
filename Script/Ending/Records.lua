-- Read earned facts; never award missions or reconstruct historical training.
local D=require('Dora');local Records={}
local function decode(s)
 if type(s)~='string'or #s>1048576 then return nil end
 local ok,value=pcall(D.json.decode,s,32);return ok and type(value)=='table'and value or nil
end
function Records.read()
 local story,why=require('Story.Service').open();if not story then return nil,why end
 local facts,why=story:summary();if not facts then return nil,why end
 if not facts.completed['final-betrayal']or not facts.unlocks['final-story-complete']then return nil,'ENDING_LOCKED'end
 local rows=D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='final-betrayal'")
 local proof=rows and rows[1]and decode(rows[1][1]);if not proof or not require('Final.BetrayalProof').validate(proof)then return nil,'INVALID_FINAL_STORY'end
 rows=D.DB:query("SELECT a.id,a.model,a.report FROM lsd.Game0MissionUnlocks u JOIN lsd.Game0MissionAttempts a ON a.id=u.attempt AND a.mission=u.mission WHERE u.id='last-promise-complete' AND a.mission='c0-m09' AND a.status='won'")
 if not rows or not rows[1]then return nil,'EVACUATION_RECORD_REQUIRED'end
 local row=rows[1];local model,p=decode(row[2]),decode(row[3])
 if not model or not require('Training.Model').validate(model.ninilite,'ninilite',require('Training.Characters').ninilite.legal)or not p or not require('Final.Proof').validate(p,model.ninilite,model.auxiliaryVariant)then return nil,'INVALID_EVACUATION_RECORD'end
 local roster,why=require('Story.AcademyLossRecords').current();if not roster then return nil,why end
 local store,why=require('Training.Store').open(nil,'ninilite');if not store then return nil,why end
 local training,why=store:load();if not training or store.writeBlocked then return nil,why or 'TRAINING_READ_FAILED'end
 local won=D.DB:query("SELECT mission,COUNT(*),MIN(id) FROM lsd.Game0MissionAttempts WHERE status='won' GROUP BY mission ORDER BY MIN(id)")
 if not won then return nil,'READ_FAILED'end
 local missions={};local catalog=require('Mission.Catalog')
 for _,r in ipairs(won)do local item=catalog[r[1]];if not item then return nil,'UNKNOWN_COMPLETED_MISSION'end;missions[#missions+1]={id=r[1],title=item.title,chapter=item.chapter,wins=r[2],firstAttempt=r[3]}end
 return {version=1,finalAttempt=row[1],evacuation=p,finalModel=model.ninilite,auxiliaryVariant=model.auxiliaryVariant,currentModel=training.adopted,currentRevision=training.revision,trainingStatus=why,missions=missions,roster=roster,story=proof}
end
return Records
