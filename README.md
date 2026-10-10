# 《灵数奇缘》游戏项目

[![IppClub](https://img.shields.io/badge/I%2B%2B%E4%BF%B1%E4%B9%90%E9%83%A8-%E8%AE%A4%E8%AF%81-11A7E2?logo=data%3Aimage%2Fsvg%2Bxml%3Bcharset%3Dutf-8%3Bbase64%2CPHN2ZyB2aWV3Qm94PSIwIDAgMjg4IDI3NCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWw6c3BhY2U9InByZXNlcnZlIiBzdHlsZT0iZmlsbC1ydWxlOmV2ZW5vZGQ7Y2xpcC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kO3N0cm9rZS1taXRlcmxpbWl0OjIiPjxwYXRoIGQ9Im0xNDYgMzEgNzIgNTVWMzFoLTcyWiIgc3R5bGU9ImZpbGw6I2Y2YTgwNjtmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Im0xNjkgODYtMjMtNTUgNzIgNTVoLTQ5WiIgc3R5bGU9ImZpbGw6I2VmN2EwMDtmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Ik0yNiAzMXY1NWg4MEw4MSAzMUgyNloiIHN0eWxlPSJmaWxsOiMwN2ExN2M7ZmlsbC1ydWxlOm5vbnplcm8iLz48cGF0aCBkPSJNMTA4IDkydjExMmwzMS00OC0zMS02NFoiIHN0eWxlPSJmaWxsOiNkZTAwNWQ7ZmlsbC1ydWxlOm5vbnplcm8iLz48cGF0aCBkPSJNMCAyNzR2LTUyaDk3bC0zMyA1MkgwWiIgc3R5bGU9ImZpbGw6I2Y2YTgwNjtmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Im03NyAyNzQgNjctMTA3djEwN0g3N1oiIHN0eWxlPSJmaWxsOiNkZjI0MzM7ZmlsbC1ydWxlOm5vbnplcm8iLz48cGF0aCBkPSJNMTUyIDI3NGgyOWwtMjktNTN2NTNaIiBzdHlsZT0iZmlsbDojMzM0ODVkO2ZpbGwtcnVsZTpub256ZXJvIi8%2BPHBhdGggZD0iTTE5MSAyNzRoNzl2LTUySDE2N2wyNCA1MloiIHN0eWxlPSJmaWxsOiM0ZTI3NWE7ZmlsbC1ydWxlOm5vbnplcm8iLz48cGF0aCBkPSJNMjg4IDEwMGgtMTdWODVoLTEzdjE1aC0xN3YxM2gxN3YxNmgxM3YtMTZoMTd2LTEzWiIgc3R5bGU9ImZpbGw6I2M1MTgxZjtmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Im0yNiA4NiA1Ni01NUgyNnY1NVoiIHN0eWxlPSJmaWxsOiMzMzQ4NWQ7ZmlsbC1ydWxlOm5vbnplcm8iLz48cGF0aCBkPSJNOTMgMzFoNDJsLTMwIDI5LTEyLTI5WiIgc3R5bGU9ImZpbGw6IzExYTdlMjtmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Ik0xNTggMTc2Vjg2bC0zNCAxNCAzNCA3NloiIHN0eWxlPSJmaWxsOiMwMDU5OGU7ZmlsbC1ydWxlOm5vbnplcm8iLz48cGF0aCBkPSJtMTA2IDU5IDQxLTEtMTItMjgtMjkgMjlaIiBzdHlsZT0iZmlsbDojMDU3Y2I3O2ZpbGwtcnVsZTpub256ZXJvIi8%2BPHBhdGggZD0ibTEyNCAxMDAgMjItNDEgMTIgMjctMzQgMTRaIiBzdHlsZT0iZmlsbDojNGUyNzVhO2ZpbGwtcnVsZTpub256ZXJvIi8%2BPHBhdGggZD0ibTEwNiA2MCA0MS0xLTIzIDQxLTE4LTQwWiIgc3R5bGU9ImZpbGw6IzdiMTI4NTtmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Im0xMDggMjA0IDMxLTQ4aC0zMXY0OFoiIHN0eWxlPSJmaWxsOiNiYTAwNzc7ZmlsbC1ydWxlOm5vbnplcm8iLz48cGF0aCBkPSJtNjUgMjc0IDMzLTUySDBsNjUgNTJaIiBzdHlsZT0iZmlsbDojZWY3YTAwO2ZpbGwtcnVsZTpub256ZXJvIi8%2BPHBhdGggZD0iTTc3IDI3NGg2N2wtNDAtNDUtMjcgNDVaIiBzdHlsZT0iZmlsbDojYTgxZTI0O2ZpbGwtcnVsZTpub256ZXJvIi8%2BPHBhdGggZD0iTTE2NyAyMjJoNThsLTM0IDUyLTI0LTUyWiIgc3R5bGU9ImZpbGw6IzExYTdlMjtmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Im0yNzAgMjc0LTQ0LTUyLTM1IDUyaDc5WiIgc3R5bGU9ImZpbGw6IzA1N2NiNztmaWxsLXJ1bGU6bm9uemVybyIvPjxwYXRoIGQ9Ik0yNzUgNTVoLTU3VjBoMjV2MzFoMzJ2MjRaIiBzdHlsZT0iZmlsbDojZGUwMDVkO2ZpbGwtcnVsZTpub256ZXJvIi8%2BPHBhdGggZD0iTTE4NSAzMWg1N3Y1NWgtMjVWNTVoLTMyVjMxWiIgc3R5bGU9ImZpbGw6I2M1MTgxZjtmaWxsLXJ1bGU6bm9uemVybyIvPjwvc3ZnPg%3D%3D&labelColor=fff)](https://ippclub.org)

<p align="center">
	<img src='Image/banner.jpg' alt='LSD' width='500px'/>
</p>

------

## 项目简介

继续开发的盘点、设计细化与任务进度见 [开发文档](Docs/README.md)。

《灵数奇缘》是一款基于 [Dora SSR](https://github.com/IppClub/Dora-SSR) 引擎开发的 2D 游戏项目。项目采用 Yue Script 脚本语言编写，使用 Spine 动画技术，包含完整的游戏系统、UI 界面和音乐资源。

## 项目结构

```
├── init.yue              # 入口文件，负责环境初始化和资源路径设置
├── Start.yue             # 主启动文件，初始化数据库和游戏流程
├── Script/               # 游戏脚本目录
│   ├── System/          # 系统脚本（开场动画、对话等）
│   ├── Scene/           # 场景脚本（休息室、训练场等）
│   ├── Academy/         # 学院关卡脚本
│   └── Control.yue      # 控制脚本
├── UI/                   # 用户界面文件
│   ├── *.yue            # Yue 脚本格式的 UI 组件
│   ├── *.xml            # XML 格式的 UI 布局文件
│   └── View/            # 视图组件
├── Data/                 # 游戏数据目录
│   ├── Config.tl        # 游戏配置文件
│   └── *.json           # JSON 格式的数据文件
├── Spine/                # Spine 动画资源目录
├── Image/                # 图像资源目录
├── Music/                # 音乐资源目录
├── Font/                 # 字体文件目录
└── Test/                 # 测试用例目录
```

## 开发环境配置

### 必备工具

1. **Dora SSR 引擎**：从 [Dora-SSR](https://github.com/IppClub/Dora-SSR) 获取
2. **Spine 动画资源**：根据需要从以下仓库获取：
   - 普通分辨率：[LSD-spine-1x](https://github.com/IppClub/LSD-spine-1x)
   - 高清分辨率：[LSD-spine-2x](https://github.com/IppClub/LSD-spine-2x)

### 运行步骤

1. 克隆或下载本项目
2. 将 Spine 动画资源复制到 `Spine/` 目录
3. 通过 Web IDE 将项目上传至 Dora-SSR
4. 在 Dora-SSR 中运行和测试

## 配置说明

游戏的主要配置位于 `Data/Config.tl` 文件中，常用配置项包括：

- **skipOP**：控制是否跳过开场动画
  - `0` - 播放开场动画（默认）
  - `1` - 跳过开场动画

## 主要功能

- 完整的游戏流程（开场动画 → 教程关卡 → 游戏主界面）
- 丰富的 UI 系统（对话框、状态栏、技能面板等）
- Spine 动画支持
- 场景系统（休息室、训练场、学院关卡等）
- 战斗和技能系统
- 角色成长系统

![Gameplay RTT](Image/gameplay-RTT.jpg)

## 开发测试使用说明

* Spine 目录下的资源请按需从 [LSD-spine-1x](https://github.com/IppClub/LSD-spine-1x.git) 或是 [LSD-spine-2x](https://github.com/IppClub/LSD-spine-2x) 仓库获取普通或是高清分辨率的美术素材，复制到该目录下使用。

* 克隆或是下载项目，然后将该项目通过 Web IDE 上传至 [Dora-SSR](https://github.com/IppClub/Dora-SSR) 中。然后进行运行和测试。

## 美术、音乐素材版权

归《灵数奇缘》社区所有，相关资产授权见[这里](https://luv-sense-digital.readthedocs.io/community/licencing.html)。

![LSD People](Image/l-s-d-people.jpg)

## 程序代码授权

MIT

## 致谢

- 感谢 [IppClub](https://ippclub.org) 提供的技术支持
- 感谢《灵数奇缘》社区提供的美术和音乐资源


### 废弃工厂的材料调查

完成备战室转译器行动准备后，沿学院原门路到站台登车，列车右侧出口第二项“工厂取材”复用三人编队，两位学员均需采用成果。进入原工厂，夜光镜定位沼泽道路，沿路向右走近5200处观察歌声，再准备并明确开始战斗。原摇杆/枪械与集合K、乌云歌谣R负责实际作战；完整吟唱解除混乱，毒素仍在。真实清理花妖后，结算继续到材料点实地采集，通讯第八页点击通知医师。伤后生命保留到下一段正式治疗；后续治疗、出发、遗迹、桃源、潜入及第三章结局现已接入，分段运行证据见策划网站的开发进度。FactoryRoute为公开事件/物理回放，FactoryResume为真实进程重启后Start原学院至工厂门路，FactoryOutcomes为显式准备撤离/低生命失败专项。音频与原型美术仍待精修。


## Game 0 当前开发状态（2026-10-04）

本工程正在制作完整 Game 0。已有标题新建/继续、建角教程、学院房门漫游、训练室与虚拟训练场、两学员示范学习/对照/采用成果、编队战斗，以及三章主线与结局的分段原生运行记录。操作复用原摇杆、枪械和技能按钮；Q版狐狸使用独立Q版素材与动画。

目前仍是开发版本。分段通过不等于连续人工通关或发行验收通过：完整模拟玩家游玩、部分角色与场景动画精修、各设备输入和窗口尺寸、音频听感及循环、长稳、最终安装包验收仍需完成。详细设计与逐次证据维护在配套 LSD-doc 项目的 `docs/source/development/game0/`，以 `progress.md` 最新记录和 `acceptance.md` 验收条件为准。

开发测试必须使用独立QA存档，不能覆盖现有玩家的 `lsd.db`。`Test` 中同时包含自动断言、视觉研究和人工操作入口；运行一个入口通常会替换当前场景，执行前应确认没有长稳或其他仍在进行的测试。

运行资源位于 Data、Font、Image、Music、Script、Sound、Spine 和 UI。Docs 为制作工程和证据，Test/Tools 为开发辅助，不属于游戏运行依赖。`Tools/stage_game0.py` 可创建带逐文件哈希的独立资源暂存目录，拒绝覆盖已有目录；该目录不含引擎，不能直接称为安装包。`Tools/audit_runtime_atlases.py` 和 `Tools/audit_runtime_audio.py` 分别检查图集引用/边界与完整音频解码，不能替代原生运行和实际视听验收。

`Tools/package_game0_macos.py` 可在工程外新目录生成包含匹配arm64 Dora运行时的完整内容候选app，使用独立存档子目录并记录逐文件哈希。需提供已验证的运行时manifest；本次候选最低系统为macOS 26.6。打包与标题启动通过不等于三章、结局分支或发行验收完成，范围与证据见开发文档candidate-package.md。
