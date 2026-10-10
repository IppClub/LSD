local D=require('Dora')
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,'Test','auxiliary-animations-result.txt')
D.Content:save(out,'LSD_AUXILIARY_RUNNING\n')
D.thread(function()
 local ok,res=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  local ui=D.Node(); ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode(); bg:drawPolygon({D.Vec2(0,0),D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff23313f)); bg:addTo(ui)
  local models={}; local ends={}; local events={}; local timing={}; local started={}; local names={'defence','cargo','mobility'}
  local manifest=assert(D.json.decode(assert(D.Content:load('Image/Auxiliary/manifest.json'))))
  for i,k in ipairs(names) do
   local m=assert(require('Ground.AuxiliaryModel').create(k),k..' model failed')
   m.recovery=.2; m.scaleX=.95; m.scaleY=.95; m.position=D.Vec2(ui.width*(i-.5)/3,ui.height*.35); m:addTo(ui)
   models[i]=m; ends[i]={}; events[i]={}; timing[i]={}
   m:slot('AnimationEnd',function(name)
    ends[i][name]=(ends[i][name] or 0)+1
    timing[i][name]=D.App.runningTime-started[i]
   end)
   m:slot('ModelEvent',function(_,name) events[i][name]=(events[i][name] or 0)+1 end)
   local label=D.Label('SourceHanSansCN-Regular',26); label.text=({'护盾履带机','四足装备机','悬浮运输机'})[i]; label.position=D.Vec2(m.x,ui.height*.75); label:addTo(ui)
  end
  -- Exclude synchronous asset upload from the first frame's scheduler delta.
  D.sleep(.5)
  for _,state in ipairs({'deploy','idle','move','collect','shield','hit','carry','depleted','lose'}) do
   local duration=0
   for i,m in ipairs(models) do started[i]=D.App.runningTime; duration=math.max(duration,m:play(state,false)) end
   assert(duration>0,'Missing '..state)
   D.sleep(duration+.35)
   for i,m in ipairs(models) do
    assert(ends[i][state]==1,names[i]..' incomplete '..state); assert(math.abs(m.recovery-.2)<.00001)
    local expected=manifest.variants[names[i]].animations[state]+.2
    assert(timing[i][state]>=expected-.05,string.format('%s truncated %s expected=%.3f nativeEnd=%.3f',names[i],state,expected,timing[i][state]))
    assert(timing[i][state]<=expected+.3,names[i]..' delayed '..state)
   end
  end
  for i,m in ipairs(models) do
   assert(events[i]['energy-transfer']==1,'No collection event '..names[i]); assert(events[i]['shield-ready']==1,'No shield event '..names[i])
   m:play('idle',true)
  end
  local report={'PASS variants=3 completeTimelines=27 collectionEvents=3 shieldEvents=3 recovery=.2 nativeDurationsVerified=true'}
  for i,name in ipairs(names) do
   for _,state in ipairs({'deploy','idle','move','collect','shield','hit','carry','depleted','lose'}) do
    report[#report+1]=string.format('%s %s expected=%.3f nativeEnd=%.3f',name,state,manifest.variants[name].animations[state]+.2,timing[i][state])
   end
  end
  return table.concat(report,'\n')
 end,debug.traceback)
 local report='LSD_AUXILIARY_'..(ok and res or 'FAIL '..tostring(res)); print(report); D.Content:save(out,report..'\n')
end)
