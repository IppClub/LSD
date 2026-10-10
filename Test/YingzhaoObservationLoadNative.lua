-- Fixed-window active combat timing, not a victory or human-input test.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-observation-load-result.json';local r={status='RUNNING',rounds={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local F=require('Training.YingzhaoFeatures');local originalVersion=F.version;local capture=F.capture
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-hunt-natural-20261006/result.json'),32);assert(prior.status=='PASS')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true});assert(loadout)
  local function summary(values)
   table.sort(values);local sum,slow=0,0;for _,v in ipairs(values)do sum=sum+v;if v>33.3333 then slow=slow+1 end end
   return {n=#values,mean=#values>0 and sum/#values or 0,p95=values[math.ceil(#values*.95)],p99=values[math.ceil(#values*.99)],max=values[#values],over33ms=slow}
  end
  for index,version in ipairs({4,5,5,4})do
   F.version=version
   local supplies=assert(require('Economy.CombatSession').virtual('observation-load:'..index..':'..D.App.runningTime,loadout))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true})
   require('Training.YingzhaoTrial').attach(b,prior.model);require('Training.YingzhaoTrial').attach(b,prior.companion)
   local samples,frames,byFrame,actors={},{},{},{};local started=D.App.runningTime
   F.capture=function(battle,owner,...)
    local at=D.App.elapsedTime;local value=capture(battle,owner,...);local ms=(D.App.elapsedTime-at)*1000
    if battle==b and b.phase=='playing'and D.App.runningTime-started>=2 then
     samples[#samples+1]=ms;local frame=D.App.totalTime;byFrame[frame]=(byFrame[frame]or 0)+ms
     local actor=owner==b.mentor and'mentor'or owner.data.supplyActorId;actors[actor]=(actors[actor]or 0)+1
    end
    return value
   end
   local monitor=D.Node();monitor:addTo(b.world)
   monitor:schedule(function(dt)if b.phase=='playing'and D.App.runningTime-started>=2 then frames[#frames+1]=dt*1000 end;return false end)
   assert(b:start());started=D.App.runningTime;local mentor=require('Training.YingzhaoMentor');local state=mentor.new()
   while b.phase=='playing'and D.App.runningTime-started<20 do mentor.step(b,state);D.sleep(.1)end
   local aggregate={};for _,v in pairs(byFrame)do aggregate[#aggregate+1]=v end
   local row={version=version,seconds=D.App.runningTime-started,status=b.phase,capture=summary(samples),frames=summary(frames),capturePerBusyFrame=summary(aggregate),actors=actors,hits=#b.bossTrace.hits,hp={mentor=b.mentorHP,ninilite=b.arena.studentHP,wuyun=b.wuyun.studentHP}}
   assert(actors.mentor and actors.ninilite and actors.wuyun,'Missing active observer')
   r.rounds[#r.rounds+1]=row;save();monitor:removeFromParent();F.capture=capture
   if b.phase=='playing'then b:finish('aborted','20-second observation load fixture')end
   while b.phase=='settling'do D.sleep(.02)end
   row.terminalStatus=b.phase;save()
  end
  r.defaultUnchanged=true;r.noAdoption=true;r.notNaturalVictory=true
 end,debug.traceback)
 F.capture=capture;F.version=originalVersion
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
