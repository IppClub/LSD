local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/training-categories-result.json';local r={status='RUNNING',osInput=false,sizes={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT')or root..'/Test/fresh-wuyun-current-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-wuyun%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/training-categories-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  require('Data.Config'):loadAsync();require('Training.Level')(nil,'wuyun')
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Training category timeout');D.sleep(.03)end end
  wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local ui=D.Director.ui3D:getChildByTag('training-controls');local a=ui.arena;local menu=ui:getChildByTag('training-menu')
  local originalNames={'结束示范','三场试战','采用','放弃','重新示范','回滚','返回训练室','近处对练','中距对练','远处对练','基础 AI 对照','成果复战','自主训练','停止训练','护甲靶练习','花妖实战','英招演练','大英招示范','学习部位','部位自主训练','新建自主训练','部位试战','自主试战','部位对照','自主对照','部位记录','缴械演练','缴械示范','学习缴械','缴械试战','缴械对照','缴械成果','缴械补练','对照记录','缴械复盘'}
  for _,name in ipairs(originalNames)do assert(menu:getChildByTag(name),'Lost original entry '..name)end
  assert(menu:getChildByTag('部位成果'),'Missing explicit Boss adoption entry')
  assert(menu:getChildByTag('学习最近示范'),'Missing latest-only learning entry')
  local groups={['基础训练']={'近处对练','中距对练','远处对练','基础 AI 对照','成果复战','自主训练','停止训练'},['场景对练']={'护甲靶练习','花妖实战','英招演练'},['部位战术']={'大英招示范','部位成果','学习部位','学习最近示范','部位自主训练','新建自主训练','部位试战','自主试战','部位对照','自主对照','部位记录'},['缴械战术']={'缴械演练','缴械示范','学习缴械','缴械试战','缴械对照','缴械成果','缴械补练','对照记录','缴械复盘'}}
  assert(ui.trainingCategory=='基础训练'and not menu:getChildByTag('缴械示范').visible and not menu:getChildByTag('缴械示范').touchEnabled)
  D.sleep(.8);local hud=D.Director.ui3D:getChildByTag('trainingHUD');hud.weapon:emit('TapBegan');hud.weapon:emit('TapEnded');D.sleep(1.5)
  assert(#a.recorder.samples==1);local sample=D.json.encode(a.recorder.samples,false,true);local adopted=D.json.encode(a.adopted,false,true)
  local originalSize=D.App.winSize;D.Director.entry:slot('Cleanup',function()D.App.winSize=originalSize end)
  for _,size in ipairs({D.Size(683,384),D.Size(960,540)})do
   D.App.winSize=size;D.sleep(.8)
   local buffer=D.App.bufferSize;local row={windowWidth=size.width,windowHeight=size.height,bufferWidth=buffer.width,bufferHeight=buffer.height,categories={}}
   for _,category in ipairs({'基础训练','场景对练','部位战术','缴械战术'})do
    menu:getChildByTag('training-category-'..category):emit('Tapped');D.sleep(.15);assert(ui.trainingCategory==category)
    local shown={}
    menu.children:each(function(b)
     if b.visible then
      assert(b.touchEnabled,'Visible entry cannot be clicked: '..b.tag)
      local p=b:convertToWorldSpace(D.Vec2.zero)+D.Vec2(buffer.width/2,buffer.height/2)
      local width=b.width*b.scaleX*ui.scaleX;local height=b.height*b.scaleY*ui.scaleY
      assert(p.x>=0 and p.y>=0 and p.x+width<=buffer.width and p.y+height<=buffer.height,'Entry outside viewport '..b.tag)
      shown[#shown+1]=b.tag
     else assert(not b.touchEnabled,'Hidden entry still accepts input '..b.tag)end
    end)
    local expected={};for _,name in ipairs({'结束示范','三场试战','采用','放弃','重新示范','回滚','返回训练室'})do expected[name]=true end
    for _,name in ipairs({'基础训练','场景对练','部位战术','缴械战术'})do expected['training-category-'..name]=true end
    for _,name in ipairs(groups[category])do expected[name]=true end
    assert(#shown==11+#groups[category],'Category has missing or extra entries: '..category)
    for _,name in ipairs(shown)do assert(expected[name],'Entry belongs to wrong category: '..name);expected[name]=nil end
    assert(not next(expected),'Expected entry hidden');row.categories[category]=shown
    assert(D.json.encode(a.recorder.samples,false,true)==sample and D.json.encode(a.adopted,false,true)==adopted,'Navigation changed model/samples')
    if size.width==683 then D.App:saveScreenshot(root..'/Test/training-category-'..category..'.tga');D.sleep(.1)end
   end
   r.sizes[#r.sizes+1]=row;save()
  end
  menu:getChildByTag('training-category-基础训练'):emit('Tapped')
  menu:getChildByTag('结束示范'):emit('Tapped');wait(function()return a.mode=='review'end);assert(not a.candidate and a.message:find('示范还不够',1,true),'Insufficient sample gate lost')
  menu:getChildByTag('放弃'):emit('Tapped');assert(not a.candidate)
  r.adoptionReviewSizes={}
  for _,size in ipairs({D.Size(683,384),D.Size(960,540)})do
   D.App.winSize=size;D.sleep(.8)
   menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
   wait(function()local v=D.Director.ui3D:getChildByTag('yingzhao-adoption');return v and v.state and not v.state.busy end)
   local adoption=D.Director.ui3D:getChildByTag('yingzhao-adoption');assert(adoption.state.expected.current==0)
   assert(not adoption.state.adopt.visible and not adoption.state.rollback.visible,'Empty archive offered an adoption mutation')
   local buffer=D.App.bufferSize
   for _,button in ipairs({adoption.state.refresh,adoption.state.back})do
    local offset=D.Vec2(buffer.width/2,buffer.height/2)
    local origin=button:convertToWorldSpace(D.Vec2.zero)+offset
    local corner=button:convertToWorldSpace(D.Vec2(button.width,button.height))+offset
    assert(origin.x>=0 and origin.y>=0 and corner.x<=buffer.width and corner.y<=buffer.height,'Review control outside viewport')
   end
   D.App:saveScreenshot(root..'/Test/yingzhao-adoption-empty-'..size.width..'.tga');D.sleep(.1)
   local beforeModels=D.json.encode(a.adopted,false,true);adoption.state.back:emit('Tapped')
   wait(function()return ui.visible and hud.visible and not D.Director.ui3D:getChildByTag('yingzhao-adoption')end)
   assert(D.json.encode(a.adopted,false,true)==beforeModels,'Opening review changed basic model')
   r.adoptionReviewSizes[#r.adoptionReviewSizes+1]={bufferWidth=buffer.width,bufferHeight=buffer.height,returned=true}
  end
  r.publicAdoptionEntryReached=true
  menu:getChildByTag('training-category-场景对练'):emit('Tapped');menu:getChildByTag('护甲靶练习'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('part-practice')end)
  local E=require('Economy.Store');assert(E.open()and not E.active()and E.wallet().available==prior.balance)
  r.balance=E.wallet().available;r.originalEntryCount=#originalNames;r.samplesPreserved=true;r.partPracticeReached=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_TRAINING_CATEGORIES_'..r.status)
end)
