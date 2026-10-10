local D=require('Dora');local View={}
function View.pages(p)
 local missions={};for _,m in ipairs(p.missions)do missions[#missions+1]=string.format('第%d章   %s',m.chapter,m.title)end
 local variants={defence='护盾机',cargo='装备机',mobility='悬浮机'}
 local people={};for _,r in ipairs(p.roster)do people[#people+1]=r.name..'  ·  '..r.detail end
 local pages={
  {title='我们走过的路',body=table.concat(missions,'\n')},
  {title='你教会她的，她记得',body=string.format('最终撤离使用：%s\n当前采用：第 %d 次保存，%s\n\n妮妮莉特在最终撤离中行动 %d 次，命中 %d 次\n导师命中 %d 次，火焰命中 %d 次\n\n%s携带记录抵达出口，完成三个区段\n掩护成功 %d 次 · 撤离耗时 %.1f 秒\n妮妮莉特剩余生命 %.0f · 辅助机剩余耐久 %.0f',require("Training.Summary").short(p.finalModel),p.currentRevision,require("Training.Summary").short(p.currentModel),p.evacuation.learner.modelActions,p.evacuation.learner.hits,p.evacuation.mentorHits,p.evacuation.fireHits,variants[p.auxiliaryVariant],p.evacuation.coverBlocks,p.evacuation.seconds,p.evacuation.learner.hp,p.evacuation.auxiliary.hp)},
  {title='仍被记住的人',body=table.concat(people,'\n'),milestone='ending'}
 }
 local credits=require('Ending.Credits').groups
 for first=1,#credits,3 do
  local lines={};for i=first,math.min(first+2,#credits)do lines[#lines+1]=credits[i].title..'\n'..table.concat(credits[i].names,' · ')end
  pages[#pages+1]={title='灵数奇缘社区 · 贡献者',body=table.concat(lines,'\n\n')}
 end
 pages[#pages+1]={title='感谢一起创造这个世界的人',body='《灵数奇缘》社区\n社区贡献者名单与作品来源保留于项目文档网站\n\nDora SSR · 游戏引擎\nYueScript · 脚本语言\nSpine · 骨骼动画技术\n\n游戏工程代码：Copyright (c) 2024 I++ Club · MIT\n美术、配乐与文案：保留《灵数奇缘》社区及各创作者署名\n\n我听得到。',milestone='credits'}
 return pages
end
function View.openAsync(world,onClosed)
 if world and (world.data.journalOpen or world.data.storyBusy)then return nil,'BUSY'end
 local records,why=require('Ending.Records').read();if not records then return nil,why end
 local store,why=require('Ending.Store').open();if not store then return nil,why end
 local watched,why=store:load();if not watched then return nil,why end
 local c={page=1,phase='reading',records=records,pages=View.pages(records),visited={}}
 local root=D.Node();root.size=D.App.bufferSize;root.order=400;root.touchEnabled=true;root.swallowTouches=true;root:addTo(D.Director.ui3D);c.node=root
 require('System.Music').play(root,'Music/L·S·Domain（现实世界主题曲）.mp3',{fade=1.2})
 local panel=D.Node();panel.size=D.Size(1440,900);panel.anchor=D.Vec2(0,0);panel:addTo(root)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(1440,0),D.Vec2(1440,900),D.Vec2(0,900)},D.Color(0xff101b2a));bg:addTo(panel)
 local stripe=D.DrawNode();stripe:drawPolygon({D.Vec2(80,735),D.Vec2(1360,735),D.Vec2(1360,738),D.Vec2(80,738)},D.Color(0xff69c9dd));stripe:addTo(panel)
 local function label(size,x,y)
  local l=assert(D.Label('SourceHanSansCN-Regular',size,true));l.anchor=D.Vec2(0,1);l.alignment='Left';l.position=D.Vec2(x,y);l.textWidth=1280;l.outlineWidth=.12;l.outlineColor=D.Color(0xff101b2a);l:addTo(panel);return l
 end
 local heading=label(44,80,820);local footer=label(20,80,160)
 -- Preserve every mission, training detail and credit in a fixed reading area.
 -- Reuse the native scroll control used by the original result/report screens.
 local area=require('UI.Control.Basic.ScrollArea')({width=1280,height=510,x=720,y=435,scrollBar=true});area:addTo(panel);c.bodyArea=area
 local body=label(27,0,0);body:removeFromParent(false);body:addTo(area.view);body.textWidth=1240;c.body=body
 local function button(text,x)
  local h=D.Node();h.scaleX=.5;h.scaleY=.5;h.position=D.Vec2(x,75);h:addTo(panel);local b=require('UI.InputButton')({text=text,textBG=''});b:slot('Tapped'):clear();b:addTo(h);return b
 end
 c.previous=button('上一页',750);c.next=button('继续',1030);c.close=button('返回',1270)
 local function layout()root.size=D.App.bufferSize;local s=math.min(root.width/1440,root.height/900);panel.scaleX=s;panel.scaleY=s;panel.position=D.Vec2((root.width-1440*s)/2,(root.height-900*s)/2)end
 layout();root:gslot('AppChange',function(n)if n=='Size'then layout()end end)
 if world then world.data.journalOpen=true;require('Story.Flow').freeze(world,true)end
 local function close()
  if c.phase=='saving'then return end;c.phase='closed'
  if world then world.data.journalOpen=false;require('Story.Flow').freeze(world,false)end
  root:removeFromParent();if onClosed then onClosed()end
 end
 local function render()
  local page=c.pages[c.page];heading.text=page.title;body.text=page.body:gsub('🐚','（贝壳）');c.visited[c.page]=true
  area:scrollTo(D.Vec2.zero);area.viewSize=D.Size(1280,math.max(510,body.height+40));body.position=D.Vec2(20,490)
  footer.text=string.format('仍有回应  ·  %d / %d%s',c.page,#c.pages,body.height>470 and '  ·  正文可滚动' or '');c.previous.visible=c.page>1
 end
 c.previous:slot('Tapped',function()if c.phase=='reading'and c.page>1 then c.page=c.page-1;render()end end)
 c.close:slot('Tapped',close)
 c.next:slot('Tapped',function()
  if c.phase~='reading'then return end
  D.thread(function()
   local page=c.pages[c.page]
   if page.milestone then
    for i=1,c.page do if not c.visited[i]then return end end
    c.phase='saving';local ok,why=store:markAsync(page.milestone);c.phase='reading'
    if not ok then footer.text='观看记录尚未保存，请点击继续重试。';c.error=why;return end
   end
   if c.page==#c.pages then close();return end;c.page=c.page+1;render()
  end)
 end)
 render();return c
end
return View
