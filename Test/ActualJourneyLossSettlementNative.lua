-- Reopen the actual earned material report through the production result adapter.
-- UI-only replay, isolated copy, no combat outcome/resource/model injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/actual-journey-loss-settlement-result.json'
local r={status='RUNNING',osInput=false,uiOnly=true,combatReplayed=false,sizes={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(os.getenv('LSD_QA_PARENT_RESULT'))
  assert(source=='/private/tmp/lsd-battle-feedback-full-journey-20261009/fresh-materials-current/result.json','Use this frozen journey actual material outcome')
  local original=assert(D.Content:load(source));local parent=assert(D.json.decode(original,256))
  assert(parent.status=='PASS'and parent.osInput==false and parent.sameJourney)
  local db=assert(parent.database);assert(db:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-materials%-current%-%d+%.db$'))
  local copy=D.Path(D.Content.writablePath,'actual-loss-result-'..os.time()..'.db')
  assert(not D.DB:existDB('lsd')and not D.Content:exist(copy)and D.Content:copyAsync(db,copy))
  assert(D.DB:exec("ATTACH DATABASE '"..copy.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local function snapshot()
   local tables=D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' ORDER BY name")
   local data={}
   for _,row in ipairs(tables)do local name=row[1];data[name]=D.DB:query('SELECT * FROM lsd."'..name:gsub('"','""')..'" ORDER BY rowid')end
   return D.json.encode(data,false,true),#tables
  end
  local before,tables=snapshot();local equal=require('Training.FlowerIdentity').equal
  local expected=assert(parent.battle.economy);assert(expected.status=='won'and expected.net<0 and expected.income>0)
  local report,attempt
  for _,row in ipairs(D.DB:query('SELECT id,status,report FROM lsd.Game0MissionAttempts ORDER BY id'))do
   local value=assert(D.json.decode(row[3],256))
   if row[2]=='won'and equal(value.economy,expected)then assert(not report,'Ambiguous actual bill');report=value;attempt=row[1]end
  end
  assert(report and report.reason and report.evaluation)
  local bill=D.DB:query('SELECT status,payload FROM lsd.Game0SupplyAttempts WHERE id=?',{string.format('mission:%d',attempt)})[1]
  assert(bill and bill[1]=='won'and equal(D.json.decode(bill[2],256).result,expected))
  local wallet=D.DB:query('SELECT available FROM lsd.Game0SupplyWallet')[1][1]
  assert(wallet==parent.balance and wallet==expected.balanceAfter)
  r.source=source;r.sourceDatabase=db;r.database=copy;r.attempt=attempt;r.economy=expected;r.wallet=wallet;r.tables=tables;save()
  local adapter=require('Factory.ResultView');adapter.prepareAsync()
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.25)
   local view=adapter.create({phase='won',report=report,reason=report.reason})
   view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.3)
   assert(view.resultLayout=='Settlement'and not view.failureReasonLabel,'Winning loss bill entered failure artwork')
   assert(view.economyLabel.text:find('（亏损）',1,true)and view.economyLabel.text:find(string.format('净收益  %+d',expected.net),1,true))
   assert(view.economyLabel.text:find(string.format('实际成本  -%d',expected.cost),1,true)and view.economyLabel.text:find(string.format('结余物资  %d',wallet),1,true))
   assert(equal(view.economy,expected)and view.againButton and view.baseButton)
   assert(view.resultHeading.text=='沼泽道路已清理'and view.resultHeading.width*view.resultHeading.scaleX<=940.01)
   local width=math.floor(D.App.bufferSize.width);local top=D.Path(D.Content.writablePath,'actual-loss-'..width..'-top.tga')
   D.App:saveScreenshot(top);D.sleep(.15)
   assert(view.economyArea.viewSize.height>view.economyArea.height,'Full actual consumption details cannot scroll')
   view.economyArea:scrollToPosY(-10000,0);D.sleep(.2)
   local bottom=D.Path(D.Content.writablePath,'actual-loss-'..width..'-bottom.tga');D.App:saveScreenshot(bottom);D.sleep(.15)
   assert(view.reportLabel.text:find(report.reason,1,true))
   local again,base=0,0
   view.againButton:slot('Tapped',function()again=again+1 end);view.baseButton:slot('Tapped',function()base=base+1 end)
   view.againButton:emit('Tapped');view.baseButton:emit('Tapped');assert(again==1 and base==1)
   r.sizes[#r.sizes+1]={width=width,height=D.App.bufferSize.height,layout=view.resultLayout,top=top,bottom=bottom,actualNet=expected.net,actualBillExactlyPreserved=true,buttonsDispatched=true};save()
   view:removeFromParent();D.sleep(.1)
   assert(snapshot()==before,'Settlement UI changed actual copied tables')
  end
  assert(D.Content:load(source)==original)
  r.allCopiedTablesUnchanged=true;r.sourceRecordUnchanged=true
  r.scope='Production Factory.ResultView, actual saved winning negative-profit bill, two sizes and scroll/buttons only; not fresh battle, OS input or all-game acceptance'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
