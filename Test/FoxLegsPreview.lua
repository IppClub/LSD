-- Inspection-only JSON clone: hide skirt through slot alpha, preserving all rigs/curves.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local data=D.json.decode(assert(D.Content:load(D.Path(root,'Docs/artwork/fox-export/fox-chibi-spine.json'))))
  local hidden=false
  for _,slot in ipairs(data.slots)do if slot.name=='skirt' then slot.color='ffffff00';hidden=true end end
  assert(hidden,'skirt slot missing')
  local debugPath=D.Path(root,'Test/fox-legs-debug.json');assert(D.Content:save(debugPath,D.json.encode(data)))
  local atlas=D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas');local asset=debugPath..'|'..atlas
  D.Cache:unload('spine:'..asset);D.Cache:unload(atlas)
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
  local function label(text,x,y)local l=D.Label('SourceHanSansCN-Regular',24);l.text=text;l.position=D.Vec2(x,y);l:addTo(ui);return l end
  label('腿部检查 · 仅隐藏裙摆，不改骨骼或动作',ui.width/2,ui.height-85)
  label('1 待机　2 行走　3 准备　A / D 转向　空格暂停',ui.width/2,ui.height-130)
  local models={};local titles={};local rates={180/(192*.55),.35}
  for i,x in ipairs({ui.width*.3,ui.width*.72})do
   local fox=assert(D.Spine(asset));fox.scaleX=.9;fox.scaleY=.9;fox.position=D.Vec2(x,170);fox.fliped=true;fox.recovery=0;fox.speed=rates[i];fox:addTo(ui);fox:play('fmove',true);models[i]=fox
   titles[i]=label(i==1 and '正常步频 · 朝右' or '慢放 · 朝右',x,ui.height-195)
  end
  local paused=false;local state='fmove';local stateText=label('当前：行走',ui.width/2,ui.height-160);ui.keyboardEnabled=true;ui:slot('KeyDown',function(key)
   if key=='Space' then paused=not paused;for i,m in ipairs(models)do m.speed=paused and 0 or rates[i]end
   elseif key=='A' or key=='D' then for i,m in ipairs(models)do m.fliped=key=='D';titles[i].text=(i==1 and '正常速度' or '慢放')..(key=='D' and ' · 朝右' or ' · 朝左')end
   elseif key=='1' or key=='2' or key=='3' then
    state=({['1']='idle',['2']='fmove',['3']='prepare'})[key];stateText.text='当前：'..({idle='待机',fmove='行走',prepare='准备'})[state]
    rates[1]=state=='fmove' and 180/(192*.55) or 1
    for i,m in ipairs(models)do m.speed=paused and 0 or rates[i];m.recovery=.15*rates[i];m:play(state,true)end
   end
  end)
  return 'PASS skirtHiddenBySlotAlpha=true originalAssetsUnchanged=true nativeSpine=true visualAcceptancePending=true'
 end,debug.traceback)
 local text='LSD_FOX_LEGS_'..(ok and result or 'FAIL '..result)..' runId='..os.time();D.Content:save(D.Path(root,'Test/fox-legs-preview-result.txt'),text);print(text)
end)
