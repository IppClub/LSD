-- Native source-asset audit for authored 2-15; this does not implement combat.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','infiltration-assets-result.txt');D.Content:save(out,'LSD_INFILTRATION_ASSETS_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local records={}
  for index,asset in ipairs({'charM','charF','shujuyuan','dahuli','factory','loopTowerA'}) do
   D.Cache:loadAsync('spine:'..asset)
   local model=assert(D.Spine(asset),'Missing asset '..asset);model.recovery=.2
   local animations=D.Spine:getAnimations(asset);local looks=D.Spine:getLooks(asset)
   local r={asset=asset,animations=animations,looks=looks};records[#records+1]=r
   if index<=4 then
    model.position=D.Vec2(ui.width*(index-.5)/4,ui.height*.3);model.scaleX=.6;model.scaleY=.6;model:addTo(ui)
    local label=D.Label('SourceHanSansCN-Regular',26);label.text=asset;label.position=D.Vec2(ui.width*(index-.5)/4,ui.height*.65);label:addTo(ui)
    for _,name in ipairs(animations) do if name=='idle' then model:play(name,true);break end end
   end
  end
  return 'PASS nativeLoad=true animationAndLookInventory=true battleImplemented=false '..D.json.encode(records,false,true)
 end,debug.traceback)
 local report='LSD_INFILTRATION_ASSETS_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
