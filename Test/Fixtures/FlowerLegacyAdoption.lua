-- Restore an actually saved pre-field-gate adoption into a disposable QA copy.
-- This is compatibility setup, not a new adoption or evaluation success.
return function(source)
 local D=require('Dora')
 assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-adoption%-store%-%d+%.db$'))
 local S=require('Training.FlowerAdoptionStore');local saved,why=S.load('ninilite');assert(not saved and why=='NOT_ADOPTED')
 assert(D.DB:exec("ATTACH DATABASE '"..source.."' AS legacy_adoption")>=0)
 assert(D.DB:exec("INSERT INTO lsd.Game0FlowerAdoptions SELECT * FROM legacy_adoption.Game0FlowerAdoptions WHERE id=1 AND learner='ninilite'")>=0)
 assert(D.DB:exec('DETACH DATABASE legacy_adoption')>=0)
 assert(D.DB:exec("UPDATE lsd.Game0FlowerAdoptionState SET current=1 WHERE learner='ninilite'")>=0)
 local deployed,why=S.load('ninilite');assert(not deployed and why=='ENCOUNTER_CHANGED')
 local rows=assert(D.DB:query('SELECT parent,payload FROM lsd.Game0FlowerAdoptions WHERE id=1'))
 local saved=assert(D.json.decode(rows[1][2],32));saved.id=1;saved.parent=rows[1][1]
 return saved
end
