local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/settlement-native-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  for _,name in ipairs({'Settlement','MissionFail','MissionResult'})do
   local code,why=D.xml.tolua(D.Content:load(root..'/UI/'..name..'.xml'));assert(code,why);assert(D.Content:save(root..'/UI/'..name..'.lua','-- [xml]: UI/'..name..'.xml\n'..code))
  end
  D.Cache:loadAsync({'ar.clip','button.clip','gearBox.clip'})
  for _,case in ipairs({{status='Complete',net=40,name='profit'},{status='Complete',net=-30,name='loss'},{status='Failed',net=-60,name='failed'},{status='Failed',net=-60,name='long-failed',long=true},{status='Complete',name='detailed-success',details=true},{status='Failed',name='detailed-failed',details=true},{status='Complete',name='virtual-success',details=true,virtual=true},{status='Failed',name='virtual-failed',details=true,virtual=true}})do
   D.Director.ui3D:removeAllChildren()
   local economy
   if case.details then
    local L=require('Economy.Ledger')
    local ledger=assert(L.new('detail-test',{{actor='mentor',item='kinetic',quantity=20},{actor='ninilite',item='emp',quantity=15},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=12}},300,100))
    assert(L.consume(ledger,'mentor','mentor','kinetic',15,'mentor'))
    assert(L.consume(ledger,'stolen','mentor','kinetic',5,'enemy'))
    assert(L.consume(ledger,'ni','ninilite','emp',10,'ninilite'))
    assert(L.consume(ledger,'wu','wuyun','blade',8,'wuyun'))
    economy=assert(L.settle(ledger,case.status=='Complete' and 'won' or 'failed'));case.net=economy.net
   else economy={income=case.status=='Complete' and 100 or 0,cost=case.status=='Complete' and 100-case.net or 60,net=case.net,refund=25,balanceAfter=300+case.net}end
   local v=require(case.name=='loss' and 'UI.MissionResult' or 'UI.Settlement')({missionMode=true,missionTitle='资源结算 · 显示测试',resultTitle=case.status=='Complete' and '沼泽道路已清理' or '行动失败',resultStatus=case.status,
    reportText=case.long and string.rep('导师：消耗与破甲统计，战术复盘记录。\n',20) or '导师：实弹命中 12\n妮妮莉特：破甲 8\n乌云：近身掩护 4',storyText='本页使用测试账单；没有发放奖励或写入正式存档。',economy=economy,economyMode=case.virtual and 'virtual' or nil})
   v:addTo(D.Director.ui3D);v:alignLayout();D.sleep(.25)
   assert(v.resultLayout==(case.status=='Complete' and 'Settlement' or 'MissionFail'))
   if case.status=='Complete' then assert(v.resultHeading.width*v.resultHeading.scaleX<=940.01,'Result title overlaps team heading')end
   assert(v.againButton and v.baseButton)
   if case.virtual then
    assert(v.economyLabel.text:find('不扣真实物资',1,true) and v.economyLabel.text:find(tostring(economy.cost),1,true))
    assert(not v.economyLabel.text:find('结余',1,true) and not v.economyLabel.text:find('净收益',1,true))
   else assert(v.economyLabel.text:find(tostring(case.net),1,true))end
   if case.long then assert(v.reportArea.viewSize.height>v.reportArea.height,'Long report must scroll');v.reportArea:scrollToPosY(-500,0);D.sleep(.1) end
   if case.details then
    local area=case.status=='Complete' and v.economyArea or v.reportArea
    local text=case.status=='Complete' and v.economyLabel.text or v.reportLabel.text
    assert(text:find('其中他人消耗5',1,true) and text:find('乌云 · 近战',1,true))
    if not case.virtual then assert(area.viewSize.height>area.height,'Detail list must scroll')else assert(text:find('未用价值',1,true) and not text:find('返还',1,true))end
    D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/settlement-'..case.name..'-top.tga');D.sleep(.15)
    area:scrollToPosY(-10000,0);D.sleep(.15)
   end
   local clicked=0;v.baseButton:slot('Tapped',function()clicked=clicked+1 end);v.baseButton:emit('Tapped');assert(clicked==1)
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/settlement-'..case.name..'.tga');D.sleep(.15)
   r.cases[#r.cases+1]={name=case.name,layout=v.resultLayout,net=case.net,buttons=true}
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
