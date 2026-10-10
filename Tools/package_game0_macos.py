#!/usr/bin/env python3
"""Bundle the complete game with a verified arm64 Dora runtime in a fresh directory."""
from pathlib import Path
import argparse, hashlib, json, plistlib, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
BOOTSTRAP='''local D=require('Dora')
local game=D.Path(D.Content.assetPath,'LSD')
local qa=os.getenv('LSD_PACKAGE_QA_ROOT')
local save=qa or D.Path(D.Content.writablePath,'LingShuQiYuan')
assert(D.Content:mkdir(save)or D.Content:isdir(save),'Cannot open game save directory')
D.Content.writablePath=save
-- Start loads Data.Config, which depends on the bundled engine Config library.
D.Content:insertSearchPath(1,D.Path(D.Content.assetPath,'Script','Lib'))
for _,p in ipairs({game,D.Path(game,'Script'),D.Path(game,'Spine'),D.Path(game,'Image'),D.Path(game,'Font')})do D.Content:insertSearchPath(1,p)end
local entry=D.Path(game,'init.lua')
assert(load(D.Content:load(entry),'@'..entry))(D.Path(game,'init'))
if qa then D.thread(function()
 D.sleep(3)
 local ok,err=xpcall(function()
  local c=assert(require('Save.Title').current)
  assert(c.phase=='ready'and c.node.parent and c.new and c.saves,'Game title not ready')
  assert(D.Content:exist(D.Path(game,'Image/banner.jpg'))and D.Content:exist(D.Path(game,'Spine/ninilite.skel')),'Game assets missing')
  assert(not D.Content:exist(D.Path(game,'Test'))and not D.Content:exist(D.Path(game,'Docs')),'Development files included')
  D.App:saveScreenshot(D.Path(save,'title.tga'));D.sleep(.25)
 end,debug.traceback)
 D.Content:save(D.Path(save,'result.json'),D.json.encode({status=ok and 'PASS'or'FAIL',error=not ok and err or nil,game=game,save=save,titleOnly=true,osInput=false},false,true))
 D.App:shutdown()
end)end
'''
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 p=argparse.ArgumentParser();p.add_argument('--runtime-manifest',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 target=a.output.resolve();runtime=json.loads(a.runtime_manifest.read_text());binary=Path(runtime['binary']).resolve()
 if target.exists()or target==ROOT or ROOT in target.parents:raise RuntimeError('Choose a fresh output outside the game source')
 if runtime['status']!='built'or digest(binary)!=runtime['binarySha256']:raise RuntimeError('Runtime binary does not match the verified manifest')
 original=binary.parents[2]
 if original.suffix!='.app':raise RuntimeError('Expected a macOS application runtime')
 target.mkdir(parents=True);stage=target/'runtime-stage'
 subprocess.run([sys.executable,str(ROOT/'Tools/stage_game0.py'),'--output',str(stage)],check=True)
 app=target/'LingShuQiYuan.app';shutil.copytree(original,app,symlinks=True)
 resources=app/'Contents/Resources';shutil.move(str(stage),str(resources/'LSD'))
 (resources/'Script/init.lua').write_text(BOOTSTRAP)
 info=app/'Contents/Info.plist';meta=plistlib.loads(info.read_bytes());meta.update(CFBundleName='灵数奇缘',CFBundleDisplayName='灵数奇缘',CFBundleIdentifier='IppClub.LingShuQiYuan',LSApplicationCategoryType='public.app-category.games');info.write_bytes(plistlib.dumps(meta))
 subprocess.run(['/usr/bin/codesign','--force','--deep','--sign','-',str(app)],check=True)
 subprocess.run(['/usr/bin/codesign','--verify','--deep','--strict',str(app)],check=True)
 manifest={'kind':'macos-playable-candidate','scope':'Complete current game content; final acceptance incomplete','runtimeBundled':True,'runtimeVerified':False,'platform':'macOS arm64','minimumSystemVersion':meta.get('LSMinimumSystemVersion'),'sourceRuntime':runtime,'bootstrapSha256':digest(resources/'Script/init.lua'),'gameManifestSha256':digest(resources/'LSD/runtime-manifest.json'),'files':[]}
 for f in sorted(app.rglob('*')):
  if f.is_file()and not f.is_symlink():manifest['files'].append({'path':str(f.relative_to(target)),'bytes':f.stat().st_size,'sha256':digest(f)})
 (target/'package-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 (target/'游玩说明.md').write_text('''# 灵数奇缘 · 可玩候选版

双击 LingShuQiYuan.app，选择“开始新旅程”。此包保留当前三个章节及已接入剧情内容，无需开发工程或另装引擎。

适用平台：Apple Silicon Mac，macOS 26.6及以上。本次为开发候选版，完整连续通关、结局分支、声音与长稳验收尚未完成。

使用画面中的摇杆和技能按钮，也可用A/D移动、J瞄准并松开射击；轻点直射，持续按住一秒后进入慢速精瞄，适合瞄准较窄的部位；技能快捷键以当前场景提示为准。战斗中靠近敌人会自动面向目标，后退为半速。学院训练室和虚拟训练场从学院漫游入口进入，训练页面按基础训练、场景对练、部位战术、缴械战术分组，全部原功能保留。

能源伏击中，E为焰火、L为寒风，K用于集合调整站位。持续集合会让学员靠拢并暂缓自主进攻；需要他们进攻时松开。注意实际射击距离，避免无效耗弹。

大英招讨伐中，F为火焰、R为旋风，G用于集合；长按G进入恢复集合，再次短按G取消。集合有有限期限；移动时长按恢复集合会跟随导师调整站位，实际恢复完成后会结束。到期未到齐会短暂显示“集合未到齐”，需要再按G重整；已到齐但恢复未完成会提示长按G继续。保留金粉保护辅助机，在护盾耗尽或机体首次受损时及时换位。留意完整连招、收招倒计时和退路方向，避免持续退向场边；使用原预览线瞄准已破甲部位，兼顾援军和辅助机的位置。较高部位需要留出瞄准距离，贴得太近时应优先瞄准可见的低处部位；实弹负责伤害，EMP负责破甲，头部未破甲时实弹伤害会明显降低。获胜仍按实际消耗结算，不保证盈利。

遗迹追兵战中，E为烟雾、L为火光、H使用已有治疗水。任务是掩护四人撤离并沿三段光路到右侧出口；射击和火光各需命中一次，并完整施放烟雾。烟雾隔在你与追兵之间会遮断追踪，火光只打断命中的敌人；边推进边掩护，给后半段留烟雾。请按任务重新配装，不必携带大量子弹去击杀全部追兵。

战前选择补给并预留预算，任务结束按实际消耗结算，未用额度退回；成功仍可能亏损。物资不足时可在配装页减少携带量，或选择“整理回收”。失败可以重新配装再战。战斗中的学员行为来自玩家采用的训练成果；九尾狐同行不参与训练。

本包使用独立的LingShuQiYuan存档子目录；不会自动导入或替换开发工程的原存档。请通过游戏标题页面创建、继续和选择旅程，避免直接修改数据库。

运行时与资源版本、逐文件校验见package-manifest.json。游戏与素材作者署名保留在游戏回顾/署名及所附原文档中。
''')
 print(json.dumps({'status':'PACKAGED_NOT_ACCEPTED','application':str(app),'files':len(manifest['files']),'minimumSystemVersion':manifest['minimumSystemVersion']},ensure_ascii=False))
if __name__=='__main__':main()
