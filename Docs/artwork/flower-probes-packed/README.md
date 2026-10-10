# 花妖骨骼探针合并

运行资源已采用此导出。每骨骼保留 o/x/y 三个点，合并为一个槽位；未简化网格或仿射计算。

重建顺序：运行 `Tools/build_flower_hitboxes.py` 生成未合并源，再运行 `Tools/pack_flower_probes.py` 使用本机 Spine 导入/导出。两工具都不会自动覆盖运行资源。验证后将 `export/dahuayao-probes-packed.skel` 复制到 `Spine/dahuayao-hitboxes.skel`，将 `regions.json` 复制到 `Data/Combat/flower-regions.json`；同步更新花妖 manifest 哈希。

`baseline/` 保留接入前资源供对照，不作为游戏运行资源。`Test/FlowerPackedProbesNative.lua` 对照 15 个动画、双向 360 个姿态及父节点旋转/非均匀缩放，比较 604800 个坐标，误差为零。200 次交替采样总耗时旧版 0.81130 秒、新版 0.61406 秒；这是采样开销，不是整场帧率收益。

原模型至导出模型的网格对照覆盖 5248980 个坐标，最大误差 0.00683594（门槛 0.05）。视觉质量仍以原动画及最终同场审阅为准。
