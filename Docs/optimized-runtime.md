# macOS 优化运行构建与性能验收

2026-10-10：本页记录的测试运行时及其构建产物已清理，以下路径为历史记录；再次测试须重建匹配运行时。

## 原界面单档往返长测（2026-10-09，终局通过）

`Test/ProductionReturnSoakNative.lua`仅执行一次Start并attach一个合法历史检查点副本，通过原列车部署、清障任务、成功结算按钮返回列车重复。没有QA根Cleanup重置、直接清场或每轮重新加载检查点；生产Navigation负责切换场景。当前冻结为`2026-10-09-full-content-battle-input-candidate`。终局58轮、1818.52秒及独立SQL审计通过，证据`evidence/2026-10-09/production-return-long`。只覆盖清障这一原任务循环。

只读审计入口：

```sh
python3 Tools/audit_production_return_soak.py --result Test/production-return-soak-result.json --run /private/tmp/lsd-battle-input-production-return-soak-20261009/run.json --output /private/tmp/lsd-battle-input-production-return-soak-20261009/prefix-audit.json --allow-running
```

运行中只接受已通过原结算返回的轮次；SQL一致快照还单独核算下一轮预算预留和已提交但未返回的结果。终局用归档result.json并去掉`--allow-running`，才检查运行器PASS、无active账单、包加载隔离及文件保持。脚本验证每轮真实消费、库存、退款、episode、父档模型和旧账。

场景、对象、Lua引用及回调趋势和帧时间单独审阅。夹具`cycles`保留每轮完整报告，观测表本身持续增长；LuaKB增加不能单独作为游戏泄漏或无泄漏证明。前缀中的平稳对象数也不能替代终局检查。此测试覆盖一条原任务往返，不代替三章所有场景、真实OS操作、全部结局或视听验收。

审计输出`lifecycleObservations`记录对象/引用/场景/LuaKB的首末值与范围、观察器保留的报告数量及序列化字节数，并按阶段汇总超过33.3毫秒的帧。报告字节数不是Lua实际分配估算；帧采样包含观察器序列化工作，慢帧列表最多保留100条。21轮前缀中场景均1、对象907–908、Lua引用114、回调235；LuaKB增加667.26，观察器保留21份报告、序列化约121KB。四条慢帧均发生在初始加载或首轮，最大126.20毫秒。这些是运行中观测，终局仍需重新核对。

2026-10-05：当前 Dora xmake 图中，默认 macOS Debug 和 Release 的 Lua VM 编译记录均未包含优化参数。不能只看构建目录名称判断运行性能。

## 可重复构建

在游戏工程运行：

```sh
python3 Tools/build_optimized_runtime.py --engine /Users/Jin/Workspace/Dora-SSR --output /private/tmp/lsd-runtime-release
```

脚本使用独立 xmake 配置/输出，显式传入 `--cxflags=-O3`，验证 `lvm.c` 的实际编译参数，并记录源码版本、二进制 SHA-256、原配置与源码是否保持不变。构建后输出应用位置。脚本不打开游戏存档、不发布、不替换系统应用；这是本机 macOS ARM64 的构建步骤，不代表其他平台已验收。

## 已验证范围

- 原版 Release 与显式优化版使用同一引擎源码、同一游戏代码。完整元数据见 `evidence/2026-10-05/release-engine-manifest.json` 和 `optimized-engine-manifest.json`。
- 真实战斗输入回放：390 个瞄准查询、2802 次地形回调，优化版与原结果一致；总耗时 0.79461→0.23962 秒，单帧瞄准峰值 27.93→11.42 ms。它证明计算耗时下降，不等于完整游戏帧率结论。
- 优化版近距训练 3117 帧，最大 16.68 ms；野外训练 1537 帧，最大 17.42 ms；均无超过 33 ms 的长帧，两场自然胜利、候选不变、训练来源可重建。均使用明确命名的隔离 QA 存档。
- 正式战斗 HUD 2591 帧，最大 16.68 ms，无超过 33 ms；36 次射击、35 次命中并自然获胜。为脚本驱动控制器测试，不等于 OS 输入全流程（`optimized-hud-performance-result.json`）。
- 原生几何回归通过。其余场景、长时间体验、真实输入和其他平台仍需验收；此前 Debug 的 267.56 ms 异常不因这两场通过而被抹去。

后续性能报告必须注明实际应用路径、二进制哈希与编译优化证据。最终游戏候选包应使用已经验收的优化构建，不能重新混用未优化的默认运行器。

## 隔离运行战斗验收

构建完成后，用该构建目录的 `manifest.json` 启动测试：

```sh
python3 Tools/run_combat_qa.py --runtime-manifest /private/tmp/lsd-runtime-release/manifest.json --test cycles --evidence Docs/evidence/combat-cycles-new-run
```

`--test` 可选 `geometry`、`aim-replay`、`training`、`hud`、`cycles`、`lanes`、`lane-shots`、`attribution`、`disarm`、`medium-flow`、`medium-pressure`、`small-combat`。证据目录必须是新目录。运行器校验二进制哈希、优化编译记录及运行前后的游戏 Lua 文件指纹；检测到其他 Dora 进程时拒绝并行启动。每次创建独立 QA 存档目录，保存结果、进程日志与版本清单。

`cycles` 连续执行六场近距/野外冻结候选评价，检查来源重建、候选不变和旧战斗释放，并记录帧时间及对象/回调数量。结果中的内存趋势仍需审阅；测试通过不代表所有场景或最终发行包长稳通过。出现失败后保留证据，修复后换新目录重跑，不覆盖原失败记录。

## 本次原返回终局帧时

109088帧，均值16.670毫秒、P95/P99 16.7毫秒、最长126.20毫秒；6条超过33.3毫秒，包含第34轮部署45.12毫秒、第43轮战斗34.65毫秒。场景数始终1，对象906–908，Lua引用114，回调235；LuaKB2165.80→4061.25，夹具保留58份完整报告。终局不认定全部游戏内存或全任务稳定。原报告和阶段慢帧完整保留；上文21轮数字属于当时前缀。
