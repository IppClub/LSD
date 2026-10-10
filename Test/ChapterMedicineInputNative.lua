-- Production chapter HUD/buttons and real saved medicine inventory.
-- Controlled health, paused battle update and simulated lifecycle events;
-- no physical input, mission-entry, costs, victory or leak acceptance claim.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/chapter-medicine-input-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local permanent=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_MEDICINE_PARENT_RESULT'))),32)
  local empty=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_EMPTY_MEDICINE_PARENT_RESULT'))),32)
  assert(permanent.status=='PASS'and empty.status=='PASS')
  local function wait(fn)local limit=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<limit,'Chapter medicine fixture timeout');D.sleep(.02)end end
  for _,spec in ipairs({{'defense','Academy.DefenseLevel'},{'rescue','Rescue.Level'},{'final','Final.Level'},{'final-emergency','Final.Level'}})do
   for _,input in ipairs({'keyboard','touch'})do
    local source=spec[1]=='final-emergency'and empty.database or permanent.database
    assert(source:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-.+%.db$'))
    local db=D.Content.writablePath..'/chapter-medicine-'..spec[1]..'-'..input..'-'..os.time()..'.db'
    assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,db))
    assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
    local P=require('Training.Progress');assert(P.load()and P.adopted)
    local S=require('Story.Supplies');local count=S.count('mentor','first-aid-water')
    assert(count==(spec[1]=='final-emergency'and 0 or 1),'Unexpected actual saved medicine stock')
    local c
    if spec[2]=='Final.Level'then c=require(spec[2]).openAsync({ninilite=P.adopted},'mobility',function()return true end)
    else c=require(spec[2]).openAsync({ninilite=P.adopted},function()return true end)end
    local b=c.battle;b.update=function()return false end
    local item={chapter=spec[1],input=input,database=db,parentDatabase=source,stockBefore=count,cases={}}
    r.cases[#r.cases+1]=item;save()
    local function use()
     if input=='keyboard'then c.hud:emit('KeyDown','H')else c.medicine:emit('TapBegan')end
    end
    c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
    b.mentorHP=50
    local uses=b.medicineUses;local emergency=b.emergencyRemaining
    local function unchanged(label)
     use();D.sleep(.15)
     assert(b.mentorHP==50 and b.medicineUses==uses and b.emergencyRemaining==emergency and S.count('mentor','first-aid-water')==count,label..' consumed medicine')
     item.cases[#item.cases+1]=label;save()
    end
    D.emit('AppEvent','WindowFocusLost');unchanged('focus-loss')
    D.emit('AppEvent','WindowHidden');D.emit('AppEvent','WindowFocusGained');unchanged('focus-gain-still-hidden')
    D.emit('AppEvent','WindowShown');D.emit('AppEvent','WillEnterBackground');unchanged('background')
    D.emit('AppEvent','DidEnterForeground');c.controls.visible=false;unchanged('hidden-controls');c.controls.visible=true
    D.emit('Story.Display',true);unchanged('story-hidden-hud');D.emit('Story.Display',false)
    D.sleep(.2);assert(b.mentorHP==50 and S.count('mentor','first-aid-water')==count,'Return replayed stale medicine request')
    -- A contact may reduce HP to zero before the next battle update switches
    -- to settlement. A queued/new H or touch must not spend medicine then.
    b.mentorHP=0;use();wait(function()return not b.medicineBusy end)
    assert(b.mentorHP==0 and b.medicineUses==uses and b.emergencyRemaining==emergency and S.count('mentor','first-aid-water')==count,'Zero-health mentor consumed medicine before settlement')
    item.zeroHealthRejected=true;b.mentorHP=50
    use();wait(function()return not b.medicineBusy end)
    assert(b.mentorHP==75,'Fresh chapter medicine did not heal exactly 25')
    if spec[1]=='final-emergency'then
     assert(b.emergencyUsed==1 and b.emergencyRemaining==0 and b.medicineUses==uses and S.count('mentor','first-aid-water')==0,'Emergency medicine changed permanent stock')
    else assert(b.medicineUses==uses+1 and S.count('mentor','first-aid-water')==count-1,'Permanent medicine not consumed exactly once')end
    item.stockAfter=S.count('mentor','first-aid-water');item.hpAfter=b.mentorHP;item.medicineUses=b.medicineUses;item.emergencyUsed=b.emergencyUsed
    use();wait(function()return not b.medicineBusy end);assert(b.mentorHP==75 and S.count('mentor','first-aid-water')==item.stockAfter,'Empty inventory healed or consumed extra stock')
    item.freshInput=true;item.noReplay=true;item.emptyInventorySafe=true;save()
    b:finish('aborted','Controlled chapter medicine input test');wait(function()return c.phase=='result'end)
    assert(c.result.resultLayout=='MissionFail');item.dedicatedFailureLayout=true
    D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();D.sleep(.5)
    assert(D.DB:exec('DETACH DATABASE lsd')>=0);collectgarbage('collect')
   end
  end
  r.scope='Actual three chapter medicine buttons and H handlers; copies of earned saves, controlled HP/update and simulated events. No mission entry/bill or actual OS focus claim.'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
