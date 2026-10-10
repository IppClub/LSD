# 原设计装备图标

来源为用户提供的6个PSD，原文件未改动。43个透明PNG保存在Image/Equipment，Data/Equipment/artwork.json记录图层、尺寸、源文件哈希与art-only状态。

重新导出：在安装psd-tools[composite]的Python环境运行 Tools/export_item_icons.py /Users/Jin/Downloads/加粗道具。

未知武器箱的大智能对象实际同时包含大小两箱，小图层只包含轮廓，必须先合成整组再按原稿间隔分离，不能单独导出小图层。contact-sheet.jpg为导出核对图。原枪械组中弹药小图、弓箭组中的箭等属于原稿组合；接入单项UI时按用途挑选，不应当作已完成的战斗武器。
