local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/spatial-evidence-read-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-reaction-migration-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-reaction%-migration%-%d+%.db$'))
  local dest=D.Content.writablePath..'/spatial-evidence-read-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local row=D.DB:query('SELECT payload FROM lsd.Game0FlowerQTrials ORDER BY id DESC LIMIT 1')[1]
  local episode=D.json.decode(row[1],32).episode;local S=require('Training.CombatStore')
  local valid,why=S.validate(episode);assert(valid,why);assert(#episode.steps==prior.spatialDecisions and #episode.movement==prior.forcedEvents)
  local function copy()return D.json.decode(D.json.encode(episode,false,true),32)end
  local e=copy();e.steps[1].observation.spatial=nil;assert(not S.validate(e))
  e=copy();e.steps[1].observation.spatial.boss.distance=-1;assert(not S.validate(e))
  e=copy();e.movement[1].origin='demo';assert(not S.validate(e))
  e=copy();e.movement[1].at=-1;assert(not S.validate(e))
  e=copy();e.versions.spatial=1;assert(not S.validate(e),'Spatial version mismatch accepted')
  e=copy();for _,step in ipairs(e.steps)do if step.observation.spatial.firearm then step.observation.spatial.firearm.hullDistance=-1;break end end;assert(not S.validate(e))
  r.missingRejected=true;r.invalidDistancesRejected=true;r.forcedOriginProtected=true;r.timeRejected=true;r.decisions=#episode.steps;r.events=#episode.movement
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
