local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/small-yingzhao-timeline-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.Cache:loadAsync('spine:xiaoyingzhao')
  local Sequence=require('Enemy.Sequence');local Timeline=require('Enemy.SmallYingzhaoTimeline')
  for _,flipped in ipairs({false,true})do for _,skill in ipairs({'jump','kick'})do
   local m=assert(D.Spine('xiaoyingzhao'));m.look='default';m.recovery=.2;m.fliped=flipped;m:addTo(D.Director.entry)
   local row={skill=skill,flipped=flipped,clips={},impacts={}};r.cases[#r.cases+1]=row
   local seq;seq=Sequence.new({now=function()return D.App.runningTime end,play=function(name,serial,index)
    local clip={name=name,started=D.App.runningTime};row.clips[#row.clips+1]=clip
    m:slot('AnimationEnd'):set(function(n)if seq:ended(n,serial,index)then clip.ended=D.App.runningTime end end)
    clip.duration=m:play(name,false);return clip.duration
   end,impact=function(name,index,strike)
    row.impacts[#row.impacts+1]={clip=name,time=D.App.runningTime-seq.started}
   end,complete=function()m:play('idle',true)end})
   assert(seq:start(Timeline.stages(skill)))
   while seq.status=='playing' do seq:update();D.sleep(.01)end
   assert(seq.status=='complete',seq.error);assert(#row.impacts==1)
   local expected=skill=='jump' and .2 or .65
   assert(row.impacts[1].clip==(skill=='jump' and 'jump2' or 'kick'))
   assert(row.impacts[1].time>=expected and row.impacts[1].time<expected+.08)
   for i,clip in ipairs(row.clips)do assert(clip.ended and clip.ended-clip.started>=clip.duration-.01);if i>1 then assert(clip.started>=row.clips[i-1].ended)end end
   D.sleep(.25);assert(m.current=='idle');row.recovered=true
   row.completedImpacts=row.impacts;row.completedClips=row.clips;row.impacts={};row.clips={};assert(seq:start(Timeline.stages(skill)));D.sleep(.1);seq:update();assert(seq:cancel('QA_INTERRUPT'))
   m:play('hit',false);D.sleep(.8);seq:update();assert(#row.impacts==0 and seq.status=='cancelled');row.cancelledWithoutImpact=true
   m:removeFromParent();save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
