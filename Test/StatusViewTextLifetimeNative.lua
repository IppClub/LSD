-- Native production status view comparison; controlled authoritative contacts,
-- not a geometry/aiming test, formal mission or whole-combat FPS benchmark.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/status-view-text-lifetime-result.json'
local r={status='RUNNING',osInput=false,controlledUiFixture=true,formalCombat=false,cases={},screenshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local meta,oldIndex
 local ok,why=xpcall(function()
  local oldPath='/Users/Jin/Workspace/Dora/LSD-builds/2026-10-09-full-content-battle-feedback-candidate/LingShuQiYuan.app/Contents/Resources/LSD/Script/Combat/StatusView.lua'
  local raw=assert(D.Content:load(oldPath));local old=assert(load(raw,'@'..oldPath))()
  local new=require('Combat.StatusView');local Damage=require('Combat.Damage')
  local ids={'head','body','leftArm','rightArm','leftLeg','rightLeg'}
  local names={head='头部',body='躯干',leftArm='左臂',rightArm='右臂',leftLeg='左腿',rightLeg='右腿'}
  local world=D.Node();world:addTo(D.Director.ui3D)
  local views={};local tracked=setmetatable({},{__mode='k'})
  for i,module in ipairs({old,new})do
   local parts={};for _,id in ipairs(ids)do parts[id]={maxAP=120,armoredMultiplier=.2,exposedMultiplier=1,armoredResponse='stop'}end
   local damage=Damage.new({id='status-target',maxHP=1000,parts=parts})
   local view=module.new(damage,i==1 and '原版显示' or '缓存版显示',names);view:observeParts(ids);view:refresh('head');view.node.anchor=D.Vec2.zero;view.node:addTo(world)
   views[i]=view
   if not meta then
    meta=getmetatable(view.health);oldIndex=assert(meta.__newindex)
    meta.__newindex=function(object,key,value)
     local count=tracked[object];if count and key=='text'then count.writes=count.writes+1 end
     return oldIndex(object,key,value)
    end
   end
   local count={writes=0};view.counter=count
   tracked[view.health]=count;tracked[view.armor]=count
   for _,label in pairs(view.partLabels)do tracked[label]=count end
  end
  local function equal()
   local a,b=views[1],views[2]
   assert(a.health.text==b.health.text and a.armor.text==b.armor.text)
   assert(a.hpBar.scaleX==b.hpBar.scaleX and a.apBar.scaleX==b.apBar.scaleX and a.apBar.visible==b.apBar.visible)
   assert(a.hpBar.color3:toRGB()==b.hpBar.color3:toRGB())
   for _,id in ipairs(ids)do assert(a.partLabels[id].text==b.partLabels[id].text and a.partLabels[id].color3:toRGB()==b.partLabels[id].color3:toRGB())end
  end
  D.App.winSize=D.Size(960,540);D.sleep(.2);world.size=D.App.bufferSize
  for i,v in ipairs(views)do v.node.position=D.Vec2(D.App.bufferSize.width*(i==1 and .25 or .75),D.App.bufferSize.height*.6)end
  for _=1,120 do for _,v in ipairs(views)do v:refresh();v:updateObservedParts()end;equal();D.sleep(.01)end
  assert(views[1].counter.writes==960 and views[2].counter.writes==0)
  r.steady={refreshes=120,beforeTextWrites=views[1].counter.writes,afterTextWrites=views[2].counter.writes};save()
  local function capture(name)
   for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
    D.App.winSize=size;D.sleep(.15);world.size=D.App.bufferSize
    for i,v in ipairs(views)do v.node.position=D.Vec2(D.App.bufferSize.width*(i==1 and .25 or .75),D.App.bufferSize.height*.6)end
    D.sleep(.1);equal()
    local file=D.Path(D.Content.writablePath,'status-view-'..name..'-'..string.format('%d',D.App.bufferSize.width)..'.tga')
    D.App:saveScreenshot(file);D.sleep(.1)
    r.screenshots[#r.screenshots+1]={path=file,state=name,width=D.App.bufferSize.width,height=D.App.bufferSize.height};save()
   end
  end
  capture('unobserved')
  local n=0
  for _,id in ipairs(ids)do
   for _,armorDamage in ipairs({30,90})do
    n=n+1;local events={}
    for i,v in ipairs(views)do
     local token='contact-'..n;assert(v.damage:beginAttack(token))
     local e=assert(v.damage:hit({attackId=token,hitId=token,source='native-fixture',part=id,position={x=100+i*500,y=200},normal={x=-1,y=0}},{id='controlled-weapon',armorDamage=armorDamage,healthDamage=25}))
     v:hit(e,world);assert(v.damage:finishAttack(token));events[i]=e
    end
    equal();assert(events[1].hpAfter==events[2].hpAfter and events[1].apAfter==events[2].apAfter)
    r.cases[#r.cases+1]={part=id,apAfter=events[2].apAfter,hpAfter=events[2].hpAfter,armorBroken=events[2].armorBroken};save()
    if n==1 then capture('armored')end
   end
  end
  capture('broken')
  for i,v in ipairs(views)do
   local token='low-health';assert(v.damage:beginAttack(token))
   local e=assert(v.damage:hit({attackId=token,hitId=token,source='native-fixture',part='head',position={x=100+i*500,y=200},normal={x=-1,y=0}},{id='controlled-weapon',armorDamage=0,healthDamage=740}))
   v:hit(e,world);assert(v.damage:finishAttack(token))
   assert(v.damage.hp==200 and v.health.text=='生命 200 / 1000' and v.armor.text=='头部 · 已破甲')
   assert(v.hpBar.color3:toRGB()==0xff6b6b)
  end
  equal();capture('low-health');D.sleep(.8)
  for _,v in ipairs(views)do assert(#v.effects==0);v:close()end
  meta.__newindex=oldIndex;meta=nil;world:removeFromParent()
  assert(D.Content:load(oldPath)==raw)
  r.scope='Native production labels, bars, colors, damage event consumption and effect cleanup parity; controlled contacts, no actual aim/geometry, formal mission or whole-combat FPS claim'
 end,debug.traceback)
 if meta and oldIndex then meta.__newindex=oldIndex end
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
