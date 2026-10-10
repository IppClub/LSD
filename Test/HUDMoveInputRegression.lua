-- Native component event tests; does not claim real OS-input or playthrough coverage.
return function(root)
 local D=require('Dora');local HUD=require('UI.HUDMove')
 local id=os.time();local path=D.Path(root,'Test/hud-move-input-result.json')
 D.Content:save(path,D.json.encode({status='RUNNING',runId=id}))
 D.thread(function()
  local hud;local ok,result=xpcall(function()
   hud=HUD{x=-5000,y=-5000,visible=true};hud.keyboardEnabled=false
   local current={keyLeft=false,keyRight=false};local history={};local cases={}
   hud.onMove=function(key,down)current[key]=down;history[#history+1]={key=key,down=down}end
   hud:addTo(D.Director.ui3D)
   local function frames(n)for _=1,n do D.sleep()end end
   local function check(name,left,right)
    assert(current.keyLeft==left and current.keyRight==right,name..' got '..D.json.encode(current));cases[#cases+1]=name
   end
   frames(2);check('initial release',false,false)
   hud:emit('Right',true);frames(4);check('held touch remains pressed',false,true)
   hud:emit('Right',false);frames(2);check('touch release',false,false)
   history={};hud:emit('Left',true);hud:emit('Left',false);frames(3)
   local seen=false;for _,e in ipairs(history)do if e.key=='keyLeft' and e.down then seen=true end end
   assert(seen,'same-frame touch was dropped');check('same-frame touch then release',false,false)
   hud:emit('Left',true);hud:emit('Right',true);frames(2);check('both touches held',true,true)
   hud:emit('Left',false);frames(2);check('one of two touches released',false,true)
   hud:emit('Right',false);frames(2);check('both touches released',false,false)
   history={};hud:emit('KeyDown','A');frames(3)
   seen=false;for _,e in ipairs(history)do if e.key=='keyLeft' and e.down then seen=true end end
   assert(seen,'same-frame keyboard was dropped');check('short keyboard then release',false,false)
   hud:emit('Right',true);frames(2);check('switch keyboard to touch',false,true)
   hud:emit('Right',false);frames(2);check('switched touch released',false,false)
   hud:emit('Right',true);frames(2);hud.visible=false;frames(2)
   check('hidden HUD releases movement',false,false)
   hud.visible=true;frames(2);check('show HUD does not revive old touch',false,false)
   hud:emit('Left',true);frames(2);check('press before cleanup',true,false)
   hud:removeFromParent();frames(2);check('cleanup releases movement',false,false)
   hud=nil
   return {status='PASS',cases=cases,nativeComponent=true,osInput=false}
  end,debug.traceback)
  if hud then hud:removeFromParent()end
  local report=ok and result or {status='FAIL',error=result};report.runId=id
  D.Content:save(path,D.json.encode(report));print('LSD_HUD_MOVE_INPUT '..D.json.encode(report))
 end)
end
