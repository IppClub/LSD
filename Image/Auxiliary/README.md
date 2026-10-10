# 原辅助机美术与模型

作者：周大西。来源：LSD-doc `docs/source/gamedoc/setting/machine.md` 与 `docs/source/img/machine/{d,a,s}-machine.png`。三份 PNG 是未经修改的原始透明分件，哈希记录在 manifest.json。

在游戏根目录运行 `python3 Tools/build_auxiliary_models.py`（需要 Pillow），重建三套 Dora clip/model 与可编辑 manifest。每个关节的原图像素矩形、锚点、位置、动画用途和原生遮罩几何均可追踪；时间轴定义在生成器内。PNG 只读取与复制，透明度分析只产生模板几何。

正式加载使用 `Ground.AuxiliaryModel.create(variant)`，保持分件顺序并应用随关节变换的原生 ClipNode 遮罩，避免原图相邻零件混入。`Ground.AuxiliaryActor` 管理完整动作结束、恢复、终姿和实际维生负载表现；`Ground.SupportView` 放入原场景。原图同时有整机示意，未把整张设计页当作游戏模型。

variant: defence / cargo / mobility。三套各含 deploy / idle / move / collect / shield / hit / carry / depleted / lose。原生引擎设置 recovery=0.2；collect 和 shield 具备表现事件，资源收入不依赖动画重复回调。

最终图稿修订：护盾机17、装备机19、悬浮机12个组件。传感器前后侧使用原裁切拆层，补回脚掌、连接臂、履带纹理、前壳与导管，修正遮挡与锚点；PNG 字节保持不变。装备机图稿为挡板展开状态，游戏待机的后挡板和右箱盖应关闭，采集/carry时才展开并完整复位。行程与关节从属见生成器和 manifest；原生同尺度对照入口 `Test/AuxiliaryAssembly.lua`，接缝与关闭验收入口 `Test/AuxiliaryJoints.lua`。
