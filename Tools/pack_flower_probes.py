"""Pack three invisible affine probes per bone; leave runtime files untouched."""
import json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=root/'Docs/artwork/flower-hitboxes'
out=root/'Docs/artwork/flower-probes-packed';out.mkdir(exist_ok=True)
d=json.loads((source/'dahuayao-hitboxes.json').read_text())
manifest=json.loads((source/'vertex-probes.json').read_text())
bases=sorted({r['basis'] for p in manifest for v in p['vertices'] for r in v})
slots={s['name']:s for s in d['slots']};removed=set()
for base in bases:
 names=[base+'-'+v for v in ['o','x','y']];removed.update(names)
 slot={'name':base,'bone':slots[names[0]]['bone'],'attachment':names[0]}
 assert all(slots[n]['bone']==slot['bone'] for n in names)
 d['slots'].append(slot)
 for skin in d['skins']:
  attachments={}
  for n in names:attachments.update(skin['attachments'].pop(n))
  skin['attachments'][base]=attachments
for animation in d['animations'].values():
 assert not removed.intersection(animation.get('slots',{}))
 for frame in animation.get('drawOrder',[]):assert all(x['slot'] not in removed for x in frame.get('offsets',[]))
d['slots']=[s for s in d['slots'] if s['name'] not in removed]
for part in manifest:
 for vertex in part['vertices']:
  for ref in vertex:ref['basisSlot']=ref['basis']
(out/'dahuayao-probes-packed.json').write_text(json.dumps(d,ensure_ascii=False))
(out/'regions.json').write_text(json.dumps(manifest))
editor='/Applications/Spine.app/Contents/MacOS/Spine'
for name,args in [('import',['-i',str(out/'dahuayao-probes-packed.json'),'-o',str(out/'dahuayao-probes-packed.spine'),'--replace','-r']),('export',['-i',str(out/'dahuayao-probes-packed.spine'),'-o',str(out/'export'),'-e','binary'])]:
 with (out/(name+'.log')).open('w') as log:subprocess.run([editor]+args,check=True,stdout=log,stderr=subprocess.STDOUT,timeout=120)
print('Packed',len(bases)*3,'probe slots into',len(bases),'without replacing runtime')
