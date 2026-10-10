"""Export existing authored PSD groups losslessly to transparent UI PNGs."""
from pathlib import Path
import argparse, hashlib, json
from psd_tools import PSDImage

FILES = {
 '道具 加粗 EMP枪 拆.psd': ('emp', ['capture','shotgun','machinegun','sniper','rifle','smg','pistol']),
 '道具 加粗 实弹枪 拆.psd': ('kinetic', ['tranquilizer','shotgun','machinegun','sniper','rifle','smg','pistol']),
 '道具 加粗 激光枪.psd': ('laser', ['tranquilizer','shotgun','machinegun','sniper','rifle','smg','pistol']),
 '道具 加粗 激光冷兵器&道具.psd': ('equipment', ['grenade','computer','phone','bow','shovel','axe','blade','shield']),
 '道具 加粗 第二批小道具.psd': ('accessory', ['jump','speed','agility','armband','hologram','duck']),
}

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('source',type=Path)
 args=parser.parse_args()
 root=Path(__file__).resolve().parents[1];out=root/'Image/Equipment';out.mkdir(parents=True,exist_ok=True)
 rows=[]
 def export(p,group,key,label,viewport=None):
  image=group.composite(viewport=viewport);assert image is not None,key
  image=image.convert('RGBA');box=image.getbbox();assert box,key
  image=image.crop(box);image.save(out/(key+'.png'))
  rows.append(dict(id=key,name=label,file='Image/Equipment/'+key+'.png',width=image.width,height=image.height,
   source=p.name,sourceSha256=hashlib.sha256(p.read_bytes()).hexdigest(),group=group.name,gameplayStatus='art-only'))
 for filename,(prefix,names) in FILES.items():
  p=args.source/filename;psd=PSDImage.open(p);groups=[g for g in psd if g.is_group()]
  assert len(groups)==len(names),filename
  for g,name in zip(groups,names):export(p,g,prefix+'-'+name,g.name.strip())
 p=args.source/'道具 加粗 箱子.psd';psd=PSDImage.open(p)
 for g,kind in zip([g for g in psd if g.is_group()][:4],['unknown','kinetic','emp','laser']):
  if kind=='unknown':
   # The large smart object contains BOTH boxes; the small sibling is only
   # an outline overlay. Composite the group before splitting the authored gap.
   x0,y0,x1,y1=g.bbox
   export(p,g,'crate-unknown-large',g.name.strip()+'（大）',(x0,y0,1285,y1))
   export(p,g,'crate-unknown-small',g.name.strip()+'（小）',(1285,y0,x1,y1))
   continue
  for child in g:
   size='small' if '小' in child.name else 'large'
   export(p,child,'crate-'+kind+'-'+size,g.name.strip()+('（小）' if size=='small' else '（大）'))
 catalog=root/'Data/Equipment';catalog.mkdir(parents=True,exist_ok=True)
 (catalog/'artwork.json').write_text(json.dumps({'schemaVersion':1,'items':rows},ensure_ascii=False,indent=2))
 print(f'Exported {len(rows)} original transparent assets')
if __name__=='__main__': main()
