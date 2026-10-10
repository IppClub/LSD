-- Copy only the save earned by fresh opening, public training and formal battle.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-opening-academy-resume-result.json';local r={status='RUNNING',osInput=false,stage='continue-click-required'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/fresh-opening-academy-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/lsd%-fresh%-opening%-academy%-qa%-%d+/lsd%-journey%-%d+%-%d+%.db$'))
  local directory=D.Content.writablePath..'/fresh-opening-resume-'..os.time();assert(D.Content:mkdir(directory))
  local name=D.Path:getFilename(prior.database);local db=directory..'/'..name;assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));r.database=db;r.source=prior.database
  local title=require('Save.Title').open({store=require('Save.Slots').new(directory)});assert(title.continue,'Normal title did not find copied journey');save()
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Fresh journey continue stalled');D.sleep(.03)end end
  wait(function()return title.selected end,120);assert(title.selected==name);r.stage='resuming';save()
  wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='PreparationRoom'and w.data.navigationAttached end,45)
  local C=require('Data.Config');assert(C.charName==prior.identity.name and C.char==prior.identity.character and (C.tutorialCompleted==true or C.tutorialCompleted==1))
  local P=require('Training.Progress');assert(P.load()and P.adopted);assert(require('Training.Summary').record(P.adopted).count==prior.model.count)
  local M=assert(require('Mission.Service').open());assert(M:summary().unlocks['library-lead'])
  local E=require('Economy.Store');assert(E.open()and E.wallet().available==prior.balance and not E.active());r.balance=E.wallet().available
  local rows=D.DB:query("SELECT status,report FROM lsd.Game0MissionAttempts WHERE mission='c0-m01'");assert(#rows==1 and rows[1][1]=='won')
  local battle=D.json.decode(rows[1][2],32);assert(battle.economy.cost==prior.battle.economy.cost and battle.economy.income==prior.battle.economy.income)
  r.identity={name=C.charName,character=C.char};r.model=require('Training.Summary').record(P.adopted);r.noRepeatedTutorial=true;r.noDuplicateRewards=true;r.stage='academy-resumed'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FRESH_OPENING_ACADEMY_RESUME_'..r.status)
end)
