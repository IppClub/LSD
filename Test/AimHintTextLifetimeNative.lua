-- Native setter observation on the actual HUD/component; no save or combat injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local output=root..'/Test/aim-hint-text-lifetime-result.json'
local r={status='RUNNING',osInput=false,controlledUiFixture=true,formalCombat=false,cases={}}
local function save()D.Content:save(output,D.json.encode(r,false,true))end;save()
D.thread(function()
 local originalNewIndex,meta
 local ok,why=xpcall(function()
  local oldPath='/private/tmp/lsd-aim-hint-text-cache-20261009/AimHint-before.lua'
  local oldRaw=assert(D.Content:load(oldPath))
  local before=assert(load(oldRaw,'@'..oldPath))()
  local after=require('UI.AimHint')
  local hud=require('UI.HUDControl')({weaponIcon='kineticgun'})
  hud.weapon.visible=true;hud.topControl.visible=false;hud.message.visible=false
  hud:addTo(D.Director.ui3D)
  local tracked=setmetatable({},{__mode='k'})
  local function frames(n)
   local remaining=n;local node=D.Node();node:addTo(hud)
   node:schedule(function()remaining=remaining-1;return remaining<=0 end)
   while remaining>0 do D.sleep(.01)end
   node:removeFromParent()
  end
  for _,spec in ipairs({{'before',before},{'after',after}})do
   local input={held=false,precision=false,available=true}
   local hint=spec[2].attach(hud,function()return input.held,input.precision,input.available end)
   if not meta then
    meta=getmetatable(hint.label);originalNewIndex=assert(meta.__newindex)
    assert(type(originalNewIndex)=='function')
    meta.__newindex=function(object,key,value)
     local count=tracked[object]
     if count and key=='text'then count.writes=count.writes+1 end
     return originalNewIndex(object,key,value)
    end
   end
   local count={writes=0};tracked[hint.label]=count
   frames(5);count.writes=0;frames(120)
   local entry={variant=spec[1],steadyFrames=120,steadyTextWrites=count.writes,transitions={}}
   for _,phase in ipairs({{true,false,true,'正在瞄准\n继续按住可精瞄'},{true,true,true,'精瞄中\n松开发射'},{false,false,false,'暂时无法射击'},{false,false,true,'轻点射击\n长按可精瞄'}})do
    input.held=phase[1];input.precision=phase[2];input.available=phase[3]
    local initial=count.writes;frames(5)
    assert(hint.label.text==phase[4] and hint.node.visible)
    entry.transitions[#entry.transitions+1]={text=hint.label.text,writes=count.writes-initial,phase=hint.phase}
   end
   if spec[1]=='before'then assert(entry.steadyTextWrites>=120)
   else assert(entry.steadyTextWrites==0);for _,t in ipairs(entry.transitions)do assert(t.writes==1)end end
   r.cases[#r.cases+1]=entry;save()
   hint.node:removeFromParent();hud.aimHint=nil;tracked[hint.label]=nil
  end
  meta.__newindex=originalNewIndex;meta=nil
  hud:removeFromParent();assert(D.Content:load(oldPath)==oldRaw)
  r.scope='Native Label text setter counts and real HUD phase transitions only; no whole-combat FPS or lag improvement claim'
 end,debug.traceback)
 if meta and originalNewIndex then meta.__newindex=originalNewIndex end
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
