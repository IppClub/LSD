# 玉的乘坐动作制作源

原策划：配套 LSD-doc 的 `docs/source/gamedoc/characters/yu.md`，机器人下方双臂形成临时座椅并承载玉行动。人物Q版画师双程，佛陀设计周大西。

当前目录只保存原资源的编辑导出与结构核对，不是已完成乘坐动作，不被游戏运行代码引用。原始yu.skel、yu.atlas、yu.png保持不变，哈希见source-inventory.json。source-export/yu.json由本机Spine CLI从原二进制导出；original-regions.json由当前引擎同版Spine解析器读取原区域尺寸，供重新导出时核对，避免沿用其他角色的错误尺寸。

已有动作仅fmove、idle、idle1。共84个骨骼；两条腿的链分别为zong34→zong35→zong36→zong37、zong38→zong39→zong40→zong41。四个IK约束分别控制大小腿和足部，存储在JSON的constraints字段，而不是旧版ik字段。坐姿制作必须处理这四个约束，直接旋转大腿会被IK覆盖。长裙/饰带的权重链独立于腿部，必须逐帧核对膝部及裙摆，不得仅抬高整个人物来冒充乘坐。

编辑器4.3.26读取原4.3.08二进制时提示版本不同，并提示未包含nonessential网格内部编辑边；只导出成功不代表可无损回写。必须先进行原动作往返对比，再制作坐下、乘坐循环、起身/落地的动作与接触点。下方双掌应依据接触点托住坐骨/裙摆，人物随同一悬浮根节点移动；护盾恢复与武器攻击不能使座椅失稳。

后续验收：原生渲染侧面与反向、腿和裙摆轮廓、双掌接触、完整有限动作与0.2秒恢复、移动过程坐姿稳定、到达后落地恢复；再接实际研究区救援/撤离。当前长稳正在运行，尚未启动该目录的视觉预览或替换运行素材。

原动作往返几何验证：source-export/yu.json经Spine CLI导出roundtrip-export/yu.skel，与原yu.skel使用相同原atlas，在引擎同版Spine运行库按每动画121个时点比较所有绘制顶点。3个动画共515202个坐标采样，最大误差0.00124359（idle1/item15/3.31417秒），小于0.05阈值。证据Docs/evidence/2026-10-04/yu-original-roundtrip.json。仅证明此往返的几何与时长一致，不证明纹理、绘制遮挡、编辑网格完整性或新乘坐动作质量；仍未替换原运行资源。

## 改用桌面原工程（用户指出后查得）

原工程位于 `/Users/Jin/Desktop/LSD/LSD美术/Q版/Q版 spine 玉/yu.spine`，同目录有完整images与打包设置。已只读导出original-project-export/yu.json，保留84骨骼、3个原动作和35个网格的内部边信息，无二进制反向导出的缺边警告。后续制作用此原工程来源，source-export及roundtrip-export仅保留为之前的排查证据。整个桌面美术库发现88个Spine工程，清单与哈希保存在上一层desktop-spine-sources.json；原工程没有改写。

Tools/build_yu_riding.py已改用原工程导出制作独立sit/ride/stand候选。初版translate轴名大小写不符合原生解析格式，已修正为translatex/translatey，原生运行库现可读取ride姿态；尚未进行图像验收，不能用于替换游戏。原工程与现有运行atlas的比例/区域和动画一致性仍须再检查。

候选工程riding-candidate.spine及candidate-export/riding-candidate.skel已由官方CLI导入/导出成功，无缺图提示。编辑器拒绝同时存在translate及translatex/y轨道，已统一成带缓动采样的二维translate，原IK的弯曲方向保持。新增sit/stand各0.8秒、ride两秒；原动画与原运行二进制515202个坐标比较最大误差仍0.00124359。Test/YuRidingPreview.lua为待运行的独立原生对照和完整时长检查；目前没有视觉通过结论。

组合预览Test/YuBuddhaMount.lua已运行：两个相反朝向同时显示Yu候选与原BuddhaPrototype，使用下方双掌的实际父子节点坐标计算承载位置，跟随悬浮和Guard过渡。初版锚点过高使手掌靠近腰/肘，已调整到裙摆下方的承载区；截图yu-buddha-mount-guard.png。当前仍是接触研究，两个掌心局部取点与裙摆边缘需精修，并需坐上/落地过程后才能安装到救援场景。报告PASS只表示预览正常运行，没有断言视觉通过。
