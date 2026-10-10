# 中英招武器挂点派生资源

来源见source-inventory.json：桌面原始Spine工程只读导出，原工程SHA256不变。source-export保留原工程导出JSON；zhongyingzhao-weapon.json/.spine为可编辑派生工程，export与Spine/zhongyingzhao-weapon.skel为新增运行资源，使用原zhongyingzhao.atlas与图片，未替换原skel。

Tools/build_yingzhao_weapon.py在bone52添加held-weapon/s:pistol挂点，坐标(-100,-25)、角度24度，放在zhuazhiyou之前，让手覆盖握把。逐帧重编码drawOrder，去掉新增挂点后保持原附件顺序。测试使用原kineticgun PT，scaleX=0.3/scaleY=-0.3；原模型默认朝左，左右反转均已验证枪口朝向。其他枪型需要独立握持检查。

14个原动画、每个121姿态的原网格对照共2737532个坐标，最大误差0.00280762，小于0.05阈值；不把坐标对照当作所有美术质量完成。原生gunidle/shoot双向完整播放和枪口方向通过，持枪/射击截图已查看。

抢夺、武器临时转移/归还和原持有者禁射已有原生专项证据；实际子弹和按距离选择持械射击已有专项证据；公开缴械演练已接入；完整AI及整场受击压制/距离平衡仍未完成，不将派生资源当作完整敌人交付。

## 前臂瞄准控制

新增中性骨骼 `weapon-aim`，位于 bone13 与 bone14 之间。仅把原前臂的平移搬到父控制骨骼，保留原旋转和动画；对加权附件重映射骨骼索引。运行时可设置局部旋转，使前臂、手和挂载枪械一起俯仰。默认旋转0。退出瞄准时需恢复到0，不能把偏转遗留到后续动作。

与加入瞄准骨骼前的派生资源对照，全部原动画共2740920个坐标最大误差0.0000915527，低于0.05阈值。见 `Docs/evidence/2026-10-05/medium-yingzhao-aim-geometry.txt`。原桌面Spine工程的SHA256复核不变。`Test/MediumYingzhaoAimNative.lua`负责双向枪口方向、瞄准和连续动作校准；这是瞄准资源验证，不代表弹丸或敌人射击AI已接入。

控制器现已在shoot前摇接入半量反馈瞄准，约1/3秒沿实际枪口发射弹丸；取消/结束逐步恢复控制骨骼。动力/EMP弹丸语义与原工厂武器配置共用，详见 `Test/MediumYingzhaoShootNative.lua`。EMP握持的最终视觉审阅仍待补齐。
