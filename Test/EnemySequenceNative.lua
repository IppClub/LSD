local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine')})do D.Content:insertSearchPath(1,p)end
local Sequence=require('Enemy.Sequence')
D.thread(function()
 local report={status='RUNNING',cases={},scope='Actual multistage animation completion, not skill damage or balance'}
 local function save()D.Content:save(D.Path(root,'Test/enemy-sequence-native-result.json'),D.json.encode(report))end
 save()
 local ok,err=xpcall(function()
  for _,case in ipairs({{asset='xiaoyingzhao',parts={'jump','jump2','jump3','jump4'}},{asset='zhongyingzhao',parts={'rob','rob2','rob3','rob4'}}})do
   D.Cache:loadAsync('spine:'..case.asset);local m=assert(D.Spine(case.asset));m.recovery=.2;m.position=D.Vec2(600,300);m:addTo(D.Director.entry);D.sleep(.15)
   local r={asset=case.asset,clips={}};report.cases[#report.cases+1]=r
   local seq
   seq=Sequence.new({now=function()return D.App.runningTime end,play=function(name,serial,index)
    local row={name=name,started=D.App.runningTime};r.clips[#r.clips+1]=row
    m:slot('AnimationEnd'):set(function(n)if seq:ended(n,serial,index)then row.ended=D.App.runningTime end end)
    local duration=m:play(name,false);row.duration=duration;return duration
   end,complete=function()r.completed=true;m:play('idle',true)end,stop=function(why)r.stopped=why end})
   local stages={};for _,name in ipairs(case.parts)do stages[#stages+1]={name=name}end
   assert(seq:start(stages))
   while seq.status=='playing'do seq:update();D.sleep(.01)end
   assert(seq.status=='complete',seq.error);assert(#r.clips==#case.parts)
   for i,row in ipairs(r.clips)do assert(row.ended and row.ended-row.started>=row.duration-.01);if i>1 then assert(row.started>=r.clips[i-1].ended)end end
   D.sleep(.3);assert(m.current=='idle');r.recoveredToIdle=true;m:removeFromParent();save()
  end
 end,debug.traceback)
 report.status=ok and 'PASS' or 'FAIL';report.error=ok and nil or err;save()
end)
