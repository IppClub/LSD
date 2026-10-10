-- Story completion and unlocks commit together. Dialogue playback is never saved mid-line.
local D=require("Dora")
local Catalog=require("Story.Catalog")
local Service={}; Service.__index=Service
function Service.open()
 if not D.DB:existDB("lsd") then return nil,"NO_GAME_DATABASE" end
 if D.DB:exec("CREATE TABLE IF NOT EXISTS lsd.Game0StoryMeta (id INTEGER PRIMARY KEY CHECK(id=1),schemaVersion INTEGER NOT NULL)")<0 then return nil,"SCHEMA_FAILED" end
 if D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryMeta VALUES (1,1)")<0 then return nil,"SCHEMA_FAILED" end
 local rows=D.DB:query("SELECT schemaVersion FROM lsd.Game0StoryMeta WHERE id=1")
 if not rows or not rows[1] or rows[1][1]~=1 then return nil,"INCOMPATIBLE_STORY_SAVE" end
 for _,sql in ipairs({
  "CREATE TABLE IF NOT EXISTS lsd.Game0StoryPerformances (node TEXT PRIMARY KEY,report TEXT NOT NULL)",
  "CREATE TABLE IF NOT EXISTS lsd.Game0StoryNodes (id TEXT PRIMARY KEY, completedAt INTEGER NOT NULL)",
  "CREATE TABLE IF NOT EXISTS lsd.Game0StoryUnlocks (id TEXT PRIMARY KEY,node TEXT NOT NULL)",
  "CREATE TABLE IF NOT EXISTS lsd.Game0StoryAssignments (role TEXT PRIMARY KEY,duty TEXT NOT NULL,node TEXT NOT NULL)",
  "CREATE TABLE IF NOT EXISTS lsd.Game0StorySupplies (source TEXT NOT NULL,recipient TEXT NOT NULL,item TEXT NOT NULL,amount INTEGER NOT NULL CHECK(amount>=0),PRIMARY KEY(source,recipient,item))"
 }) do if D.DB:exec(sql)<0 then return nil,"SCHEMA_FAILED" end end
 return setmetatable({},Service)
