-- Isolated art preview; no story, model, wallet, health or production asset writes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/twins-reaction-candidate-result.json'
local r={status='RUNNING',productionInstalled=false,osInput=false,scope='hurt candidate only',models={},screenshots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local base='/private/tmp/lsd-twins-reaction-candidate-20261006-v1'
  local ui=D.Node();ui:addTo(D.Director.ui);local size=D.App.bufferSize;ui.position=D.Vec2(-size.width/2,-size.height/2);local runId=tostring(os.time())
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(size.width,0),D.Vec2(size.width,size.height),D.Vec2(0,size.height)},D.Color(0xff19222e));bg:addTo(ui)
  local floor=D.DrawNode();floor:drawSegment(D.Vec2(0,250),D.Vec2(size.width,250),2,D.Color(0xffe9ecf0));floor:addTo(ui)
  local stage=D.Label('SourceHanSansCN-Regular',30);stage.position=D.Vec2(size.width/2,size.height-100);stage:addTo(ui)
  local all={}
  for i,def in ipairs({{'vika','original',false},{'vivi','original',false},{'vika','candidate',false},{'vivi','candidate',false},{'vika','candidate',true},{'vivi','candidate',true}})do
   local name,mode,flip=table.unpack(def);local asset=mode=='original' and root..'/Spine/'..name..'.skel' or base..'/'..name..'/export/'..name..'-reactions.skel'
   local m=assert(D.Spine(asset..'|'..root..'/Spine/'..name..'.atlas'));m.position=D.Vec2((i-.5)*size.width/6,250);m.scaleX=1.8;m.scaleY=1.8;m.fliped=flip;m.recovery=.2;m:addTo(ui)
   local label=D.Label('SourceHanSansCN-Regular',24);label.position=D.Vec2(m.x,180);label.text=name..' · '..mode..(flip and ' 镜像' or '');label:addTo(ui)
   local row={name=name,mode=mode,flip=flip,completed=0};r.models[#r.models+1]=row
   m:slot('AnimationEnd',function(clip)if clip=='hurt' and not row.ended then row.completed=row.completed+1;row.ended=D.App.totalTime end end)
   m.speed=0;m:play('idle',true);all[#all+1]={model=m,row=row}
  end
  save();D.sleep(.2)
  local start=D.App.totalTime
  for _,entry in ipairs(all)do if entry.row.mode=='candidate'then entry.model.speed=1;entry.row.started=start;entry.row.duration=entry.model:play('hurt',false);assert(math.abs(entry.row.duration-.64)<.02,'Wrong clip duration')end end
  for _,time in ipairs({.0,.08,.16,.28,.43,.86})do
   while D.App.totalTime-start<time do
    for _,entry in ipairs(all)do if entry.row.ended and not entry.row.resumed then entry.row.resumed=true;entry.model.speed=1;entry.model.recovery=.2;entry.model:play('idle',true)end end
    D.sleep(.005)
   end
   stage.text=string.format('双子原骨架受击候选 · %.2fs · 原idle参照 / 正向 / 镜像',time)
   local path=base..'/preview-'..runId..'-'..math.floor(time*100)..'.tga';D.App:saveScreenshot(path);r.screenshots[#r.screenshots+1]=path;D.sleep(.01)
  end
  for _,entry in ipairs(all)do local row=entry.row;if row.mode=='candidate'then assert(row.completed==1 and row.ended-row.started>=row.duration-.035,'Reaction clipped or repeated')end end
  r.fullDurationAndRecovery=true;save()
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and tostring(why)or nil;save();print('LSD_TWINS_REACTION_CANDIDATE_'..r.status)
end)
