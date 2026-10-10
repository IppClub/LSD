local D=require('Dora');local A=require('CombatAnimation');local R=require('Story.ValleyRules');local Activities={}
function Activities.attach(world)
 if world.tag~='OuterHeaven' or world.valleyActivities then return end
 local service=require('Story.ValleyService').open();if not service then return end
 local facts,err=service:summary();if not facts then return nil,err end
 local c={phase='idle',service=service,states=facts.states,terminals={},logs={},fishCycles={},chickenDirs={1,-1},calm=0,observing={0,0,0},began=D.App.runningTime};world.valleyActivities=c
 local art=require('Story.ValleyArt').create(world);c.art=art
 local scriptTree='AI:ValleyActivityPresentation';D.Platformer.Data.store[scriptTree]=D.Platformer.Decision.Reject()
 local function player() return D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==world end) end
 local function guide() local v=world.valleyEncounter and world.valleyEncounter.actor;return v and v.unit.world==world and v or nil end
 local function clone(s) return D.json.decode(D.json.encode(s,false,true),16) end
 local function near(x,range) local p=player();return p and math.abs(p.unit.x-x)<(range or 130) end
 local ui=D.Node();ui.tag='valley-activities-ui';ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D);c.ui=ui
 local backdrop=D.DrawNode();backdrop.tag='valley-activities-backdrop';backdrop:addTo(ui)
 local label=D.Label('SourceHanSansCN-Regular',24);label.anchor=D.Vec2(0,1);label.alignment='Left';label:addTo(ui)
 local action=require('UI.Skill')({visible=true,text='行动 E'});action:addTo(ui);c.actionButton=action
 local retry=require('UI.InputButton')({text='重试保存',textBG=''});retry.scaleX=.6;retry.scaleY=.6;retry.visible=false;retry:slot('Tapped'):clear();retry:addTo(ui);c.retryButton=retry
 local function save(id,state)
  local ok,saveError=c.service:saveAsync(id,state)
  if not world.parent then return end
  if ok then
   c.states[id]=state;c.pending=nil;c.phase='idle';retry.visible=false
   local n,total=R.progress(id,state);c.message=R.complete(id,state) and R.specs[id].title..'完成 · '..R.specs[id].amount..'份奖励已收好。' or R.specs[id].title..' '..n..' / '..total
  else c.pending={id=id,state=state};c.phase='save-error';c.message='进度尚未保存：'..tostring(saveError)..'。已完成的动作可重试保存。';retry.visible=true end
 end
 retry:slot('Tapped',function() if c.phase~='save-error' then return end;c.phase='saving';D.thread(function() save(c.pending.id,c.pending.state) end) end)
 local function full(e,track,key)
  local u=e.unit;local oldTree=u.decisionTree;local oldBusy=e.busy;e.busy=true;e.keyLeft=false;e.keyRight=false;u.decisionTree=scriptTree;u:stop();u.velocityX=0;A.configure(u,e.name)
  u.data.combatCompletedName='';local began=D.App.runningTime;local duration=A.play(u,track,false);assert(duration>0,'Activity animation missing '..track)
  local log={track=track,started=began,duration=duration};c.logs[#c.logs+1]=log;log.activity=key
  while u.data.combatCompletedName~=track or (u.data.combatCompletedAt or -1)<began do
   if not world.parent then return false end
   -- The engine swallows thread errors; continue instead of a silent stall.
   if D.App.runningTime>=began+duration+2 then print('ValleyActivities: animation stalled, continuing')break end
   D.sleep(.01)
  end
  log.completed=D.App.runningTime;A.rest(u);u.decisionTree=oldTree;e.busy=oldBusy;return true
 end
 local function perform(id,mutate)
  if c.phase~='idle' or world.data.storyBusy or world.data.journalOpen then return false end
  local p=player();if not p or p.busy then return false end
  c.phase='acting';D.thread(function()
   local state=clone(c.states[id]);if not full(p,'comp',id) then return end
   mutate(state);c.phase='saving';save(id,state)
  end);return true
 end
 local function closeQuiz() if c.quiz then c.quiz:removeFromParent();c.quiz=nil end;require('Story.Flow').freeze(world,false) end
 function c:answer(index)
  if c.phase~='quiz' or not c.quiz then return false,'NO_QUESTION' end
  local lesson=R.lessons[c.states.language.correct+1];if not lesson then return false,'COMPLETE' end
  if index~=lesson.correct then c.message='语气还没对上。先静下来，再听一次。';c.calm=0;closeQuiz();c.phase='idle';return false,'WRONG_ANSWER' end
  closeQuiz();c.phase='idle';return perform('language',function(state) state.correct=state.correct+1;c.calm=0 end)
 end
 local function quiz()
  if c.calm<3 then c.message='先停下脚步，静听三秒，再尝试交流。';return false,'CALM_REQUIRED' end
  local p=player();if not p or not near(R.specs.language.x,180) then return false,'OUT_OF_RANGE' end
  local lesson=R.lessons[c.states.language.correct+1];if not lesson then return false,'COMPLETE' end
  c.phase='quiz';require('Story.Flow').freeze(world,true)
  local q=D.Node();q.size=D.App.bufferSize;q.order=100;q:addTo(D.Director.ui3D);c.quiz=q
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(q.width,0),D.Vec2(q.width,q.height),D.Vec2(0,q.height)},D.Color(0xdd183c46));bg:addTo(q)
  local text=D.Label('SourceHanSansCN-Regular',32);text.text='静心倾听 · '..lesson.speech..'\n它想表达哪一种意思？';text.textWidth=q.width-160;text.alignment='Center';text.position=D.Vec2(q.width/2,q.height*.70);text:addTo(q)
  c.answerButtons={}
  for i,answer in ipairs(lesson.answers) do
   local button=require('UI.InputButton')({text=tostring(i),textBG=''});button.position=D.Vec2(q.width*.23,q.height*.57-(i-1)*90);button.scaleX=.65;button.scaleY=.65;button:slot('Tapped'):clear();button:slot('Tapped',function() c:answer(i) end);button:addTo(q);c.answerButtons[i]=button
   local line=D.Label('SourceHanSansCN-Regular',27);line.anchor=D.Vec2(0,.5);line.alignment='Left';line.text=answer;line.position=D.Vec2(q.width*.34,q.height*.57-(i-1)*90);line:addTo(q)
  end
  local back=require('UI.InputButton')({text='再听一会',textBG=''});back.position=D.Vec2(q.width*.5,q.height*.22);back.scaleX=.6;back.scaleY=.6;back:slot('Tapped'):clear();back:slot('Tapped',function() closeQuiz();c.phase='idle' end);back:addTo(q)
  return true
 end
 function c:request()
  local p=player();if c.phase~='idle' or not p or p.busy or world.data.storyBusy or world.data.journalOpen then return false,'BUSY' end
  local id=c.active;if not id then return false,'NO_ACTIVITY' end
  if R.complete(id,c.states[id]) then c.message='这项活动已经完成，奖励已保存。';return false,'COMPLETE' end
  if id=='fish' then
   for i,n in ipairs(art.fishes) do if not c.states.fish.marks[i] and c.fishCycles[i]<.65 and near(n.x-200,105) then return perform(id,function(s) s.marks[i]=true end) end end
   c.message='鱼儿还未游到手边。靠近浮出水面的鱼，再按行动。';return false,'FISH_NOT_REACHABLE'
  elseif id=='farm' then
   local i=math.floor((p.unit.x-(R.specs.farm.x-150))/150+.5)+1
   if i<1 or i>3 or not near(R.specs.farm.x+(i-2)*150,80) then return false,'OUT_OF_RANGE' end
   local stage=c.states.farm.plots[i]
   if stage==3 then return false,'PLOT_HARVESTED' end
   if stage==2 and os.time()-c.states.farm.watered[i]<R.growthSeconds then c.message='苗还在长，去照看旁边的田垄吧。';return false,'STILL_GROWING' end
   return perform(id,function(s) s.plots[i]=stage+1;if stage==1 then s.watered[i]=os.time() end end)
  elseif id=='peach' then
   for i=1,3 do if not c.states.peach.marks[i] and near(R.specs.peach.x+(i-2)*200,90) and c.observing[i]>=2.5 then return perform(id,function(s) s.marks[i]=true end) end end
   c.message='停在一棵花树旁，看看飘落的花瓣，再记录风景。';return false,'OBSERVE_FIRST'
  elseif id=='chicken' then
   for i,n in ipairs(art.chickens) do if not c.states.chicken.marks[i] and near(n.x-200,105) then c.catching=i;return perform(id,function(s) s.marks[i]=true;c.catching=nil;n.x=R.specs.chicken.x-180+(i-1)*90;n.scaleX=1 end) end end
   c.message='靠近野鸡，再用行动把它收拢入栏。';return false,'CHICKEN_TOO_FAR'
  elseif id=='language' then return quiz() end
  return false,'UNKNOWN_ACTIVITY'
 end
 action:slot('TapBegan',function() c:request() end)
 ui.keyboardEnabled=true;ui:slot('KeyDown',function(key) if key=='E' then c:request() end end)
 for _,id in ipairs(R.ids) do
  local spec=R.specs[id];local marker=D.Node();marker.position=D.Vec2(spec.x,world.offset+230);marker.tag='valley-'..id;marker:addTo(world)
  local menu=require('UI.Interaction')({text=spec.title,buttons={{'参与活动',''}},fliped=false});menu.tag='valley-'..id..'-terminal';menu.transformTarget=marker;menu.scaleX=.325;menu.scaleY=.325;menu.visible=false;menu.menu.enabled=false;menu:addTo(world)
  c.terminals[id]={menu=menu,near=false};menu:slot('Tapped',function()
   if c.phase~='idle' or not near(spec.x,210) or world.data.storyBusy or world.data.journalOpen then return end
   c.active=id;c.message=({fish='鱼儿浮出水面时，靠近它按行动。',farm='靠近三道田垄，依次播种、浇水、等苗长成后收获。',peach='停在三棵桃树旁，驻足观赏，再记录景色。',chicken='追上两只野鸡，靠近后按行动收拢入栏。',language='停下脚步，静听三秒，选择怪物话语的意思。'})[id]
  end)
 end
 local prev=D.App.runningTime
 ui:schedule(function()
  if not world.parent then ui:removeFromParent();return true end
  local now=D.App.runningTime;local dt=math.min(.1,now-prev);prev=now;local p=player();local v=guide()
  local available=p and not p.busy and c.phase=='idle' and not world.data.storyBusy and not world.data.journalOpen
  ui.size=D.App.bufferSize;action.position=D.Vec2(ui.width-170,170);action.visible=c.active~=nil and available
  retry.position=D.Vec2(ui.width-250,ui.height-260);label.position=D.Vec2(30,ui.height-170);label.textWidth=math.max(280,math.min(1310,ui.width-450));label.visible=not world.data.storyBusy and not world.data.journalOpen
  local n,total=0,0;if c.active then n,total=R.progress(c.active,c.states[c.active]) end;label.text=(c.active and R.specs[c.active].title..' '..tostring(n)..' / '..tostring(total)..' · 行动 E\n' or '桃源漫游 · 万薇莉会陪你探索五项活动\n')..(c.message or '沿谷道向右：鱼塘 → 田地 → 桃林 → 鸡舍 → 静听处')
  backdrop.visible=label.visible;backdrop.position=D.Vec2(15,ui.height-260);backdrop:clear();backdrop:drawPolygon({D.Vec2.zero,D.Vec2(label.textWidth+30,0),D.Vec2(label.textWidth+30,108),D.Vec2(0,108)},D.Color(0xbb101b28))
  for id,t in pairs(c.terminals) do local can=available and near(R.specs[id].x,210);if (not not can)~=t.near then t.near=not not can;if can then t.menu.visible=true;t.menu:show() else t.menu:hide(false) end end end
  for i,n in ipairs(art.fishes) do local u=(now-c.began+i*.87)%3.4;c.fishCycles[i]=u;n.visible=not c.states.fish.marks[i];n.x=R.specs.fish.x+200+math.sin(now*.8+i)*135;n.y=world.offset+18+math.sin(now*2+i)*7;n.opacity=u<.65 and 1 or .35 end
  for i,n in ipairs(art.plots) do local s=c.states.farm;require('Story.ValleyArt').crop(n,s.plots[i],(os.time()-s.watered[i])/R.growthSeconds) end
  for i,n in ipairs(art.chickens) do
   if c.states.chicken.marks[i] then n.x=R.specs.chicken.x-180+(i-1)*90;n.y=world.offset
   elseif c.active=='chicken' and available and c.catching~=i then
    if p and math.abs((n.x-200)-p.unit.x)<480 then c.chickenDirs[i]=p.unit.x<n.x-200 and 1 or -1 end
    if n.x>R.specs.chicken.x+550 then c.chickenDirs[i]=-1 elseif n.x<R.specs.chicken.x-300 then c.chickenDirs[i]=1 end
    n.x=n.x+c.chickenDirs[i]*220*dt;n.scaleX=c.chickenDirs[i];n.y=world.offset+math.abs(math.sin(now*12+i))*9
   end
  end
  for i=1,3 do if available and near(R.specs.peach.x+(i-2)*200,90) and math.abs(p.unit.velocityX)<5 then c.observing[i]=c.observing[i]+dt else c.observing[i]=0 end end
  if available and near(R.specs.language.x,180) and math.abs(p.unit.velocityX)<5 then c.calm=math.min(3,c.calm+dt) else c.calm=0 end
  if v and world.valleyEncounter.phase=='ready' then
   for _,name in ipairs({'fmove','idle','turn'}) do local a=v.unit:getAction(name);if a then a.reaction=.05 end end
   local follow=available and math.abs(v.unit.x-p.unit.x)>230
   v.keyLeft=follow and v.unit.x>p.unit.x or false;v.keyRight=follow and v.unit.x<p.unit.x or false
   local monster=world.valleyEncounter.friendly
   if monster and monster.visible and available then
    local dx=math.min(v.unit.x,p.unit.x)-450-monster.x;local moving=math.abs(dx)>70
    if moving then monster.x=monster.x+(dx>0 and 1 or -1)*math.min(math.abs(dx),190*dt);monster.scaleX=dx>0 and -1 or 1 end
    if moving~=c.friendlyMoving then c.friendlyMoving=moving;monster:play(moving and 'move' or 'idle1',true) end
   end
  end
  return false
 end)
 world:slot('Cleanup',function() if ui.parent then ui:removeFromParent() end;if c.quiz then c.quiz:removeFromParent() end end)
 require('Story.ValleyDays').attach(world,c)
 return c
end
return Activities
