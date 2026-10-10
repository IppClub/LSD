local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/q-training-ui-native-result.json';local r={status='RUNNING',osInput=false}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local db=D.Content.writablePath..'/q-ui.db';assert(not D.Content:exist(db) and not D.DB:existDB('lsd'))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  require('Data.Config'):loadAsync();require('Training.Level')(nil,'ninilite')
  local limit=D.App.runningTime+30
  while not D.Director.ui3D:getChildByTag('training-controls')do assert(D.App.runningTime<limit);D.sleep(.05)end
  local ui=D.Director.ui3D:getChildByTag('training-controls');local a=ui.arena
  local menu=ui:getChildByTag('training-menu');assert(menu.children.count==15)
  menu:getChildByTag('自主训练'):emit('Tapped');D.sleep(.3);assert(a.qTraining)
  local hud=D.Director.ui3D:getChildByTag('trainingHUD')
  hud.move:emit('Left',true);hud.move:emit('Left',false);D.emit('Skill.Began');D.sleep(.1)
  assert(#a.recorder.samples==0)
  menu:getChildByTag('停止训练'):emit('Tapped');D.sleep(.2)
  assert(not a.qTraining and a.mode=='review' and not a.candidate and not a.adopted)
  assert(#D.DB:query('SELECT * FROM lsd.Game0Training')==0)
  r.sizes={}
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.7)
   local buffer=D.App.bufferSize
   for i=1,menu.children.count do
    local button=menu.children:get(i);local p=button:convertToWorldSpace(D.Vec2.zero)+D.Vec2(buffer.width/2,buffer.height/2)
    assert(p.x>=0 and p.y>=0 and p.x+button.width*button.scaleX*ui.scaleX<=buffer.width and p.y+button.height*button.scaleY*ui.scaleY<=buffer.height,'Button outside viewport: '..button.tag)
   end
   r.sizes[#r.sizes+1]={width=buffer.width,height=buffer.height,buttons=menu.children.count}
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-04/q-training-ui-'..buffer.width..'x'..buffer.height..'.tga')
  end
  r.cancelled=true;r.noSave=true;r.manualInputIsolated=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
