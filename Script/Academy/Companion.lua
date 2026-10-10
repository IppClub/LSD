-- Working original NPC interaction: authored check-in or actual training profile.
local D=require("Dora")
local Companion={}
local names={ninilite="妮妮莉特",wuyun="乌云",sunborn="林睿哲",liyena="李叶娜",moling="忍冬",moyu="半夏",ayan="阿岩",villywan="万薇莉",yuzijiang="余子绛"}
local talks={ninilite="Story/Dialog/companion-ninilite.yarn",wuyun="Story/Dialog/companion-wuyun.yarn"}
local function ayanProfile(world)
 local Flow=require("Story.Flow"); local service,err=require("Story.Service").open(); if not service then return nil,err end
 local facts=service:summary(); if not facts then return nil,"READ_FAILED" end
 world.data.journalOpen=true; Flow.freeze(world,true)
 local c={phase="information",id="ayan"}; world.companionPanel=c
 local unlocked=facts.completed["ayan-fragment"]
 local view=require("UI.Phone")({storyMode=true,panelTitle="阿岩 · 人物故事",closeText="返回漫游",pageText="人物记录",
  row1Title="建筑设计师",row1Status="35岁 · 学院建筑与道路设计",
  row2Title="错过的约定",row2Status=unlocked and "故事已记录 · 点击重读" or "训练之后 · 聆听阿岩往事",
  row3Title="记录与记忆",row3Status=facts.completed["ayan-sharing"] and "已讨论 · 线索待核实" or "听完故事后继续交谈",
  row4Title="阿岩的日记",row4Status=facts.completed["ayan-found"] and "人物故事2 · 点击阅读" or "未找到日记 · 前往遗迹调查"})
 c.view=view; view.tag="ayan-character-story"; view:addTo(D.Director.ui3D); view.previousButton.visible=false; view.nextButton.visible=false
 local identity="阿岩 · 建筑设计师\n\n35岁，擅长虚拟领域的建筑设计与结构力学。\n他在学院设计房间、整理道路，也照顾新来的伙伴。\n\n故事片段需要本人愿意讲述后才记录；未获得的记忆不会提前显示。"
 view.detail.text=identity
 view.mailButton:slot("Tapped",function() view.detail.text=identity end)
 view.researchButton:slot("Tapped",function()
  if c.phase~="information" then return end
  if not unlocked then view.detail.text="这段故事尚未记录。\n\n完成李叶娜的两场训练、读完第三封邮件并转告妮妮莉特，然后到训练室中央与阿岩交谈，选择聆听往事。"; return end
  c.phase="dialogue"; world.data.journalOpen=false; view:removeFromParent()
  D.thread(function()
   local opened,why=Flow.openAsync("ayan-fragment",world,function() c.phase="closed"; ayanProfile(world) end,true)
   if not opened then c.phase="information"; world.data.journalOpen=true; view:addTo(D.Director.ui3D); view.detail.text="故事暂时无法重读，请重试。"; print(tostring(why)) end
  end)
 end)
 view.archiveButton:slot("Tapped",function() view.detail.text=facts.completed["ayan-sharing"] and "阿岩认为，集齐散落能源后，AI训练场可能共享战斗记录和数据，并帮助寻找记忆。\n\n这是阿岩提供的线索。现有训练成果仍按学员分别记录；是否能找回遗失的记忆，还需要更多证据。" or "记录与记忆的线索尚未讨论。请先在训练室听取阿岩的讲述。" end)
 view.stationButton:slot("Tapped",function()
  if c.phase~="information" then return end
  if not facts.completed["ayan-found"] then view.detail.text="这本日记尚未找到。沿夜光镜求救信号实际调查阿岩的去向。"; return end
  c.phase="dialogue"; world.data.journalOpen=false; view:removeFromParent()
  D.thread(function()
   local opened,why=Flow.openAsync("ayan-diary",world,function() c.phase="closed"; ayanProfile(world) end,facts.completed["ayan-diary"] or false)
   if not opened then c.phase="information"; world.data.journalOpen=true; view:addTo(D.Director.ui3D); view.detail.text="日记暂时无法打开："..tostring(why) end
  end)
 end)
 view.closeButton:slot("Tapped",function() if c.phase~="information" then return end; c.phase="closed"; world.data.journalOpen=false; Flow.freeze(world,false); view:removeFromParent() end)
 return c
