-- Art-only native preview. No production assets, story, wallet, or health writes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/twins-full-reaction-candidate-result.json'
local base='/private/tmp/lsd-twins-full-reaction-candidate-20261007-v8'
local r={status='RUNNING',productionInstalled=false,osInput=false,scope='full reaction art candidate',models={},screenshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local ui=D.Node();ui:addTo(D.Director.ui);local size=D.App.bufferSize
  ui.position=D.Vec2(-size.width/2,-size.height/2)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(size.width,0),D.Vec2(size.width,size.height),D.Vec2(0,size.height)},D.Color(0xff19222e));bg:addTo(ui)
  local stage=D.Label('SourceHanSansCN-Regular',28);stage.position=D.Vec2(size.width/2,size.height-30);stage:addTo(ui)
  local runId=tostring(os.time());local all={}
  for i,def in ipairs({{'vivi','original',false},{'vivi','candidate',false},{'vivi','candidate',true},{'vika','original',false},{'vika','candidate',false},{'vika','candidate',true}})do
   local name,mode,flip=table.unpack(def);local column=(i-1)%3;local row=math.floor((i-1)/3)
   local asset=mode=='original'and root..'/Spine/'..name..'.skel'or base..'/'..name..'/export/'..name..'-reactions.skel'
   local m=assert(D.Spine(asset..'|'..root..'/Spine/'..name..'.atlas'))
   m.position=D.Vec2((column+.5)*size.width/3,100+row*size.height/2);m.scaleX=1.6;m.scaleY=1.6;m.fliped=flip;m.recovery=.2;m:addTo(ui)
   local floor=D.DrawNode();floor:drawSegment(D.Vec2(column*size.width/3,m.y),D.Vec2((column+1)*size.width/3,m.y),2,D.Color(0xffe9ecf0));floor:addTo(ui)
   local label=D.Label('SourceHanSansCN-Regular',23);label.position=D.Vec2(m.x,m.y-50);label.text=name..' · '..mode..(flip and ' 镜像'or'');label:addTo(ui)
   local record={name=name,mode=mode,flip=flip,clips={}};r.models[#r.models+1]=record
   m:slot('AnimationEnd',function(clip)
    local c=record.clips[clip];if c and not c.ended then c.ended=D.App.totalTime;c.completed=(c.completed or 0)+1 end
   end)
   m.speed=0;m:play('idle',true);all[#all+1]={model=m,row=record}
  end
  local function screenshot(clip,time)
   stage.text=string.format('双子原骨架 · %s %.2fs · 原idle / 候选 / 镜像',clip,time)
   local path=base..'/full-preview-'..runId..'-'..clip..'-'..math.floor(time*100)..'.tga'
   D.App:saveScreenshot(path);r.screenshots[#r.screenshots+1]=path;D.sleep(.02)
  end
  local function play(clip,duration,samples)
   local start=D.App.totalTime
   for _,entry in ipairs(all)do if entry.row.mode=='candidate'then
    entry.model.speed=1;local actual=entry.model:play(clip,false)
    assert(math.abs(actual-duration)<.02,'Unexpected '..clip..' duration')
    entry.row.clips[clip]={started=start,duration=actual,completed=0}
   end end
   for _,time in ipairs(samples)do while D.App.totalTime-start<time do D.sleep(.005)end;screenshot(clip,time)end
   while D.App.totalTime-start<duration+.05 do D.sleep(.005)end
   for _,entry in ipairs(all)do if entry.row.mode=='candidate'then
    local c=entry.row.clips[clip];assert(c.completed==1 and c.ended-c.started>=duration-.035,'Clipped '..clip)
   end end
  end
  D.sleep(.2);screenshot('idle',0)
  play('hurt',.64,{.08,.16,.43,.64})
  for _,e in ipairs(all)do if e.row.mode=='candidate'then e.model:play('idle',true)end end
  D.sleep(.4)
  play('fall',.9,{0,.1,.24,.38,.56,.9})
  for _,e in ipairs(all)do if e.row.mode=='candidate'then e.model:play('down',true)end end
  D.sleep(.55);screenshot('down',.55)
  play('standUp',1.14,{0,.18,.4,.7,.96,1.14})
  for _,e in ipairs(all)do if e.row.mode=='candidate'then e.model:play('idle',true)end end
  D.sleep(.4);screenshot('recovered',.4)
  r.fullDurationAndRecovery=true;r.visualAcceptancePending=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and tostring(why)or nil;save();print('LSD_TWINS_FULL_REACTION_CANDIDATE_'..r.status)
end)
