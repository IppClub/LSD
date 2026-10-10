# 《灵数奇缘》开发文档入口

更新：2026-10-09。开发目标是保留已经制作的三个章节、场景、任务、角色与全部既有结局，完善接入现有战斗并达到完整可玩质量。Q版狐狸不训练。

策划和开发状态集中维护在配套LSD-doc网站工程，本目录保存美术制作资料与精简验证结论。

- [当前进度](../../../github/LSD-doc/docs/source/development/game0/progress.md)：当前候选、未关闭问题和下一动作。
- [完整可玩版迭代方案](../../../github/LSD-doc/docs/source/development/game0/mvp-playable-plan.md)：三章范围、实施顺序和最终交付条件。
- [战斗接入矩阵](../../../github/LSD-doc/docs/source/development/game0/battle-integration-matrix.md)：原任务入口、战斗、结算、剧情返回和保存。
- [当前验收](../../../github/LSD-doc/docs/source/development/game0/acceptance-current.md)：区分专项、脚本回归、真实操作与整体交付。
- [候选包](../../../github/LSD-doc/docs/source/development/game0/candidate-package.md)：冻结版本、引擎、资源、签名和运行证据。
- [资源机制](../../../github/LSD-doc/docs/source/development/game0/resource-economy.md)、[Boss专项](../../../github/LSD-doc/docs/source/development/game0/enemy-boss-iteration.md)、[全部结局路径](../../../github/LSD-doc/docs/source/development/game0/ending-paths.md)：对应设计与缺口。
- [历史索引](../../../github/LSD-doc/docs/source/development/game0/progress-history.md)：旧版本与失败记录，旧“当前”状态不作为最新结论。

上述链接对应本机`Workspace/Dora/LSD`与`Workspace/github/LSD-doc`布局；独立克隆时需另取LSD-doc工程。开发章节入口为`docs/source/development/game0/index.md`。本轮网站修改尚未发布。

已有三章脚本主路径和多个专项运行记录；正式Boss可玩性、真实连续游玩、全部既有结局、视听及同版本稳定性继续验收。具体状态以当前进度为准，避免在本页重复维护一份容易过期的进度表。

复用学院漫游到训练室/虚拟训练场、原统一操作UI、教程瞄准预览/弹道、实际训练成果和专用胜败结算。任务预算、实际消耗、退款、净收益及存档由原流程衔接；每场的快捷键以画面提示和候选包附带的游玩说明为准。

开发QA只使用隔离存档，正式`lsd.db`不改；同一时间仅运行一个原生游戏测试。冻结候选保持不可变，修复在源码完成后另建候选。`Test`包括受控、脚本与人工操作入口，不能将受控PASS当作正式任务通关。

验证记录仅保留[精简结论](evidence/summary.md)。原始证据、构建候选和测试中间产物已清理；美术源工程见`artwork/`，历史文档里的附件路径仅用于说明当时验证范围。
