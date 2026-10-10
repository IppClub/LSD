-- Run only after TrainingSoak is terminal. Runtime modules/assets come from stage.
local D=require('Dora');local sourceRoot=D.Path:getPath(D.Path:getScriptPath(...))
local soak=package.loaded['_lsd_training_soak_state'];assert(not soak or soak.status~='RUNNING','Do not interrupt the active soak')
local stage=assert(D.Content:load(D.Path(sourceRoot,'Test/runtime-stage-path.txt'))):match('^%s*(.-)%s*$')
assert(stage:match('^/private/tmp/lsd%-game0%-stage%-[%w%-]+$'),'Expected isolated runtime stage')
local out=D.Path(sourceRoot,'Test/staged-cold-continue-result.json')
local report={status='RUNNING',runId=os.time(),stage=stage,osInput=true,coldProcess=false,requiresExternalProcessEvidence=true}
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local oldPaths,oldWritable=D.Content.searchPaths,D.Content.writablePath
 local restored=false
 local function restore()
  if restored then return end;restored=true
  if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end
  D.Content.searchPaths=oldPaths;D.Content.writablePath=oldWritable
 end
 D.Director.entry:slot('Cleanup',restore)
 local ok,why=xpcall(function()
  assert(not D.DB:existDB('lsd'))
  local source=assert(D.Content:load(D.Path(sourceRoot,'Test/save-opening-resume-fixture.txt')))
  assert(D.Path:getPath(source):match('lsd%-title%-opening%-qa%-%d+$'))
  local directory='/private/tmp/lsd-stage-save-'..report.runId;assert(not D.Content:exist(directory)and D.Content:mkdir(directory))
  assert(D.Content:copyAsync(source,D.Path(directory,'lsd.db')));report.database=D.Path(directory,'lsd.db')
  local manifest=assert(D.json.decode(D.Content:load(D.Path(stage,'runtime-manifest.json')),128))
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();D.Cache:unload()
  for _,item in ipairs(manifest.files)do
   if item.path:sub(-4)=='.lua'then
    local module=item.path:sub(1,-5):gsub('/','.');package.loaded[module]=nil
    if module:sub(1,7)=='Script.'then package.loaded[module:sub(8)]=nil end
   end
  end
  D.Content.writablePath=directory
  D.Content.searchPaths={stage,D.Path(stage,'Script'),D.Path(stage,'Spine'),D.Path(stage,'Image'),D.Path(stage,'Font'),D.Path(D.Content.assetPath,'Script'),D.Path(D.Content.assetPath,'Script/Lib')}
  for _,path in ipairs({'Script/Save/Title.lua','Script/Start.lua','Spine/StoryActions/researcher.skel','Image/Rescue/buddha-guard-chibi.png','Spine/StoryActions/yu-riding.json','Script/Rescue/BuddhaChibiStyle.lua','Script/Story/Dialog/companion-ninilite-first-training.yarn'})do
   assert(D.Content:getFullPath(path)==D.Path(stage,path),'Fallback outside stage: '..path)
  end
  assert(not D.Content:exist('Docs/artwork/researcher/export/actions.skel'))
  local entry=assert(load(D.Content:load(D.Path(stage,'init.lua')),'@'..D.Path(stage,'init.lua')))
  entry(D.Path(stage,'init'))
  local title=assert(require('Save.Title').current);assert(title.continue and title.store.directory==directory)
  local clickDeadline=D.App.runningTime+120
  while not title.selected do assert(D.App.runningTime<clickDeadline,'Native continue click required');D.sleep(.05)end
  local deadline=D.App.runningTime+40
  while true do
   local w=D.Platformer.Data.store.world
   if w and w.tag=='PreparationRoom'and w.data.navigationAttached then
    local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
    if p and not p.busy then break end
   end
   assert(D.App.runningTime<deadline,'Staged continue failed');D.sleep(.04)
  end
  local config=require('Data.Config');assert(config.charName=='JourneyQA'and config.char=='charF'and config.skipOP==1)
  local holder=D.Node();holder.x=-5000;holder:addTo(D.Director.ui3D)
  local carrier=require('Rescue.BuddhaCarrier').new(holder,0,0,'Spine/StoryActions/yu-riding.json|Spine/yu.atlas',require('Rescue.BuddhaChibiStyle'))
  assert(carrier:mountAsync());D.sleep(.2);assert(carrier:landAsync());assert(carrier.phase=='ground')
  report.carrierEvents=carrier.events;carrier:dispose();D.sleep(.05)
  report.interrogation={}
  for _,gender in ipairs({'charM','charF'})do
   local pair=require('Factory.InterrogationActors').new(holder);pair:addCompanions(gender)
   assert(pair:coverAsync());assert(pair:releaseAsync());assert(pair:warnAsync());assert(pair:slapAsync())
   assert(pair.phase=='unconscious' and #pair.events==4)
   report.interrogation[#report.interrogation+1]={gender=gender,events=pair.events};pair.node:removeFromParent();D.sleep(.05)
  end
  holder:removeFromParent()
  report.status='PASS';report.academyResumed=true;report.runtimeSearchPaths=D.Content.searchPaths;report.developmentResourcesAbsent=true
  D.App:saveScreenshot(D.Path(sourceRoot,'Docs/evidence/2026-10-04/staged-cold-continue-d.tga'))
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why;restore()end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
