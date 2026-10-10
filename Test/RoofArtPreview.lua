local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local result={status='RUNNING',scope='roof art native composition only'}
 local out=D.Path(root,'Test/roof-art-preview-result.json');D.Content:save(out,D.json.encode(result))
 local ok,why=xpcall(function()
  local Art=require('Factory.RoofArt');assert(D.Cache:loadAsync(Art.file)~=false)
  local ui=D.Node();ui:addTo(D.Director.ui3D);ui.size=D.App.bufferSize
  local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff182b36));bg:addTo(ui,-100)
  local stage=D.Node();local scale=math.min(ui.width/3900,(ui.height-100)/1650);stage.scaleX=scale;stage.scaleY=scale;stage:addTo(ui)
  Art.sprite('catwalk',stage,260,45,650,126,-10)
  Art.sprite('stairs',stage,740,145,760,510,-10)
  Art.sprite('catwalk',stage,1130,495,550,107,-10)
  Art.sprite('climbWall',stage,1360,555,320,545,-5)
  for x=1880,3680,600 do Art.sprite('catwalk',stage,x,974,760,138,-10)end
  local dome=Art.dome(stage,2800,1090,1220)
  local label=D.Label('SourceHanSansCN-Regular',26);label.text='屋顶分件拼接检查 · 路线与攀爬尚未接入';label.position=D.Vec2(ui.width/2,ui.height-40);label:addTo(ui,50)
  assert(dome.rear.order<dome.cannon.order and dome.cannon.order<dome.front.order)
  D.sleep(.3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-art-preview.tga'))
  result.status='PASS';result.parts=6;result.layerOrder={dome.rear.order,dome.cannon.order,dome.front.order};result.gameplayValidated=false
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end
 D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
