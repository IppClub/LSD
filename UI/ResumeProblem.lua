local D=require('Dora')
return function(reason)
 print('Game0 resume stopped: '..tostring(reason))
 local ui=D.Node();ui.tag='resume-problem';ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
 local label=D.Label('SourceHanSansCN-Regular',28);label.text='当前版本无法读取这份游戏进度。\n请更新游戏后重试，存档没有被重置。';label.alignment='Center';label.position=D.Vec2(ui.width/2,ui.height/2+70);label:addTo(ui)
 local retry=require('UI.InputButton')({text='重试读取',textBG=''});retry.scaleX=.65;retry.scaleY=.65;retry.position=D.Vec2(ui.width/2,ui.height/2-70);retry:slot('Tapped'):clear();retry:addTo(ui)
 retry:slot('Tapped',function()ui:removeFromParent();package.loaded.Start=nil;require('Start')end)
 return ui
end
