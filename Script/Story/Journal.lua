local D=require("Dora")
local Flow=require("Story.Flow")
local Journal={}
function Journal.openAsync(world,page)
 if world.data.storyBusy or world.data.journalOpen then return nil,"STORY_BUSY" end
 local service,err=require("Story.Service").open(); if not service then return nil,err end
 local facts,readError=service:summary(); if not facts then return nil,readError end
 world.data.journalOpen=true; Flow.freeze(world,true)
 local controller={phase="journal",service=service,page=page or 1}; world.storyJournal=controller
 local hint=""
 local function render()
  if controller.view then controller.view:removeFromParent() end
  facts=assert(service:summary())
  local archive=facts.completed["archive-discovery"]
  local detail="当前目标\n"..facts.objective.."\n\n"
  if archive then detail=detail.."已发现资料\n接触事件：三月十五日清晨四点，地下城屏幕同时出现同一图像。\n怪物：适应地面环境的强大生物，地下入侵原因未明。\n调查方向：前往地面站台，核实怪物来源。\n\n" end
  if facts.completed["ground-arrival"] then detail=detail.."地面记录：本次携带采集辅助机，金粉维持生命场；集合恢复生命，沿路自动采集。\n\n"
  elseif facts.completed["station-brief"] then detail=detail.."站台记录：地面作业需辅助机协同；护盾机、枪火库与载人机由部署队调试、分配。\n\n" end
  if facts.completed["lin-investigation"] then
   local rows=D.DB:query("SELECT recipient,item,amount FROM lsd.Game0StorySupplies ORDER BY recipient,item")
   detail=detail.."随队医疗物资\n"
   for _,row in ipairs(rows or {}) do local name=row[1]=="ninilite" and "妮妮莉特" or row[1]=="wuyun" and "乌云" or "导师"; detail=detail..name.." · "..(row[2]=="first-aid-water" and "止伤水" or "贴药").." ×"..row[3].."\n" end
   detail=detail.."\n"
  end
  detail=detail.."学院路线\nB区右门：训练室\nC区右门：指挥室\nC区电梯→D区：左门资料室，右门研发室。\n调查暗格后，C区左侧通道→地铁站台。\n\n"..hint
  local ids={"mail-one","academy-research","archive-discovery","station-brief","train-conflict","mail-two","ground-arrival","ground-contact","ground-rescue","wuyun-rest","underground-cooperation","energy-plan","energy-recovery","ayan-arrival","ayan-detour","ayan-tour","liyena-challenge","liyena-recognition","mail-three","mail-three-forward","ayan-refreshment","ayan-fragment","ayan-sharing","medical-meeting","translator-request","translator-preparation","factory-encounter","factory-material","medical-notify","medical-treatment","medical-recovery","lin-investigation","ruins-preparation","ruins-station","ruins-twins","ayan-found","ayan-diary","ayan-recovery","ruins-ambush","valley-awakening","valley-days","valley-friends","valley-departure","fox-trail-rest","fox-trail-scout","fox-trail-return","command-assembly","patrol-approach","patrol-contact","patrol-cleared","infiltration-fox-guide","infiltration-researcher-scout","researcher-contact","researcher-interrogation","control-pod-researchers","roof-confrontation","roof-aftermath","return-online","network-warning"}
  local titles={"羽凌灵 · 首封邮件","妮妮莉特 · 研发","暗格资料","站台部署","车厢争执","羽凌灵 · 第二封邮件","地面维生场","前沿强敌","乌云的救援","休息室的约定","地下城的合作","地面调查计划","中央能源回收","建筑师的接引","走错的方向","学院的训练邀请","猎鹰的挑战","李叶娜的认可","羽凌灵 · 第三封邮件","转告妮妮莉特","训练后的食物","阿岩的故事碎片","战斗记录与记忆","医师姐弟","林睿哲 · 材料委托","转译器与沼泽","沼泽中的歌声","砗磲贝材料","通知医师姐弟","沼泽毒伤的治疗","休息到翌日","林睿哲 · 断网组织","阿岩失踪的消息","站台出发讨论","求救器与双胞胎","遗迹中的阿岩","阿岩的日记记录","阿岩的数据回收","返程道路的袭击","桃源谷醒来","桃源谷的几日练习","怪物语言与大狐狸","跟随大狐狸","路旁休息与万薇莉","隐蔽侦察据点","开阔处的同行者","指挥室归来与分工","工厂的隐蔽行动","巡逻队的警觉","首波守卫已制服","跟随狐狸潜入","厂区的研发人员","抓获研发人员","指挥中心的口供","信标与发射炮"}
  local statuses={
   facts.mission.unlocks["library-lead"] and "新邮件 · 点击阅读" or "通讯待恢复 · 先完成警戒",
   "前往D区研发室","在资料室调查第二层书柜",
   archive and "前往站台集合点" or "先调查资料室暗格",
   facts.completed["station-brief"] and "站台登车 · 车厢交谈" or "先了解站台部署",
   facts.completed["train-conflict"] and "新邮件 · 点击阅读" or "先完成车厢交谈",
   facts.completed["mail-two"] and "车厢右侧部署 · 下车处交谈" or "先阅读第二封邮件",
   facts.completed["ground-arrival"] and "地面右侧前沿侦察" or "先确认地面维生场",
   facts.mission.unlocks["wuyun-rescued"] and "结算继续 · 与乌云交谈" or "先守住地面退路",
   facts.completed["ground-rescue"] and "前往学院休息室" or "先与乌云在地面交谈",
   facts.completed["wuyun-rest"] and "休息室会见来访者" or "先完成休息室约定",
   facts.completed["underground-cooperation"] and "休息室讨论地面计划" or "先与林睿哲讨论合作",
   facts.mission.unlocks["energy-site-secured"] and "前往中央能源箱收取" or "清理中央能源点伏击",
   facts.completed["energy-recovery"] and "前往训练室 · 接引人阿岩" or "先回收中央能源",
   facts.completed["ayan-arrival"] and "跟随阿岩 · 走近停步处" or "先认识接引人阿岩",
   facts.completed["ayan-detour"] and "继续参观 · 林睿哲的安排" or "先完成阿岩带路",
   facts.mission.unlocks["liyena-coop-complete"] and "训练结算继续 · 听取挑战" or "先完成李叶娜合作训练",
   facts.mission.unlocks["liyena-duel-complete"] and "训练结算继续 · 听取回应" or "先赢得李叶娜对打训练",
   facts.completed["liyena-recognition"] and "新邮件 · 点击阅读" or "先完成李叶娜两场训练",
   facts.completed["mail-three"] and "点击转告 · 留下已接收记录" or "先读第三封邮件",
   "训练室中央 · 走近阿岩", "领取食物后 · 聆听往事", "听完故事后 · 继续交谈", "休息室右侧 · 拜访医师姐弟", "拜访后 · 阅读新委托", "备战室中央 · 与两人确认", "工厂沼泽道路 · 实地观察", "清理花妖后 · 实地采集", "采集后 · 点击通知医师", "休息室诊疗区 · 接受治疗", "治疗后 · 明确休息至翌日", "翌日新消息 · 点击阅读", "阅读消息后 · 同伴讨论", "站台集合点 · 出发讨论","遗迹寻人 · 求救信号处","双胞胎指向 · 实地寻找","找到日记后 · 人物故事阅读","阿岩现场 · 回收手环数据","回收之后 · 现场返程路线","引开追兵之后 · 万薇莉身旁","学会怪物语 · 吊床旁休息","几日之后 · 万薇莉身旁","桃源谷狐狸身旁 · 选择出谷","实际跟随 · 停步处休息","据点附近 · 夜光镜收集","收集完毕 · 撤到开阔处","指挥室中央 · 向林睿哲汇报","分工后出发 · 走近狐狸","夜光镜定位后 · 开始战斗","实际制服巡逻队后 · 狐狸身旁","安全点 · 跟随狐狸","通过三处掩体后 · 乌云身旁","发现研发人员后 · 开始行动","抓获研发人员后 · 实地审问","第七层 · 舱门内的研发人员"}
  local pages=math.ceil(#ids/4); controller.page=math.max(1,math.min(pages,controller.page))
  local args={storyMode=true,journalText=detail,pageText="记录 "..controller.page.." / "..pages}
  controller.recordIds={}
  for i=1,4 do
   local index=(controller.page-1)*4+i; local id=ids[index]
   controller.recordIds[i]=id; args["row"..i.."Visible"]=id~=nil
   args["row"..i.."Title"]=id and (require("Story.Catalog")[id].title or titles[index]) or ""
   args["row"..i.."Status"]=id and (facts.completed[id] and "已记录 · 点击重读" or statuses[index] or require("Story.Catalog")[id].discoveryHint) or ""
  end
  local view=require("UI.Phone")(args)
  view.tag="story-journal"; view.controller=controller; controller.view=view; view:addTo(D.Director.ui3D)
  local function close()
   if controller.phase~="journal" then return end
   controller.phase="closed"; world.data.journalOpen=false; view:removeFromParent(); Flow.freeze(world,false)
  end
  view.closeButton:slot("Tapped",close)
  local function read(id)
   local node=require("Story.Catalog")[id]
   if (node.discoveryTag or node.controlPodCompletion or node.roofCompletion or node.roofAftermathCompletion) and not facts.completed[id] then hint=node.discoveryHint or "首次收取请走近中央能源箱；已记录后可在这里重读。"; render(); return end
   local scene=facts.completed[id] and (node.scene or world.tag) or world.tag
   local can,why=service:canRead(id,scene)
   if not can then hint=why=="WRONG_SCENE" and "请先漫游到对应房间，完成首次调查。" or node.requiresStory and "先完成前置记录："..require("Story.Catalog")[node.requiresStory].title or "先到指挥室完成电梯警戒线，恢复通讯。"; render(); return end
   -- Recorded room events may be reread anywhere; initial discovery remains physical.
   controller.phase="dialogue"; world.data.journalOpen=false; view:removeFromParent()
   D.thread(function()
    local opened,openError=Flow.openAsync(id,world,function() controller.phase="closed"; Journal.openAsync(world,controller.page) end,facts.completed[id] or false)
    if not opened then controller.phase="journal"; world.data.journalOpen=true; hint=tostring(openError); render() end
   end)
  end
  local buttons={view.mailButton,view.researchButton,view.archiveButton,view.stationButton}
  for i,button in ipairs(buttons) do
   local id=controller.recordIds[i]
   if id then button:slot("Tapped",function() read(id) end) end
  end
  if controller.page==2 then view.conflictButton=view.mailButton; view.secondMailButton=view.researchButton end
  view.previousButton.visible=controller.page>1; view.nextButton.visible=controller.page<pages
  view.previousButton:slot("Tapped",function() controller.page=controller.page-1; render() end)
  view.nextButton:slot("Tapped",function() controller.page=controller.page+1; render() end)
 end
 render(); return controller
end
return Journal
