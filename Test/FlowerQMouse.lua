-- Only sets up an isolated fixture and observes; no synthetic button events.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-mouse-result.json';local r={status='RUNNING',input='external-mouse'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-repeated-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-repeated%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-mouse-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local S=require('Training.FlowerQAdoptionStore');assert(S.currentId()==0)
  local initial=require('Training.FlowerPractice').openAsync(nil,'wuyun');r.ready=true;save()
  local endAt=D.App.totalTime+1200
  while D.App.totalTime<endAt do
   local q=D.Director.ui3D:getChildByTag('flower-q-controls');local view=D.Director.ui3D:getChildByTag('flower-q-adoption-controls')
   if q then r.enteredQ=true end
   if view then r.enteredAdoption=true;local p=view.panel;r.page=p.page;r.busy=p.busy;r.confirming=p.confirming;r.message=p.message
    if p.confirming=='adopt'then r.sawAdoptConfirmation=true end
    if p.confirming=='rollback'then r.sawRollbackConfirmation=true end
   end
   local current=S.currentId();if current and current>0 then r.adopted=current end
   if r.adopted and current==0 then r.rolledBack=true end
   local practice=D.Director.ui3D:getChildByTag('flower-practice-controls')
   if r.rolledBack and not view and practice and practice.practice~=initial and practice.practice.characterId=='wuyun' and practice.practice.hud.visible and practice.practice.arena.demoInputAvailable() and not q then r.returnedToWuyun=true;break end
   save();D.sleep(.2)
  end
  assert(r.enteredQ and r.enteredAdoption and r.sawAdoptConfirmation and r.adopted and r.sawRollbackConfirmation and r.rolledBack and r.returnedToWuyun,'Mouse path incomplete')
  assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==1);r.historyRetained=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
