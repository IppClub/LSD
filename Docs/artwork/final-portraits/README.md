# 终章立绘表演盘点

原生读取结果：女导师、林睿哲只有idle（2.6667秒）；妮妮只有idle（5.3333秒）；男导师有idle与idle1（均3.3333秒）。各角色只有default/full外观，不能把这些名字当作悲伤或愤怒表情。

FinalPortraitStudy在原生引擎取妮妮0.05、1.3、2.9、3.6秒画面对照，均为敬礼、笑脸的原绘姿态。右眼附件变化发生在约2.7333至3.3333秒；嘴部只有横向缩放。没有供终章直接使用的闭口、惊恐、悲伤嘴部附件。仅降速、冻结帧或截取前半段无法解决情绪不匹配。

source-export中四份JSON由已安装Spine官方CLI从工程原skel导出，仅作制作参考。源文件SHA及版本记录见inventory.json。编辑器4.3.26报告源数据版本差异和原文件未含网格内部边线；未找到解包图片目录。这些JSON没有替换运行时原资源。世界坐标往返对照已完成默认皮肤、每动画121个采样：女导师、男导师、林睿哲误差分别小于0.010、0.030、0.008；妮妮精确3.33333秒处附件切换存在十进制时间精度差异，前后偏移0.0001秒时几何误差均小于0.011。完整结果见roundtrip.json；这不证明所有皮肤、切换边界或动画质量合格。原附件已使用官方Spine CLI解包到ninilite-images；解包专用atlas仅移除末尾无bounds的孤立“1”，原资源未改。后续仍需恢复编辑用原附件尺寸，再修改原骨架上的姿态/脸部动作；需要补画的嘴部应匹配原画，不能压扁笑脸代替悲伤。

证据：Docs/evidence/2026-10-04/final-portrait-inventory-native.json、ninilite-portrait-native-study.tga。Test/FinalPortraitInventory.lua与FinalPortraitStudy.lua均不附加游戏数据库。

待做：妮妮中性倾听、震惊制止与坚定回应；导师受伤后说话；林睿哲严肃陈述。保持原发饰/呼吸/眨眼的自然运动，情境姿态与循环分别制作，使用recovery衔接。UI目前只接受角色而不接受表情，需要扩展对白属性并确保回看、同角色换表情、两种导师资产都有效。该项目前仍未完成。

## 闭口附件制作试验（未验收）

prototype/mouth-closed-v1.png、mouth-closed-v2.png由imagegen根据原zui.png补绘透明背景闭口嘴部。第一版过于写实、唇部厚；第二版要求纤细红褐色闭口线、减少唇色。两版均非原作者素材，保留来源区别。第二版1536×1024的细线缩小到实际立绘后出现明显断点，尚不符合原画质量，不允许用于正式表情。

Tools/build_portrait_prototype.py可重建独立预览JSON和atlas，使用相对路径引用原图集，并添加新嘴部区域，不修改原骨架文件。listenPrototype在idle基础上换嘴，第三版复用原youyan6至youyan10分层附件使双眼睁开，去掉原wink切换。仍保留敬礼，眼部暂未加自然眨眼，不能充当完成的“倾听”表情。

Test/FinalPortraitPrototype.lua在原生引擎并排显示原立绘和新附件，证据为Docs/evidence/2026-10-04/final-portrait-mouth-prototype.tga。最初atlas绝对路径被错误拼接导致右侧资源缺失，已修复为相对路径并重新截图；目前截图右侧真实显示新附件。该测试不访问存档，也没有验证完整情绪演出。下一步需重制适于最终显示尺寸的清晰闭口线、补齐眼神与放下敬礼手臂的原骨架姿态，再进行正式对白接入。

### 第三版原生预览

mouth-closed-v3.png继续通过imagegen补绘，要求连续较厚的不透明嘴线，以改善约35像素显示宽度下的断点。原生并排截图已确认新素材和双眼睁开附件均真实显示；嘴线比第二版连续，但形状偏平，仍未验收。对照截图分别保存在final-portrait-mouth-v2.png、final-portrait-mouth-v3.png，避免以最新版覆盖版本间证据。

渲染排查：Spine使用默认Sprite效果，fs_sprite.sc直接采样颜色与alpha，没有alpha阈值丢弃；AtlasCache的SpineTextureLoader也未应用atlas的filter字段。因此不能靠改atlas过滤声明宣称解决。当前优先使素材在实际像素尺寸可读，未修改引擎渲染或原游戏素材。

### 放下手臂与眨眼候选动作

新增listenCandidate制作样本。先比较肩肘70/140、90/160、110/180度偏移，发现单纯旋转造成肩部尖角与上臂被身体遮住。第二轮采用85/180度并比较腋下边缘顶点3、4沿所属骨骼局部X的0/100/180变形，选择100作为候选。变形仅写入新动作的网格时间线，保留原UV和原文件；不能把该方案视为所有姿态通用修复。角度与局部变形两轮截图分别为final-portrait-arm-angles.png、final-portrait-arm-deform.png。

候选保留原呼吸、头发、飘带，增加微小手臂摆动。第一次眨眼直接缩放整个眼部，会一并压扁眉毛；已追加独立眉毛/上睫毛骨骼，保持眉形，上睫毛下移闭合并保留弧度。新增骨骼追加在数组末尾，不改变原加权网格骨骼编号；原项目资产仍不受影响。prototype中的槽位重绑定仅为候选制作，不能把整份JSON直接当作原idle的等价替代。

FinalPortraitMotion原生完成两个循环，实际间隔5.33357秒，动作声明5.33333秒，recovery为0.2。open/blink/reopen/loop四张原生截图已逐一检查；眉毛在闭眼时保留，睁眼恢复正常，手臂无明显脱节。PASS_TIMING_ONLY明确只证明时长循环，不代表全部美术验收。未使用数据库，没有进行OS玩家操作。嘴线偏细偏平，肩部接缝仍需正式对白尺寸检查，表情语义和recovery切换画面尚待验证；仍未接入正式对白。证据final-portrait-motion-native.json。

### 正式对白布局与鼠标检查

Test/FinalPortraitDialogue.lua把候选仅注入测试进程的UI.StoryPortrait，使用真实UI.Story和终章三句台词。1792×1136渲染区下实际立绘比例0.33433，面部未被对白遮住。真实CUA鼠标完成三句、打开回顾、返回与结束；QA数据库逐表与来源比较不变。主存档没有打开。此结果不代表全15句或各屏幕比例已经验收。证据final-portrait-dialogue-os.json。

该过程发现并修复正式UI/ReviewSentence.xml姓名栏固定220导致“妮妮莉特”换行的问题：姓名不强制换行，正文起点按实际姓名宽度留间距，长姓名在限宽内缩放。生成Lua通过引擎xml.tolua同步。再次真实鼠标检查，姓名保持一行且正文分列清楚，证据final-portrait-review-fixed.tga。

同时发现原idle的youyan6/youyan7网格变形仍会在2.7至3.3秒附近挤压单眼；listenCandidate已移除这两条继承变形，保留新眨眼。补充idle→listenCandidate的recovery过渡三张采样，确实出现中间肩肘姿态并最终放下手臂；循环仍为5.33346秒。这只覆盖已采样过渡，不等于全部情绪动作验收。证据final-portrait-recovery-native.json。候选未进入正式剧情资源，嘴形细线和肩部接缝的最终美术完善仍未完成。
