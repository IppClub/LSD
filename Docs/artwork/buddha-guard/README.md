# 佛陀守护者素材与动画样机

原设计：LSD-doc/docs/source/img/design/character/yu-buddha-d.jpg，画师周大西。人物要求：六臂、白金装甲、光环、下方推进器、双手托举玉、生成护罩。

2026-10-04使用内置image_gen生成，非CLI。parts-v1.png为初稿，parts-v2.png为修订稿；原图保留，未覆盖历史素材。生成素材是基于原设计的衍生制作，不标为原画师交付。

最终修订提示词：

Edit this rigging atlas. Keep same 1536x1024 pixels 3 columns 2 rows, same robot design, colors and clean ink cel shading. Correct only rigging geometry and transparency. Each component must lie INSIDE its 512x512 cell with at least 35px transparent margin. Top-left central body must be reduced to 420px tall, centered at (256,256). Top-middle upper arm: DELETE the existing long lower forearm extension beneath its gold elbow ring. Show ONLY one upper arm segment shoulder ball to elbow ball, white ceramic shell gold trim, a single rigid section length 230px centered in cell (768,256). Top-right forearm remains single rigid segment, centered in cell (1280,256), length260px. Bottom-left open hand centered (256,768), height280px. Bottom-middle cupped hand centered (768,768), width300px. Bottom-right halo centered (1280,768), diameter400px. Absolutely no background gradients or smoky shadows surrounding the components; every pixel outside component silhouettes must have alpha zero, except a narrow 5px glow just at halo rim. NO overall glow, no text, no layout lines. Preserve white/gold Buddha robot body without arms, with twin grey thrusters and burgundy hanging panel. All parts have complete uncut outlines. This is a transparent component texture for skeletal animation, not a presentation illustration.

初稿生成要求：3×2透明分格，主体无手臂、上臂、前臂、张开手掌、托举手掌、光环；忠实原白金/黑色关节/红色垂饰，Q版比例和清晰赛璐璐描边。

运行：Test/BuddhaPrototype.lua（独立预览）、Test/BuddhaWardView.lua（护盾联动）。运行图集为Image/Rescue/buddha-guard-parts.png，与parts-v2.png内容相同。当前支持六条父子关节链、悬浮、光环、Guard切换平滑插值，并接入研究区初次救援和双子撤离战斗。显示层读取Ward状态，0.6秒召唤、0.4秒收回，实际吸收伤害时闪光；不修改伤害、范围或容量。托举乘坐、武器攻击、最终关节轮廓和美术品质仍未验收，不得称为最终高质量动画已完成。

样机第二轮：肩根收回躯干，上中两对手臂置于身体后方；下方手掌朝内且抵消肩肘角保持水平。Guard/idle切换采用固定0.2秒smoothstep过渡，相同状态不重启。BuddhaRig原生测试四次过渡、264帧父子链及托掌水平通过。此为结构/状态检查，不证明贴图关节像素完全贴合，该轮尚未放入正式场景，后续联动接入见上文。


## 2026-10-04 玉 Q 版风格对齐候选 v3

重新读取桌面原始 `Q版/Q版 玉.psd`、`设计/角色设计稿/新人设/玉 v3.png` 与 `玉 v3 佛陀.png`。旧版佛陀小头长脸、饱和金色和硬高光，与玉的大头和柔和浅杏金不一致。内置 image_gen 生成 `Docs/artwork/buddha-guard-chibi-v3.png`；完整提示词、来源和工具记录见 `Docs/artwork/buddha-guard/chibi-v3-generation.json`。

`Test/YuBuddhaStyle.lua` 在原生引擎同时展示旧版和新版，复用玉实际 Spine 乘坐候选及机器人 Guard 过渡。新版素材上下排分界实际为 576，因此预览使用独立取图范围；躯干比例 .65、上移 40，光环比例 .85、上移 80。BuddhaPrototype 新增可选样式参数，默认生产素材和参数不变。

原生运行 1791093559：142 帧，加载及状态切换 PASS。证据 `Docs/evidence/2026-10-04/yu-buddha-style-v3-native.json`、`yu-buddha-style-v3-guard.png`。人工看图确认配色、圆脸和光环较前版更接近玉；肩根存在缝隙，六臂尺寸与新躯干仍需适配，托掌接触、遮挡、镜像和完整乘坐生命周期未通过视觉验收。此图是候选，未替换正式场景，不代表 Game 0 美术完成。


## 2026-10-04 佛陀 v3 关节注册与乘坐生命周期

新版图集按实际肩、肘、腕中心注册：上臂锚点 (278,473)/512×576，肘偏移 (4.5,-95.5)，前臂锚点 (226,430)/512×576，腕偏移 (7.5,-90.25)，左右肩根分别适配三分之四视图。候选参数集中于 `Test/BuddhaChibiStyle.lua`，生产默认图集不变。原生对照截图显示肘腕错位减少，但六臂根部遮挡及造型仍需视觉复核。

`Rescue/BuddhaCarrier.lua` 等自身调度进入后才启动有限动作，避免新场景首帧影响；等待原生完成事件及完整片长两者均满足才切换循环。支持 sit→ride→stand→idle，返回 idle 使用 recovery .2；重入返回 BUSY，移除节点后中止并返回 CLOSED。候选样式参数可传入，便于与同一玉资源验证。

