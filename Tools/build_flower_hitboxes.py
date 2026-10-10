"""Build review-only weighted hit regions from the authored flower mesh hulls.
No runtime asset is replaced. Preserve weights so regions follow original bones.
"""
import copy,json
from pathlib import Path
base=Path(__file__).resolve().parents[1]/'Docs/artwork/flower-hitboxes'
data=json.loads((base/'source-export/dahuayao.json').read_text())
assert len(data['skins'])==1, 'Multi-skin probes require per-skin mapping'
# Logical armor regions may have disconnected mesh pieces. Each piece keeps
# its authored contour; shared IDs resolve against one AP pool, never a hull
# spanning the empty space between tendrils.
regions={'lian':'flower-head','qugan':'flower-core','huaxiong':'flower-core',
 'zuohuabanxia':'petal-left','yhb':'petal-left','yhb1':'petal-left','zsb':'petal-left',
 '3':'petal-right','1':'petal-right','2':'petal-right','4':'petal-right',
 'tengmantui':'roots','diqunbai':'roots'}
for prefix,part,count in [('z','petal-left',5),('y','petal-right',5),('tm','roots',6),('qb','roots',3)]:
 for i in range(1,count+1):regions[f'{prefix}{i}']=part
priorities={'flower-head':40,'petal-left':30,'petal-right':30,'roots':20,'flower-core':10}

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
  name='hit-'+slot
  skin['attachments'][name]={name:{'type':'boundingbox','vertexCount':count,'vertices':points}}
for slot,part in regions.items():
 name='hit-'+slot
 data['slots'].append({'name':name,'bone':slots[slot]['bone'],'attachment':name})
# Expose each weighted influence as a PointAttachment through getKey.
# Weighted sums reproduce mesh hull vertices without adding engine-only APIs.
manifest=[]
bases={}
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
   if bone not in bases:
    prefix=f'basis-{len(bases)}';bases[bone]=prefix
    for suffix,px,py in [('o',0,0),('x',1024,0),('y',0,1024)]:
     name=prefix+'-'+suffix
     data['slots'].append({'name':name,'bone':bone,'attachment':name})
     data['skins'][0]['attachments'][name]={name:{'type':'point','x':px,'y':py}}
   refs.append({'basis':bases[bone],'x':x,'y':y,'weight':weight})
  verts.append(refs)
 manifest.append({'id':part,'sourceSlot':slot,'geometryId':slot,'priority':priorities[part],'vertices':verts})
(base/'vertex-probes.json').write_text(json.dumps(manifest,indent=2))
# This source has no mesh deform timelines; any later source with deformation
# needs an explicit transfer instead of silently diverging from the artwork.
assert all('deform' not in a and 'attachments' not in a for a in data['animations'].values())
(base/'dahuayao-hitboxes.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
(base/'regions.json').write_text(json.dumps({'status':'candidate-not-runtime','source':'dahuayao runtime skeleton 4.3.08 exported with Spine 4.3.26','regions':regions,'requires':'pose, visibility, overlap and runtime-source equivalence review'},ensure_ascii=False,indent=2))
print(f'Built {len(manifest)} mesh pieces in 5 logical regions; runtime unchanged')

# Keep the C++ parity fixture generated from the same manifest.
lines=['// Generated probe manifest for native geometry verification.',
 'struct Ref {const char* slot; float weight,x,y;};',
 'struct Part {const char* slot; std::vector<std::vector<Ref>> vertices;};',
 'std::vector<Part> parts={']
for part in manifest:
 lines.append('{"'+part['sourceSlot']+'",{')
 for refs in part['vertices']:
  lines.append('{'+','.join('{"%s",%sf,%sf,%sf}'%(r['basis'],repr(float(r['weight'])),repr(float(r['x'])),repr(float(r['y']))) for r in refs)+'},')
 lines.append('}},')
lines.append('};')
(base/'probe-manifest.h').write_text('\n'.join(lines))
