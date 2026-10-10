"""Build review-only weighted hit regions from the authored Taotie mesh hulls.
No runtime asset is replaced. Preserve weights so regions follow original bones.
"""
import copy,json
from pathlib import Path
base=Path(__file__).resolve().parents[1]/'Docs/artwork/boss-hitboxes'
data=json.loads((base/'source-export/dataotie.json').read_text())
assert len(data['skins'])==1, 'Multi-skin probes require per-skin mapping'
regions={'tou':'head','toubaoshi':'head-gem','beijia1':'back-front','beijia2':'back-rear','qiantui1shang':'front-leg','houqiantuishang':'rear-leg','weiba':'tail'}
slots={s['name']:s for s in data['slots']}
for skin in data['skins']:
 for slot,part in regions.items():
  mesh=skin['attachments'][slot][slot]
  assert mesh['type']=='mesh'
  count=mesh['hull'];v=mesh['vertices']
  if len(v)==len(mesh['uvs']): points=v[:count*2]
  else:
   offset=0
   for _ in range(count):
    bones=int(v[offset]);assert bones>0 and bones==v[offset]
    offset+=1+bones*4
   points=v[:offset]
  name='hit-'+part
  skin['attachments'][name]={name:{'type':'boundingbox','vertexCount':count,'vertices':points}}
for slot,part in regions.items():
 name='hit-'+part
 data['slots'].append({'name':name,'bone':slots[slot]['bone'],'attachment':name})
# Expose each weighted influence as a PointAttachment through getKey.
# Weighted sums reproduce mesh hull vertices without adding engine-only APIs.
manifest=[]
for slot,part in regions.items():
 mesh=data['skins'][0]['attachments'][slot][slot];v=mesh['vertices'];offset=0;verts=[]
 for index in range(mesh['hull']):
  if len(v)==len(mesh['uvs']):
   influences=[(slots[slot]['bone'],v[index*2],v[index*2+1],1)]
  else:
   count=int(v[offset]);offset+=1;influences=[]
   for _ in range(count):
    bone,x,y,weight=v[offset:offset+4];offset+=4
    influences.append((data['bones'][int(bone)]['name'],x,y,weight))
  refs=[]
  for j,(bone,x,y,weight) in enumerate(influences):
   name=f'probe-{part}-{index}-{j}'
   data['slots'].append({'name':name,'bone':bone,'attachment':name})
   for skin in data['skins']:
    skin['attachments'][name]={name:{'type':'point','x':x,'y':y}}
   refs.append({'key':name,'lookupPath':name+'/'+name,'weight':weight})
  verts.append(refs)
 manifest.append({'id':part,'vertices':verts})
(base/'vertex-probes.json').write_text(json.dumps(manifest,indent=2))
# This source has no mesh deform timelines; any later source with deformation
# needs an explicit transfer instead of silently diverging from the artwork.
assert all('deform' not in a and 'attachments' not in a for a in data['animations'].values())
(base/'dataotie-hitboxes.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
(base/'regions.json').write_text(json.dumps({'status':'candidate-not-runtime','source':'dataotie alt original project','regions':regions,'requires':'pose, visibility, overlap and runtime-source equivalence review'},ensure_ascii=False,indent=2))
print('Built 7 weighted candidate regions; runtime unchanged')