end
function Service:summary()
 local rows=D.DB:query("SELECT id FROM lsd.Game0StoryNodes")
 local rewards=D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks")
 local mission,err=require("Mission.Service").open()
 local facts=mission and mission:summary()
 if not rows or not rewards or not facts then return nil,err or "READ_FAILED" end
 local result={completed={},unlocks={},mission=facts}
 for _,row in ipairs(rows) do result.completed[row[1]]=true end
 for _,row in ipairs(rewards) do result.unlocks[row[1]]=true end
 local captured=false
 if D.DB:exist('Game0Researcher','lsd')then
  local rows=D.DB:query('SELECT schemaVersion,caught FROM lsd.Game0Researcher WHERE id=1')
  captured=rows and rows[1] and rows[1][1]==1 and rows[1][2]==1 or false
 end
 local secondPatrol=false
 if D.DB:exist('Game0SecondPatrol','lsd')then
  local rows=D.DB:query('SELECT schemaVersion,completed FROM lsd.Game0SecondPatrol WHERE id=1')
  secondPatrol=rows and rows[1] and rows[1][1]==1 and rows[1][2]==1 or false
 end
 local pod
 if D.DB:exist('Game0ControlPod','lsd')then
  local rows=D.DB:query('SELECT schemaVersion,floor,doorOpen FROM lsd.Game0ControlPod WHERE id=1')
  if rows and rows[1] and rows[1][1]==1 then pod={floor=rows[1][2],doorOpen=rows[1][3]==1}end
 end
 local roofStage,roofActive
 if D.DB:exist('Game0Roof','lsd')then
  local rows=D.DB:query('SELECT schemaVersion,stage,active FROM lsd.Game0Roof WHERE id=1')
  if rows and rows[1] and rows[1][1]==1 then roofStage=rows[1][2];roofActive=rows[1][3]==1 end
 end
 local roofWon=false
 if D.DB:exist('Game0RoofDuel','lsd')then local duel=D.DB:query('SELECT schemaVersion,completed FROM lsd.Game0RoofDuel WHERE id=1');roofWon=duel and duel[1]and duel[1][1]==1 and duel[1][2]==1 or false end
 if result.completed['final-betrayal']then result.objective='我听得到。终章交谈已记录，可在撤离终端回看。'
 elseif result.mission.unlocks['last-promise-complete']then result.objective='妮妮莉特与回收记录已抵达撤离终端。研发室出口保留撤离记录。'
 elseif result.completed['jade-distance']then result.objective='玉留下了有限的撤离窗口。带妮妮莉特与回收记录离开受损学院。'
 elseif result.mission.unlocks['twins-rescued']then result.objective='双子已抵达研究区出口。回到玉的支撑点，与她谈谈力量的代价。'
 elseif result.completed['jade-arrival']then result.objective='走近双子右侧的撤离通道，准备护送两人通过危险区。'
 elseif result.completed['academy-loss']then result.objective='研究区仍有双子的生命信号。经学院电梯到D区，沿右侧房门前往研发室。沿途终端可查看各区人员状态。'
 elseif result.mission.unlocks['academy-defense-complete']then result.objective='主通道已守住。走近A区右侧通讯点，确认其他小组的位置。'
 elseif result.completed['network-warning']then result.objective='学院入口遇袭。经学院电梯到A区，走近走廊中央的防线标记，与妮妮莉特准备防卫。'
 elseif result.completed['return-online']then result.objective='羽凌灵已重新接入。经D区右侧房门进入研发室，读取中央信道监测台。'
 elseif result.completed['roof-aftermath']then result.objective=roofActive and '乌云已进入漩涡。与妮妮莉特离开发射炮平台。'or '已撤离发射炮平台。返回指挥室中央，接听羽凌灵的新来电。'
 elseif roofWon then result.objective='乌云停下了攻势，发射炮却仍在运转。走近他继续交谈。'
 elseif result.completed['roof-confrontation'] then result.objective='发射炮已经启动。与妮妮莉特一起阻止乌云。'
 elseif result.completed['control-pod-researchers'] and roofStage==2 then result.objective='已翻过围墙。沿屋顶平台前往玻璃罩内的发射炮。'
 elseif result.completed['control-pod-researchers'] and roofStage==1 then result.objective='已到阶梯上层。走近墙面，使用攀爬技能翻上屋顶。'
 elseif result.completed['control-pod-researchers'] then result.objective='已问出发射炮位于顶楼玻璃罩内。沿控制舱房间向右到屋顶通道，再使用阶梯和攀爬。'
 elseif pod and pod.doorOpen then result.objective='控制舱舱门已打开。穿过门口，走近正在争论的三名研发人员。'
 elseif pod then result.objective='沿旋转阶梯前往第七层，在门边控制台开启金属舱门。当前第 '..pod.floor..' 层。'
 elseif secondPatrol then result.objective="控制舱前的守卫已制服。乌云留下看守，导师与妮妮莉特准备进入第七层控制舱。"
 elseif result.completed["researcher-interrogation"] then result.objective="已问出指挥中心在第七层控制舱。乌云留下看守，导师与同伴继续前往控制舱。"
 elseif captured then result.objective="研发人员已被控制。下一步在厂区核实指挥中心的位置。"
 elseif result.completed["infiltration-researcher-scout"] then result.objective="已绕过巡逻队。乌云建议抓获研发人员，进一步核实控制舱的位置。"
 elseif result.completed["infiltration-fox-guide"] then result.objective="跟随狐狸潜入厂区，在箱后隐蔽并避开巡逻守卫的视线。"
 elseif result.completed["command-assembly"] then result.objective="行动分工已记录。导师、妮妮莉特和乌云率领主攻，按狐狸侦察路线准备进攻工厂。"
 elseif result.completed["fox-trail-return"] then result.objective="侦察资料已收集。回指挥室，向林睿哲报告断网组织据点。"
 elseif result.completed["fox-trail-scout"] then result.objective="据点位置已收集。走近狐狸，三人一起撤到开阔处。"
 elseif result.completed["fox-trail-rest"] then result.objective="万薇莉已加入同行。继续跟随狐狸，隐蔽接近据点并使用夜光镜。"
 elseif result.completed["valley-departure"] then result.objective="沿工厂道路跟随狐狸，到停步处休息并使用随身食物。"
 elseif result.completed["valley-friends"] then result.objective="已学会与怪物交流。救命的大狐狸愿意带路，下一步跟随它调查断网组织。"
 elseif result.completed["valley-days"] then result.objective="几日练习后，走近万薇莉与怪物朋友，试试所学的语言。"
 elseif result.completed["valley-awakening"] then result.objective="在桃源谷与万薇莉相识。探索谷中的鱼塘、田地和桃林，再学习与怪物交流。"
 elseif result.mission.unlocks["ruins-diversion-complete"] then result.objective="同伴与双胞胎已撤离。你在桃源谷醒来，走近万薇莉了解这里。"
 elseif result.completed["ruins-ambush"] then result.objective="返程遇袭。使用烟雾和火光掩护撤离，导师沿右侧标记引开追兵；药品可在受伤时使用。"
 elseif result.completed["ayan-recovery"] then result.objective="阿岩的数据已进入手环。护送双胞胎返回基地，留意返程道路。"
 elseif result.completed["ayan-found"] then result.objective="阿岩的日记已找到，可从人物故事阅读。走近遗迹现场回收手环数据，带两位孩子返程。"
 elseif result.completed["ruins-twins"] then result.objective="求救信号来自双胞胎的发信器。带她们沿指向的道路继续寻找阿岩，夜光镜可定位。"
 elseif result.completed["ruins-station"] then result.objective="出发讨论已记录。前往遗迹城市，寻找求救信号与阿岩的去向。"
 elseif result.completed["ruins-preparation"] then result.objective="阿岩失踪。休息室右门→A区电梯→C区左通道，走近站台集合点，与两位同伴讨论。"
 elseif result.completed["lin-investigation"] then result.objective="已明确收到林睿哲消息与每人一份止伤水/贴药。走近休息室诊疗区的妮妮莉特与乌云，讨论阿岩失踪。"
 elseif result.completed["medical-recovery"] then result.objective="休息至翌日，队伍已经恢复。通讯第八页点击林睿哲的新消息，了解断网组织。"
 elseif result.completed["medical-treatment"] then result.objective="医师已经处理毒伤。等两位医师离开，在休息室诊疗区选择休息至翌日。"
 elseif result.completed["medical-notify"] then result.objective="已通知医师姐弟。返回列车→站台→C区电梯→A区左门，前往休息室治疗妮妮莉特。"
 elseif result.completed["factory-material"] then result.objective="材料已收好。通讯第八页点击通知医师姐弟，然后返回学院休息室。"
 elseif result.mission.unlocks["factory-site-secured"] then result.objective="沼泽道路已清理。向右走近砗磲贝材料点采集，随后明确通知医师。"
 elseif result.completed["factory-encounter"] then result.objective="沼泽歌声已记录。准备花妖战斗，R/歌谣按钮让乌云解除蛊惑。"
 elseif result.completed["translator-preparation"] then result.objective="行动准备已记录。目标是废弃工厂的砗磲贝，途中需警惕沼泽；出发前检查两名学员的训练成果与编队。"
 elseif result.completed["translator-request"] then result.objective="林睿哲委托采集砗磲贝。休息室右门→A区右门→备战室，走近中央的妮妮莉特与乌云，确认行动路线。"
 elseif result.completed["medical-meeting"] then result.objective="已认识忍冬与半夏。打开通讯第七页阅读林睿哲的材料委托，再回备战室与同伴准备。"
 elseif result.completed["ayan-sharing"] then result.objective="阿岩提到休息室有两位新人。训练室左门→B区左门→备战室左门→A区左门，前往休息室右侧诊疗区拜访。"
 elseif result.completed["ayan-fragment"] then result.objective="阿岩的故事碎片已记录。走近训练室中央的阿岩，继续讨论战斗记录与记忆。"
 elseif result.completed["ayan-refreshment"] then result.objective="已接过阿岩准备的食物。走近他选择聆听往事，了解他为什么来到学院。"
 elseif result.completed["mail-three-forward"] then result.objective="已将第三封邮件转给妮妮莉特。走近训练室中央的阿岩，领取训练后的食物并交谈。"
 elseif result.completed["mail-three"] then result.objective="第三封邮件已读。在通讯第五页点击转告妮妮莉特，让她保存羽凌灵的新消息。"
 elseif result.completed["liyena-recognition"] then result.objective="羽凌灵发来第三封邮件。打开通讯第五页阅读，再点击转告妮妮莉特；阿岩在训练室中央等你。"
 elseif facts.unlocks["liyena-duel-complete"] then result.objective="李叶娜对打训练已获胜。在结算继续交谈；离开后可到训练终端接续。"
 elseif result.completed["liyena-challenge"] then result.objective="李叶娜提出对打挑战。前往训练室终端，选择李叶娜对打训练。"
 elseif facts.unlocks["liyena-coop-complete"] then result.objective="合作训练已完成。在结算继续听取挑战；离开后可到训练终端选择对打。"
 elseif result.completed["ayan-tour"] then result.objective="已参观学院训练室，林睿哲邀请你与李叶娜进行合作与对打两场训练。跟随阿岩到左侧虚拟训练入口。"
 elseif result.completed["ayan-detour"] then result.objective="阿岩想了解地面的建筑师，却又带错了路。继续跟随他，在训练室听取林睿哲的安排。"
 elseif result.completed["ayan-arrival"] then result.objective="已认识建筑师阿岩。用摇杆跟随他参观训练场，走近他停下的地方再交谈。"
 elseif result.completed["energy-recovery"] then result.objective="能源已进入手环。返回列车与学院，前往训练室报告进展；中央能源记录可在通讯第四页重读。"
 elseif facts.unlocks["energy-site-secured"] then result.objective="中央道路已经安全。前往夜光镜紫色定位处，打开能源箱并收取数据。"
 elseif result.completed["energy-plan"] then result.objective="已收到遗弃城市能源定位。通过夜光镜查看路线；采用乌云与妮妮莉特各自成果后，车厢右侧把两人编入，前往中央能源箱清理伏击。"
 elseif result.completed["underground-cooperation"] then result.objective="已取得夜光镜。在休息室与乌云、妮妮莉特讨论地面计划，打开地图确认调查路线。"
 elseif result.completed["wuyun-rest"] then result.objective="第一章已记录。沿A区左门进入休息室，会见地下城的来访者，讨论合作条件。"
 elseif result.completed["ground-rescue"] then result.objective="已回到安全区域。进入学院休息室，安顿妮妮莉特并与乌云交谈。"
 elseif facts.unlocks["wuyun-rescued"] then result.objective="退路已守住。在结算继续与乌云交谈，再回学院休息室。"
 elseif result.completed["ground-contact"] then result.objective="遗弃城市的陌生强敌已记录。在前沿侦察点选择守住退路，保护辅助机并观察驱动能量。"
 elseif result.completed["ground-arrival"] then result.objective="已确认维生场。向右沿街道采集金粉，靠近前沿侦察点观察陌生强敌。"
 elseif result.completed["mail-two"] then result.objective="已读羽凌灵回信。车厢右侧出口确认编队，携辅助机进入遗弃城市。"
 elseif result.completed["train-conflict"] then result.objective="车厢争执已记录。打开通讯与日志第二页，阅读羽凌灵的第二封邮件。"
 elseif result.completed["station-brief"] then result.objective="已了解地面部署与辅助机。下一步：从集合点向左走到登车处，进入列车确认调查计划。"
 elseif result.completed["archive-discovery"] then result.objective="暗格资料已记录。准备地面调查：经D区电梯回到C区，从左侧站台通道前往地面部署集合点。"
 elseif facts.unlocks["library-lead"] then result.objective="经C区电梯前往D区，左门进入资料室；调查最里侧书柜第二层暗格。"
 else
  local training=require("Training.Progress").forCharacter("ninilite")
  local loaded=training.load()
  if not loaded then result.objective="训练记录暂时无法读取。请进入训练室检查记录状态；原成果会保留。"
  elseif training.adopted then result.objective="妮妮莉特的训练成果已采用。前往A区电梯→C区右门进入指挥室，在中央终端确认编队，守住电梯警戒线。"
  else result.objective="备战室右门→B区右门进入训练室，靠近发光终端开始示范；完成三场试战并采用成果，再前往指挥室。" end
 end
 return result
