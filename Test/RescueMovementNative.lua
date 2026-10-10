local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/rescue-movement-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local a=require('Training.Arena').createAsync({scene='VRTraining',manualUpdate=true,characterId='wuyun',minX=0,maxX=3000})
  local T=require('Ground.RescueTactics');local u=a.student;u.x=500;D.sleep(.3)
  local function drive(plan,seconds)
   local started=D.App.totalTime;local x=u.x
   while D.App.totalTime-started<seconds do T.move(u,plan);D.sleep(.02)end
   return u.x-x
  end
  local approach=T.plan(u.x,1300,nil,0,3000)
  r.approach=drive(approach,.6);assert(r.approach>70 and u.faceRight and u.playable.current=='fmove')
  local strike={kind='trample',direction=-1};local bossX=u.x+150
  local evade=T.plan(u.x,bossX,strike,0,3000)
  r.evade=drive(evade,.6);assert(r.evade< -100 and u.faceRight and u.playable.current=='bmove')
  T.move(u,{mode='hold',speed=0,face=1});assert(u.velocityX==0 and u.playable.current==u.data.combatRest)
  local x=u.x;D.sleep(.2);assert(math.abs(u.x-x)<2);r.stableStop=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
