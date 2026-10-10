-- Cold native process, unchanged package bootstrap, copied legally earned profile.
-- No title button emit: actual OS click is required. No gameplay actions are replayed.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=D.Path(root,'Test/default-continue-entry-result.json')
local r={status='RUNNING',stage='prepare-copy',titleClickRequiresOS=true,gameplayOS=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),32)
  assert(prior.status=='PASS' and prior.database:match('^/private/tmp/lsd%-combat%-qa%-[^/]+/save/LingShuQiYuan/lsd%-journey%-%d+%-%d+%.db$'),'Invalid earned opening parent')
  local writable=D.Content.writablePath;local dir=D.Path(writable,'LingShuQiYuan')
  assert(not D.Content:exist(dir)and D.Content:mkdir(dir)and not D.DB:existDB('lsd'))
  local name=D.Path:getFilename(prior.database);r.database=D.Path(dir,name);r.source=prior.database
  assert(D.Content:copyAsync(prior.database,r.database))
  local resources=assert(os.getenv('LSD_QA_DEFAULT_RESOURCES'));assert(not os.getenv('LSD_PACKAGE_QA_ROOT'))
  D.Content.assetPath=resources;local bootstrap=D.Path(resources,'Script/init.lua');r.defaultBootstrap=bootstrap
  assert(load(D.Content:load(bootstrap),'@'..bootstrap))()
  local title=assert(require('Save.Title').current);assert(title.store.directory==dir and title.continue and title.phase=='ready')
  r.stage='actual-continue-click-required';r.titleName=name;save();D.App:saveScreenshot(D.Path(writable,'default-continue-title.tga'))
  local function wait(fn,t,msg)local deadline=D.App.runningTime+t;while not fn()do assert(D.App.runningTime<deadline,msg);D.sleep(.05)end end
  wait(function()return title.selected end,120,'Actual continue click required');assert(title.selected==name);r.titleSelectedTime=D.App.runningTime;r.stage='resuming';save()
  wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='PreparationRoom'and w.data.navigationAttached and D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w and not e.busy end)end,60,'Original academy did not resume')
  local c=require('Data.Config');assert(c.charName==prior.identity.name and c.char==prior.identity.character and (c.tutorialCompleted==1 or c.tutorialCompleted==true))
  local p=require('Training.Progress');assert(p.load()and p.adopted)
  r.model=require('Training.Summary').record(p.adopted);assert(r.model.count==prior.model.count)
  local m=assert(require('Mission.Service').open());assert(m:summary().unlocks['library-lead'])
  local e=require('Economy.Store');assert(e.open()and not e.active()and e.wallet().available==prior.balance)
  local attempts=D.DB:query("SELECT status,report FROM lsd.Game0MissionAttempts WHERE mission='c0-m01'")
  assert(#attempts==1 and attempts[1][1]=='won');local b=D.json.decode(attempts[1][2],32)
  assert(b.economy.cost==prior.battle.economy.cost and b.economy.income==prior.battle.economy.income)
  r.balance=e.wallet().available;r.identity={name=c.charName,character=c.char};r.noRepeatedTutorial=true;r.noDuplicateRewards=true;r.stage='academy-resumed'
  D.App:saveScreenshot(D.Path(writable,'default-continue-academy.tga'));D.sleep(.3)
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save();print('LSD_DEFAULT_CONTINUE_ENTRY_'..r.status)
end)
