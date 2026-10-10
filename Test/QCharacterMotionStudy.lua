-- Inspect authored Q animation timing and finite native ends without attaching any save.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test','q-character-motion-study-result.txt');D.Content:save(out,'LSD_Q_MOTION_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local actors={};local records={}
  for i,asset in ipairs({'ninilite','wuyun','charF'})do
   D.Cache:loadAsync('spine:'..asset);local m=assert(D.Spine(asset));m.position=D.Vec2(ui.width*(.15+.23*(i-1)),ui.height*.3);m.recovery=.2;m:addTo(ui)
   local label=D.Label('SourceHanSansCN-Regular',24);label.text=asset..' · 原作';label.position=D.Vec2(m.x,ui.height*.82);label:addTo(ui)
   actors[#actors+1]=m;local record={asset=asset,actions={}};records[#records+1]=record
   for _,name in ipairs({'idle','fmove','prepare'})do
    local started=D.App.runningTime;local ended=false;m:slot('AnimationEnd'):set(function(a)if a==name then ended=true end end)
    local duration=m:play(name,false);assert(duration>0);while not ended do assert(D.App.runningTime-started<duration+1);D.sleep(.01)end
    record.actions[#record.actions+1]={name=name,duration=duration,completed=D.App.runningTime-started}
   end
  end
  local fox=require('Story.FoxCompanion').create();fox.position=D.Vec2(ui.width*.85,ui.height*.3);fox:addTo(ui)
  local l=D.Label('SourceHanSansCN-Regular',23);l.text='九尾狐 Q原稿 · 动画待细化';l.position=D.Vec2(fox.x,ui.height*.82);l:addTo(ui)
  for _,a in ipairs(actors)do a:play('idle',true)end;D.sleep(.5);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/q-motion-idle.tga'));D.sleep(.1)
  for _,a in ipairs(actors)do a:play('fmove',true)end;D.sleep(.25);for _,a in ipairs(actors)do a.speed=0 end;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/q-motion-stride-quarter.tga'));D.sleep(.1)
  for _,a in ipairs(actors)do a.speed=1 end;D.sleep(.5);for _,a in ipairs(actors)do a.speed=0 end;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/q-motion-stride-threequarter.tga'));D.sleep(.1)
  for _,a in ipairs(actors)do a.speed=1;a:play('idle',true)end
  return 'PASS actualAuthoredSpineTimelines=true nineFullNativeEnds=true recovery=.2 noSaveAttached=true foxStillOriginalPendingRig=true '..D.json.encode(records,false,true)
 end,debug.traceback)
 local report='LSD_Q_MOTION_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
