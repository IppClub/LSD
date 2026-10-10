-- Real units and damage entry; blocked/absorbed/lethal impacts must not steal poses.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/hit-reaction-guards-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local K=require('Combat.Displacement');local A=require('CombatAnimation')
  local a=require('Training.Arena').createAsync({scene='VRTraining',manualUpdate=true})
  a:beginDemo(180);local u=a.student;local alive=true
  local target={unit=u,alive=function()return alive end,damage=function()return 0 end}
  local strike={damage=0};a.enemyCombat:damage(target,{damage=18},strike)
  assert(not K.blocked(u)and strike.damage==0,'Absorbed hit triggered reaction');r.absorbed=true
  target.damage=function(n)return n end;target.immovable=true
  a.enemyCombat:damage(target,{damage=18,knockX=350},strike)
  assert(not K.blocked(u),'Immovable target reacted');r.immovable=true
  target.immovable=false;target.damage=function(n)alive=false;A.play(u,'lose',false);return n end
  a.enemyCombat:damage(target,{damage=18,knockY=420},strike)
  assert(not K.blocked(u)and u.playable.current=='lose','Lethal hit replaced defeat');r.lethal=true
  alive=true;target.damage=function(n)return n end;A.rest(u)
  a.enemyCombat:damage(target,{damage=14},strike);assert(K.blocked(u)and u.playable.current=='hit')
  local mock={phase='playing',mentor=u,hero=u,heroHP=100,arena=a}
  mock.heroBusy=require('Trial.Battle').heroBusy
  for _,module in ipairs({'Academy.DefenseBattle','Mission.Battle','Trial.Battle'})do
   local accepted=require(module).command(mock,'right')
   assert(not accepted and u.playable.current=='hit','Command interrupted hit: '..module)
  end
  r.commandProtection=true
  local deadline=D.App.totalTime+3
  while K.blocked(u)do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(u.playable.current==u.data.combatRest);r.recovered=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
