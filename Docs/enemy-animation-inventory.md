# 敌方骨架动作核对

日期：2026-10-04。以下由当前引擎自带Spine库解析原始二进制得到，不代表视觉或战斗验收。命中点仍需姿态校准。

| 骨架 | 动画数 | 带attack事件的动画 | 多段技能核验重点 |
| --- | --- | --- | --- |
| xiaotaotie | 13 | blow, bomb, butt, swing | rollStart/rollEnd之间的滚动持续段 |
| dataotie | 16 | 无，需校准 | rush至rush3的阶段职责 |
| xiaoshanxiao | 12 | 无，需校准 | 核对命中次数、姿态及完整收招 |
| dashanxiao | 12 | 无，需校准 | ambush1/ambush2消失及落地 |
| xiaohuli | 11 | 无，需校准 | 核对命中次数、姿态及完整收招 |
| dahuli | 25 | 无，需校准 | slice/parry/hormone/blade/ninja多段 |
| xiaohuayao | 10 | 无，需校准 | 核对命中次数、姿态及完整收招 |
| dahuayao | 15 | 无，需校准 | seed/transv多段 |
| xiaoyingzhao | 13 | 无，需校准 | jump至jump4扑击过程 |
| zhongyingzhao | 14 | 无，需校准 | rob至rob4缴械过程 |
| dayingzhao | 15 | 无，需校准 | hero至hero3冲刺过程 |

原始时长与事件见游戏工程Docs/evidence/2026-10-04/enemy-timelines.json及.tsv；解析工具Tools/audit_enemy_timelines.cpp，动作名称契约Script/Enemy/Assets.lua。契约中的分段列表用于完整性核查，顺序和循环职责未经姿态核实，不可直接作为技能实现。

原生Test/AllEnemyAssets.lua正在独立实例执行全部有限动画，检查资源加载、所需动作存在、AnimationEnd和实际耗时；报告Test/all-enemy-assets-result.json。运行未结束，不计PASS。该测试不包含实际攻击伤害，也不能替代Boss玩法。
