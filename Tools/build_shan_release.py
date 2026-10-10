"""Add weighted palm probes to a runtime-source export; retain original artwork."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1];base=root/'Docs/artwork/shan-release'
d=json.loads((base/'source-export/xiaoshanxiao.json').read_text());manifest={}
for label,slot in [('front','qianzhuaxia'),('rear','houzhuaxia')]:
 mesh=d['skins'][0]['attachments'][slot][slot];uv=mesh['uvs'];raw=mesh['vertices'];vertices=[];offset=0
 for i in range(len(uv)//2):
  count=int(raw[offset]);offset+=1;refs=[]
  for _ in range(count):
   bone,x,y,weight=raw[offset:offset+4];offset+=4;refs.append((int(bone),x,y,weight))
  vertices.append(refs)
 # Palm near the finger roots, selected on the original hand textures.
 target=(.65,.72);found=None
 for i in range(0,len(mesh['triangles']),3):
  ids=mesh['triangles'][i:i+3];a,b,c=[uv[j*2:j*2+2] for j in ids]
  den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(den)<1e-10:continue
  x=((b[1]-c[1])*(target[0]-c[0])+(c[0]-b[0])*(target[1]-c[1]))/den
  y=((c[1]-a[1])*(target[0]-c[0])+(a[0]-c[0])*(target[1]-c[1]))/den
  weights=[x,y,1-x-y]
  if min(weights)>=-1e-7:found=(ids,weights);break
 assert found,label
 refs=[]
 for idx,blend in zip(*found):
  for bone,x,y,weight in vertices[idx]:
   name=f'release-{label}-{len(refs)}'
   d['slots'].append({'name':name,'bone':d['bones'][bone]['name'],'attachment':name})
   for skin in d['skins']:skin['attachments'][name]={name:{'type':'point','x':x,'y':y}}
   refs.append({'key':name+'/'+name,'weight':weight*blend})
 manifest[label]={'slot':slot,'uv':target,'refs':refs}
(base/'xiaoshanxiao-release.json').write_text(json.dumps(d,ensure_ascii=False))
(root/'Data/Combat/shan-release.json').write_text(json.dumps(manifest,indent=2))
