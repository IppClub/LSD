-- Revalidate the unmodified episode captured by a real public-route encounter.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-captured-evidence-result.json'
local r={status='RUNNING',osInput=false,naturalVictory=false,invalid={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(os.getenv('LSD_QA_CAPTURED_RESULT'));r.source=source
  local original=D.json.decode(D.Content:load(source),64);local episode=assert(original.uncommittedEpisode)
  local F=require('Training.YingzhaoFeatures')
  for index,step in ipairs(episode.boss.steps)do for _,phase in ipairs({'before','after'})do
   local s=step[phase]
   if s and not F.validate(s)then
    r.invalid[#r.invalid+1]={index=index,actor=step.actor,action=step.action,phase=phase,observation=s,
     skillValid=require('Training.YingzhaoSkillFeatures').validate(s),timingValid=require('Training.YingzhaoTiming').validate(s),
     shieldProjection=require('Ground.PhysicalShield').project(s.physicalProtection),
     supportProjection=require('Training.YingzhaoSupportFeatures').project(s.supportState)}
   end
  end end
  r.valid,r.reason=require('Enemy.BigYingzhaoEvidence').validate(episode);save()
  assert(r.valid,r.reason)
  local forged=D.json.decode(D.json.encode(episode),64)
  local obs=forged.boss.steps[1].before
  obs.knownArmor.head={ap=35,observedAt=obs.at+.1};obs.part_head='armored'
  assert(not require('Enemy.BigYingzhaoEvidence').validate(forged),'Future knowledge accepted');r.futureKnowledgeRejected=true
  if original.checks and original.checks.naturalFormalReportAndLedger then
   local db=D.Content.writablePath..'/captured-evidence-cold-'..os.time()..'.db';r.database=db
   assert(original.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/'))
   assert(not D.DB:existDB('lsd')and D.Content:copyAsync(original.database,db))
   assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
   local id=assert(tonumber(episode.episode:match('(%d+)$')))
   local loaded,why=require('Training.CombatStore').load(id);assert(loaded,why)
   assert(require('Training.FlowerIdentity').equal(loaded.boss,episode.boss),'Saved Boss trace differs')
   assert(require('Economy.Store').open());r.coldBalance=require('Economy.Store').wallet().available
   assert(r.coldBalance==original.balanceAfter);r.savedEpisodeColdRead=true
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
