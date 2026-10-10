local D=require('Dora');local Title={}
function Title.open(options)
 require('System.Music').stop(.4);D.Audio:stopStream(.4)
 options=options or {};local store=options.store or require('Save.Slots').new()
 local c={phase='ready',store=store};Title.current=c
 local root=D.Node();root.size=D.App.bufferSize;root.tag='game0-save-title';root:addTo(D.Director.ui3D);c.node=root
 root:slot('Cleanup',function()if Title.current==c then Title.current=nil end end)
 local panel=D.Node();panel.anchor=D.Vec2.zero;panel:addTo(root)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(1440,0),D.Vec2(1440,900),D.Vec2(0,900)},D.Color(0xff101b2a));bg:addTo(panel)
 local banner=D.Sprite('Image/banner.jpg');if banner then local s=math.min(1080/banner.width,300/banner.height);banner.scaleX=s;banner.scaleY=s;banner.position=D.Vec2(720,690);banner:addTo(panel)end
 local label=D.Label('SourceHanSansCN-Regular',28,true);label.alignment='Center';label.textWidth=1280;label.position=D.Vec2(720,465);label:addTo(panel);c.label=label
 local menu=D.Node();menu:addTo(panel)
 local function layout()local size=D.App.bufferSize;root.size=size;local s=math.min(size.width/1440,size.height/900);panel.scaleX=s;panel.scaleY=s;panel.position=D.Vec2((size.width-1440*s)/2,(size.height-900*s)/2)end
 layout();root:gslot('AppChange',function(n)if n=='Size'then layout()end end)
 local storageErrors={
  BACKUP_FAILED='无法创建安全备份，暂未打开旅程。\n请检查存储空间和目录写入权限，恢复后可重试。',
  RESTORE_WRITE_FAILED='无法写入恢复后的旅程。\n请检查存储空间和目录写入权限；原存档和备份仍保留。',
  SELECTION_WRITE_FAILED='无法保存旅程选择，暂未打开旅程。\n请检查存储状态后重试；原存档仍保留。',
  CATALOG_UNREADABLE='旅程选择记录暂时无法读取。\n请检查存储状态；已有旅程文件仍保留。'
 }
 local function launch(name,new,restore)
  if c.phase~='ready'then return end;c.phase='opening'
  local saved,why;if restore then saved,why=store:restore(name)elseif new then saved,why=store:create()else saved,why=store:attach(name)end
  if not saved then c.phase='ready';c.error=why;label.text=storageErrors[why] or (why=='SAVE_NEWER_VERSION'and '这份旅程由较新版本保存，请使用对应版本打开。\n原存档已保留，也可以选择兼容的备份恢复。'or why=='SAVE_SCHEMA_UNSUPPORTED'and '这份旅程的数据版本暂不支持。\n原存档已保留，请选择其他旅程或兼容备份。'or '这份旅程暂时无法打开，请选择其他旅程。\n原存档未被替换。');return end
  c.selected=saved;root:removeFromParent()
  if options.onOpen then options.onOpen(saved)else package.loaded.Start=nil;require('Start')end
 end
 local function button(text,y,fn)
  local b=require('UI.InputButton')({text=text,textBG=''});b.scaleX=.65;b.scaleY=.65;b.position=D.Vec2(720,y);b:addTo(menu);b:slot('Tapped'):clear();b:slot('Tapped',fn);return b
 end
 local render
 render=function(page)
  menu:removeAllChildren();c.page=page or 0
  if c.page==0 then
   label.text='灵数奇缘 · GAME 0\n新旅程将单独保存，已有进度会保留。'
   local current,why=store:current();if why then label.text='旅程选择记录暂时无法读取。\n已有旅程文件仍保留，请先检查存储状态。'end;if current then c.continue=button('继续旅程',340,function()launch(current)end)end
   c.new=button('开始新旅程',245,function()launch(nil,true)end)
   c.saves=button('选择已有旅程',150,function()render(1)end)
  else
   local rows=store:list();local name=rows[c.page]
   label.text=name and ('已有旅程 '..c.page..' / '..#rows..'\n'..(name=='lsd.db'and '原有旅程' or os.date('%Y年%m月%d日 %H:%M',tonumber(name:match('lsd%-journey%-(%d+)%-')))))or'尚无保存的旅程'
   local exists=name and D.Content:exist(D.Path(store.directory,name))
   if name and not exists then label.text=label.text..'\n原文件缺失，可从备份恢复。'end
   if exists then c.load=button('读取这份旅程',340,function()launch(name)end)end
   if name and #store:backups(name)>0 then c.restore=button('从备份恢复新旅程',255,function()launch(name,false,true)end)end
   c.next=button('下一份',170,function()render(name and c.page<#rows and c.page+1 or 1)end)
   c.back=button('返回',85,function()render(0)end)
  end
 end
 render(0);return c
end
return Title