end
function Service:canRead(id,scene,replay)
 local meta=D.DB:query("SELECT schemaVersion FROM lsd.Game0StoryMeta WHERE id=1")
 if not meta or not meta[1] or meta[1][1]~=1 then return false,"INCOMPATIBLE_STORY_SAVE" end
 local node=Catalog[id]; if not node then return false,"UNKNOWN_STORY_NODE" end
 local facts,err=self:summary(); if not facts then return false,err end
 if replay and not facts.completed[id] then return false,"NOT_RECORDED" end
 if node.scene and node.scene~=scene and not (replay and facts.completed[id]) then return false,"WRONG_SCENE" end
 if node.requiresStory and not facts.completed[node.requiresStory] then return false,"STORY_LOCKED" end
 if node.requiresMission and not facts.mission.unlocks[node.requiresMission] then return false,"STORY_LOCKED" end
 if node.requiresInfiltration then
  local store,why=require("Story.InfiltrationStore").open();if not store then return false,why end
  local state,err=store:load();if not state then return false,err end
  if not state[node.requiresInfiltration] then return false,"INFILTRATION_PROGRESS_REQUIRED"end
 end
 if node.requiresRoofDuel then
  local store,why=require('Story.RoofDuelStore').open();if not store then return false,why end
  local state,why=store:load();if not state then return false,why end;if not state.completed then return false,'ROOF_DUEL_REQUIRED'end
 end
 if node.requiresRoof then
  local store,why=require('Story.RoofStore').open();if not store then return false,why end
  local state,why=store:load();if not state then return false,why end
  if state.stage~=2 then return false,'ROOF_CLIMB_REQUIRED'end
 end
 if node.requiresControlPod then
  local store,why=require('Story.ControlPodStore').open();if not store then return false,why end
  local state,why=store:load();if not state then return false,why end
  if not state.doorOpen then return false,'CONTROL_POD_DOOR_REQUIRED'end
 end
 if node.requiresResearcher then
  local store,why=require('Story.ResearcherStore').open();if not store then return false,why end
  local state,err=store:load();if not state then return false,err end
  if not state.caught then return false,'RESEARCHER_CAPTURE_REQUIRED'end
 end
 if node.requiresInfiltrationPath then
  local store,why=require('Story.InfiltrationPathStore').open();if not store then return false,why end
  local state,err=store:load();if not state then return false,err end
  if not state.completed then return false,"INFILTRATION_PATH_REQUIRED"end
 end
 if node.requiresFoxTrail then
  local trail,why=require("Story.FoxTrailStore").open();if not trail then return false,why end
  local state,readError=trail:load();if not state then return false,readError end
  if not state.departed then return false,"FOX_DEPARTURE_REQUIRED" end
 end
 if node.requiresActivity then
  local valley,why=require("Story.ValleyService").open();if not valley then return false,why end
  local activity=valley:load(node.requiresActivity);if not activity or not require("Story.ValleyRules").complete(node.requiresActivity,activity) then return false,"ACTIVITY_REQUIRED" end
 end
 return true,facts.completed[id] and "REPLAY" or "NEW"
