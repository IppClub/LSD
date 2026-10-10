-- Input cadence/reversal only; never saved as a training source.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-held-input-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Training.BigYingzhaoPractice').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},{{actor='ninilite',item='emp',quantity=1}},'ninilite')
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge;b.wuyun.mode='review';D.sleep(.4)
  local a=b.arena
  for _,hidden in ipairs({false,true})do
   b.enemies[1].enemy.opacity=hidden and 0 or 1
   assert(b:command('right'));D.sleep(.05);local turningX=a.student.x
   assert(b:command('left'));D.sleep(.05)
   assert(a.student.x<turningX,'Reversal delayed by sample throttle')
   local first=#b.bossTrace.steps;local x=a.student.x;local started=D.App.runningTime
   for i=1,60 do assert(b:command('left'));D.sleep(1/60)end
   local count=#b.bossTrace.steps-first;local elapsed=D.App.runningTime-started
   assert(count<=math.ceil(elapsed/.25)+1 and count>=2,'Unexpected held-input sample count')
   assert(x-a.student.x>100)
   assert(b:command('stop'));D.sleep(.05);local stopped=a.student.x;D.sleep(.1);assert(math.abs(a.student.x-stopped)<1)
   r.cases[#r.cases+1]={hidden=hidden,records=count,seconds=elapsed,travel=x-stopped,reversalImmediate=true};save()
  end
  b:finish('aborted','Input cadence fixture');r.noTrainingSource=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
