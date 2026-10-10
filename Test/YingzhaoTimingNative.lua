local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-timing-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local F=require('Training.YingzhaoFeatures');local T=require('Training.YingzhaoTiming')
  assert(T.project({skill='hero',stage=1,started=0,duration=2},.5)=='unknown','Impact-free transition mislabeled recovery')
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')});local g=b.enemies[1].guard;local update=g.update
  g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
  assert(b:start());b.arena.mode='review';b.wuyun.mode='review';D.sleep(.5)
  for _,skill in ipairs({'punch','massive'})do
   b.enemies[1].enemy.x=2300;b.mentor.x=400;assert(g:attack(skill,b.mentor));local seen={};local deadline=D.App.runningTime+5
   while g.busy do
    assert(D.App.runningTime<deadline);local s=b.observeYingzhao(b.mentor);assert(F.validate(s),'Invalid timing observation');assert(s.featureSchemaVersion==8)
    if s.bossTiming then
     assert(T.project(s.bossTiming,s.at)==s.bossWindow);seen[s.bossWindow]=true
     assert(T.impactLead(s)==s.bossImpactLead);seen[s.bossImpactLead]=true
     local legacy7=D.json.decode(D.json.encode(s),32);legacy7.featureSchemaVersion=7;legacy7.bossImpactLead=nil
     assert(F.validate(legacy7)and F.project(legacy7,8).bossImpactLead=='unknown'and F.key(legacy7,7)==F.key(s,7),'Version 7 compatibility changed')
     local bad=D.json.decode(D.json.encode(s),32);bad.bossImpactLead='idle';assert(not F.validate(bad),'Forged impact lead accepted')
     local wrong=D.json.decode(D.json.encode(s),32);wrong.bossTiming.started=wrong.at+1;assert(not F.validate(wrong))
     wrong=D.json.decode(D.json.encode(s),32);wrong.bossWindow='idle';assert(not F.validate(wrong))
     local old=D.json.decode(D.json.encode(s),32);old.featureSchemaVersion=6;old.bossTiming=nil;old.bossWindow=nil
     assert(F.validate(old));assert(F.project(old,7).bossWindow=='unknown');assert(F.key(old,6)==F.key(s,6),'Legacy projection changed')
    end
    D.sleep(.02)
   end
   assert(seen.early and seen.imminent and seen.recovery and seen.urgent and seen.near and seen.ahead);r.cases[#r.cases+1]={skill=skill,seen=seen,clips=g.strike.clips};save();D.sleep(.2)
  end
  b.enemies[1].enemy.visible=false;local hidden=b.observeYingzhao(b.mentor);assert(F.validate(hidden)and hidden.bossWindow=='unknown'and hidden.bossTiming==nil and hidden.bossImpactLead=='unknown')
  b.enemies[1].enemy.visible=true;b:finish('aborted','Timing feature QA');D.sleep(.1)
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