旧测试将 recovery 与 .2 直接相等比较，实际原生读回 0.200000002980232，已改为浮点容差并报告落地状态。此次测试移除外部 .05 秒预热，直接创建后坐上；原生 1791093747 通过两轮移动护盾、坐上/落地（各约 .816 秒）、恢复原点/idle，以及中途移除和重入拒绝。落地图片中机器人消失、玉站回地面，乘坐图片仍需进一步检查裙摆接触。证据 `Docs/evidence/2026-10-04/yu-carrier-lifecycle-native.json`、`yu-carrier-riding-1.png`、`yu-carrier-landed.png`。这是独立组件测试，尚未接入真实救援关卡，不代替完整模拟游玩或最终美术验收。


## 实际双子救援接入（2026-10-04，验证进行中）

新版图集现已安装到 `Image/Rescue/buddha-guard-chibi.png`，玉乘坐动画安装到 `Spine/StoryActions/yu-riding.json`；源图、导出内容与 SHA-256 见 `runtime-carrier-manifest.json`。`Rescue/Battle` 使用唯一 BuddhaCarrier：开始护送后坐上，乘坐移动到 x=4650，在同一个机器人上表现护盾及吸收脉冲，战斗结算前完成落地并关闭护盾。没有隐藏第二个玉演员，也不再单独生成战斗 wardView。初次会面 Arrival 暂时仍用旧表示，后续需统一。

首次实战运行 1791093902 在两段敌人全部击败后仍失败：双子位置 5398.6494、5559.0659，前者距离目标 1.3506，但可用间距 .4165 低于原 .5 起步门槛，后者又已在 1 像素到达容差内，导致死锁直至 240 秒超时。已将可用间距起步门槛收至 .001，保留原速度上限和不重叠间距约束。失败证据保存在 `carrier-evacuation-spacing-failure.json`。真实关卡截图 `carrier-battle-live.png` 证明乘坐及护盾显示已进入战斗，但不证明整场成功。


## 2026-10-04 佛陀乘坐接入实际救援与出口死锁修复

`Rescue/Battle` 使用单一 BuddhaCarrier，取代战斗中的独立玉演员和 wardView。坐上完整播放后以原移动速度前进到 x=4650，护盾状态和受击脉冲绑定同一个机器人，结算前完成落地。正式资源位于 `Image/Rescue/buddha-guard-chibi.png`、`Spine/StoryActions/yu-riding.json`，无 Docs 运行依赖；来源和散列见游戏 `Docs/artwork/buddha-guard/runtime-carrier-manifest.json`。初次会面 Arrival 仍用旧表示，后续需统一。

首次真实救援测试 1791093902 揭示既有到达死锁：后一名双子在 1 像素到达容差内停止，前一名剩余 1.3506 像素却只剩 .4165 可用间距，低于 .5 起步门槛，敌人清空后仍超时。改为 .001 起步门槛，保留间距约束和速度上限。失败原始记录保存在 `Docs/evidence/2026-10-04/carrier-evacuation-spacing-failure.json`。

随后 `JourneyFreshTwinsEvacuation` 原生运行 1791094175 PASS：两段撤离 35.65 秒，双子终点 5399.064/5559.482，最低间距 160.4165，生命 100/48。sit 约 .810 秒、stand 约 .814 秒，均覆盖 .8 秒片长；结算后 carrier 为 ground，护盾 2 次吸收对应 2 次脉冲。位置门禁、非法证明拒绝、写入失败重试、幂等结算、队伍更新及返回研发室检查均通过，原有表保持。使用独立 QA 数据库，不修改用户主存档。

证据 `Docs/evidence/2026-10-04/carrier-rescue-route-native.json` 和 `carrier-battle-live.png`。测试由游戏内控制事件驱动，osInput=false，不能代替真实键鼠/触控测试。六臂最终视觉品质、会面与战斗的视觉统一、全流程 OS 游玩及其他 Game 0 验收项仍未完成。


## 2026-10-04 初次会面与战斗造型统一

研发室 `Rescue/Arrival` 改用与双子战斗相同的 BuddhaCarrier 和正式素材。未完成救援时玉在佛陀托掌上播放 ride 循环；已完成救援的读档返回保持 ground，玉站在支撑点，机器人透明度为 0。移除该场景旧的独立玉演员和 wardView，避免重复显示。初次会面的护盾有效范围与剧情门禁保持由原有逻辑负责。

原生 `JourneyFreshJadeArrival` 1791094408 PASS：从 PassageA 经 PassageC、PassageD 实际移动进入 RDRoom，障碍阻挡、12 行交谈、1.216 秒开通道、存档失败重试、重复阅读不写入、重新载入骑乘及循环均通过。截图发现菜单挡脸，随后将未救援时的菜单向左偏移 160；位置交互门禁不移动，最终截图待复核。

衔接上述新 QA 存档运行 `JourneyFreshTwinsEvacuation` 1791094500 PASS：完整战斗、结算和返回后 carrier 确认为 ground，机器人收起；护盾两次脉冲、保存重试及幂等检查通过。证据为游戏 `Docs/evidence/2026-10-04/carrier-arrival-route-native.json`、`carrier-arrival-return-native.json`、`carrier-arrival-restored.png`。仅游戏内控制事件模拟，尚不算 OS 操作验收；所有运行使用隔离 QA 数据库。

菜单最终复核：原生运行 1791094614 再次通过初次会面路线；`carrier-arrival-menu.png` 确认菜单在佛陀左侧，不再遮挡面部，`carrier-arrival-menu-native.json` 保留完整结果。此次仍为游戏内事件驱动，非 OS 点击验收。