end
function Companion.openAsync(id,world,mode)
 if world.data.storyBusy or world.data.journalOpen then return nil,"STORY_BUSY" end
 if id=="ayan" then return ayanProfile(world) end
 local Flow=require("Story.Flow")
 if mode=="talk" and talks[id] then
  world.data.storyBusy=true; Flow.freeze(world,true)
  local c={phase="dialogue",id=id}; world.companionPanel=c
  local file=talks[id]
  if id=="ninilite" then
   if require("Story.AcademyLoss").isDamaged() then
    file="Story/Dialog/companion-ninilite-loss.yarn"
   else
    local profile=require("Training.Progress").forCharacter(id)
    if not profile.load() or not profile.adopted then file="Story/Dialog/companion-ninilite-first-training.yarn" end
   end
  end
  c.dialogueFile=file
  local story=require("UI.Story")(file); c.view=story; story.tag="companion-dialogue"; story:addTo(D.Director.ui3D)
  story:slot("Ended",function() c.phase="closed"; world.data.storyBusy=false; Flow.freeze(world,false); story:removeFromParent() end)
  story:showAsync(); return c
 end
 local profile=require("Training.Characters")[id] and require("Training.Progress").forCharacter(id)
 local loaded=profile and profile.load()
 world.data.journalOpen=true; Flow.freeze(world,true)
 local c={phase="information",id=id}; world.companionPanel=c
 local name=names[id] or "学院成员"
 local view=require("UI.Phone")({storyMode=true,panelTitle=name,closeText="返回漫游",pageText="人物资料",
  row1Title=profile and "当前训练成果" or "人物身份",row1Status=loaded and profile.adopted and (require("Training.Summary").short(profile.adopted).." · 已采用") or "尚无采用成果",
  row2Title="上一版成果",row2Status=loaded and profile.previous and (require("Training.Summary").short(profile.previous).." · 可回滚") or "尚无上一版本",
  row3Title="当前目标",row3Status="查看通讯记录的下一步",row4Title="学院路线",row4Status="训练室、休息室与指挥室"})
 c.view=view; view.tag="companion-information"; view:addTo(D.Director.ui3D); view.previousButton.visible=false; view.nextButton.visible=false
 local function training(model,label)
  if not profile then return name.." · 学院成员\n\n当前调查目标和已知线索可在通讯与日志中查看。" end
  if not model then return name.." · "..label.."\n\n还没有这一版训练成果。\n前往训练室，亲自示范并观看试战后采用。" end
  local traceText=''
  if model.algorithm=='qlearning' and model.trainingRunId and profile.store then
   local trace=profile.store:loadTrace(model)
   if trace then
    local outcomes={VICTORY='胜利',DEFEAT='落败',TIMEOUT='时间结束'};local lines={}
    for i,round in ipairs(trace.rounds)do lines[#lines+1]='第'..i..'轮：'..outcomes[round.reason]end
    traceText='\n最近补练：新增 '..trace.newUpdates..' 步\n'..table.concat(lines,' · ')
   else traceText='\n训练过程记录暂不可读取，已采用成果仍保留。'end
  end
  return name.." · "..label.."\n\n"..require("Training.Summary").detail(model)..traceText.."\n\n训练成果属于这名学员，切换角色会分别保留。\n在虚拟训练场选择成果复战，可以再次查看实际战斗表现。"
 end
 local service=require("Story.Service").open(); local facts=service and service:summary()
 local details={training(loaded and profile.adopted,"当前成果"),training(loaded and profile.previous,"上一版成果"),facts and facts.objective or "打开通讯与日志查看已知记录。","学院路线\n\n备战室右门→B区右门→训练室→虚拟训练场。\n备战室左门→A区左门→休息室。\nA区电梯→C区右门→指挥室。"}
 for i,b in ipairs({view.mailButton,view.researchButton,view.archiveButton,view.stationButton}) do b:slot("Tapped"):clear(); b:slot("Tapped",function() view.detail.text=details[i] end) end
 view.detail.text=details[1]
 view.closeButton:slot("Tapped",function() c.phase="closed"; world.data.journalOpen=false; Flow.freeze(world,false); view:removeFromParent() end)
 return c
end
return Companion
