-- Controlled visual fixture: current production rig, no story/save injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=D.Path(root,'Test','fox-current-cycle-visual-result.json')
local r={status='RUNNING',osInput=false,controlledVisualFixture=true,formalJourney=false,visualAcceptanceVerified=false,frames={},animationEnds={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local Fox=require('Story.FoxCompanion');local Movement=require('Story.FoxMovement')
  local asset=D.Content:getFullPath('Spine/FoxPrototype/fox-runtime.json')
  local atlas=D.Content:getFullPath('Spine/FoxPrototype/fox-chibi-spine.atlas')
  local original=assert(D.Content:load(asset));local data=assert(D.json.decode(original,32))
  local hidden=false
  for _,slot in ipairs(data.slots)do if slot.name=='skirt'then slot.color='ffffff00';hidden=true end end
  assert(hidden)
  for _,animation in pairs(data.animations)do assert(not(animation.slots and animation.slots.skirt),'Unexpected skirt animation overrides diagnostic alpha')end
  -- Preserve empty JSON objects in authored timelines. Decoding/re-encoding
  -- through Lua tables can turn {} into [], changing more than skirt alpha.
  local slotText='{"name":"skirt","bone":"root","attachment":"skirt"}'
  local position=assert(original:find(slotText,1,true),'Authored skirt slot shape changed')
  assert(not original:find(slotText,position+#slotText,true),'Duplicate diagnostic skirt slot')
  local replacement='{"name":"skirt","bone":"root","attachment":"skirt","color":"ffffff00"}'
  local diagnostic=original:sub(1,position-1)..replacement..original:sub(position+#slotText)
  local clone=D.Path(D.Content.writablePath,'fox-current-skirt-hidden-qa.json');assert(D.Content:save(clone,diagnostic))
  r.sourceAsset=asset;r.sourceAtlas=atlas;r.diagnosticClone=clone;r.onlyDiagnosticChange='skirt slot alpha=0';r.noProductionAssetWrites=true
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local function label(text,x,y)local n=D.Label('SourceHanSansCN-Regular',22);n.text=text;n.position=D.Vec2(x,y);n:addTo(ui);return n end
  label('当前运行模型 · 全周期检查夹具（非剧情 / 非移动速度测试）',ui.width/2,ui.height-70)
  local state=label('待机',ui.width/2,ui.height-110)
  local fox=Fox.createAnimated();fox.position=D.Vec2(ui.width*.22,155);fox:addTo(ui)
  local legs=assert(D.Spine(clone..'|'..atlas));legs.scaleX=fox.scaleX;legs.scaleY=fox.scaleY;legs.position=D.Vec2(ui.width*.52,155);legs:addTo(ui)
  legs.walkAnimationSpeed=Fox.walkAnimationSpeed;legs.moveAnimation=fox.moveAnimation;legs.movementState='idle';legs.artFacesRight=fox.artFacesRight;legs:play('idle',true)
  local ref=assert(D.Spine('villywan'));ref.scaleX=1;ref.scaleY=1;ref.position=D.Vec2(ui.width*.82,155);ref.recovery=.2;ref.fliped=true;ref:play('idle',true);ref:addTo(ui)
  label('正式Q版狐狸',fox.x,125);label('仅裙摆透明 · 同骨骼曲线',legs.x,125);label('万薇莉 · 原始模型比例参考',ref.x,125)
  local models={fox,legs,ref};local phase
  for i,m in ipairs(models)do m:slot('AnimationEnd',function(name)r.animationEnds[#r.animationEnds+1]={model=i,name=name,phase=phase,at=D.App.runningTime}end)end
  for _,spec in ipairs({{'idle-left',0,40},{'walk-right',200,26},{'turn-walk-left',-200,26},{'stop-idle-left',0,40}})do
   phase=spec[1];local velocity=spec[2];state.text=phase
   for _,m in ipairs({fox,legs})do Movement.setVelocity(m,velocity)end
   ref.speed=1;if velocity~=0 then ref.fliped=velocity<0 end;ref:play(velocity==0 and 'idle'or'fmove',true)
   local started=D.App.runningTime;local x=fox.x
   for frame=1,spec[3]do
    D.sleep(.125);local file=D.Path(D.Content.writablePath,'fox-current-'..phase..'-'..frame..'.tga');D.App:saveScreenshot(file)
    r.frames[#r.frames+1]={phase=phase,index=frame,path=file,at=D.App.runningTime,elapsed=D.App.runningTime-started,state=fox.movementState,clip=fox.current,fliped=fox.fliped,speed=fox.speed,recovery=fox.recovery}
   end
   -- Screenshot dispatch is deferred until render; keep this phase alive
   -- for several frames before flipping or changing animation.
   D.sleep(.08)
   assert(fox.x==x,'Pose fixture should not claim physical travel')
   assert(fox.fliped==legs.fliped and fox.movementState==legs.movementState)
   if velocity~=0 then assert(fox.fliped==(velocity>0) and math.abs(fox.speed-.85)<.001)else assert(fox.speed==1 and math.abs(fox.recovery-.2)<.001)end
  end
  assert(D.Content:load(asset)==original,'Production JSON changed')
  r.configuredWalkSpeed=Fox.walkSpeed;r.configuredWalkAnimationSpeed=Fox.walkAnimationSpeed
  r.referenceDisplayScale=ref.scaleX;r.limits={'controlled stationary pose sheet, not formal movement','reference uses authored HeroUnit scale=1; no inferred Spine Node height','human image review required for bends/overlap/quality'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
