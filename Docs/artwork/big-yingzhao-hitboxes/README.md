# 大英招部位护甲派生素材

来源是游戏当前 `Spine/dayingzhao.skel`，原始 skel/atlas/PNG 和桌面工程均保留。`runtime-source.spine` 是当前运行二进制导入项目；`dayingzhao-hitboxes.spine` 为可编辑的派生项目。生成脚本为 `Tools/build_big_yingzhao_hitboxes.py`。

41 块原网格轮廓归并六个逻辑部位，42 组骨骼仿射采样点随动画移动。头发、尾部装饰、斧和灯光不属于身体命中区域。原眼白 deform 完整保留，不进入护甲采样。

`Tools/verify_big_yingzhao_hitboxes.cpp` 使用引擎的 Spine 运行库，比较原/派生骨架所有原美术网格及新增点还原的轮廓；结果见 `parity-result.txt`。原生验证入口 `big-yingzhao-armor`，双向对齐图和结果在 `/private/tmp/lsd-big-yingzhao-armor-overlay-20261006`。

生产加载器已用新骨架，仍保持原尺寸；`Enemy.BigYingzhaoArmor` 提供分区伤害和显隐门控。正式任务弹丸、地形遮挡、预算、学习数据与难度尚未完成整合，不因素材与适配器测试通过而视作完整 Boss 验收。