end
function Service:completeAsync(id,scene,replay,proof)
 local allowed,err=self:canRead(id,scene,replay); if not allowed then return false,err end
 local node=Catalog[id]
 if node.foodCompletion or node.scanCompletion then
  local trail,why=require("Story.FoxTrailStore").open();if not trail then return false,why end
  local state,readError=trail:load();if not state then return false,readError end
  if node.foodCompletion and state.foodUsed~=1 then return false,"FOOD_REQUIRED" end
  if node.scanCompletion and not state.scanned then return false,"SURVEY_REQUIRED" end
 end
 local newlyPerformed=(node.finalBetrayalCompletion or node.jadeDistanceCompletion or node.jadeArrivalCompletion or node.academyLossCompletion or node.interrogationCompletion or node.controlPodCompletion or node.roofCompletion or node.roofAftermathCompletion) and not self:summary().completed[id]
 if newlyPerformed then
  local validator=node.finalBetrayalCompletion and 'Final.BetrayalProof' or node.jadeDistanceCompletion and 'Rescue.DistanceProof' or node.jadeArrivalCompletion and 'Rescue.ArrivalProof' or node.academyLossCompletion and 'Story.AcademyLossProof' or node.roofAftermathCompletion and 'Story.RoofAftermathProof' or node.roofCompletion and 'Story.RoofDialogueProof' or node.controlPodCompletion and 'Story.ControlPodDialogueProof' or 'Story.InterrogationProof'
  local ok,why=require(validator).validate(proof);if not ok then return false,why end
  if node.academyLossCompletion then
   local roster,why=require('Story.AcademyLossRecords').build();if not roster then return false,why end
   if D.json.encode(roster,false,true)~=D.json.encode(proof.roster,false,true)then return false,'RESIDENT_RECORD_MISMATCH'end
  end
 end
 local operations={
  {"INSERT OR IGNORE INTO lsd.Game0StoryNodes VALUES (?,?)",{{id,os.time()}}},
  {"INSERT OR IGNORE INTO lsd.Game0StoryUnlocks SELECT ?,id FROM lsd.Game0StoryNodes WHERE id=?",{{node.reward,id}}}
 }
 if newlyPerformed then operations[#operations+1]={"INSERT OR IGNORE INTO lsd.Game0StoryPerformances VALUES (?,?)",{{id,D.json.encode(proof,false,true)}}}end
 for _,assignment in ipairs(node.assignments or {}) do
  operations[#operations+1]={"INSERT OR IGNORE INTO lsd.Game0StoryAssignments SELECT ?,?,id FROM lsd.Game0StoryNodes WHERE id=?",{{assignment[1],assignment[2],id}}}
 end
 local granted=D.DB:query("SELECT source FROM lsd.Game0StorySupplies WHERE source=? LIMIT 1",{id})
 if node.grantSupplies and not granted then return false,"READ_FAILED" end
 if node.grantSupplies and granted and not granted[1] then
  local mentor=require("Data.Config").char=="charF" and "charF" or "charM"
  for _,recipient in ipairs({mentor,"ninilite","wuyun"}) do
   for _,item in ipairs({"first-aid-water","medicated-plaster"}) do
    operations[#operations+1]={"INSERT OR IGNORE INTO lsd.Game0StorySupplies VALUES (?,?,?,1)",{{id,recipient,item}}}
   end
  end
 end
 if not D.DB:transactionAsync(operations) then return false,"WRITE_FAILED" end
 return true,"COMMITTED"
end
function Service:assignments()
 local checked,err=Service.open();if not checked then return nil,err end
 local rows=D.DB:query("SELECT role,duty,node FROM lsd.Game0StoryAssignments ORDER BY role");if not rows then return nil,"READ_FAILED" end
 local result={};for _,row in ipairs(rows) do result[row[1]]={duty=row[2],node=row[3]} end;return result
end
return Service
