#!/usr/bin/env python3
"""Reverse the original get-up clip on the original rig for a visible story collapse.
Original textures, meshes, bones, constraints and all existing animations are retained.
The combat 'lose' clip remains unchanged, including its intentional fade-out.
"""
import copy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'Spine/Final';OUT.mkdir(exist_ok=True)
def reverse(keys,duration,default=None,deform=False):
 keys=copy.deepcopy(keys)
 if keys[0].get('time',0)>0:
  keys.insert(0,dict(default or {},time=0,curve='stepped'))
 if keys[-1].get('time',0)<duration:
  last=copy.deepcopy(keys[-1]);last.pop('curve',None);last['time']=duration;keys.append(last)
 result=[]
 for i in range(len(keys)-1,-1,-1):
  k=copy.deepcopy(keys[i]);k.pop('curve',None);k['time']=round(duration-k.get('time',0),7)
  if i:
   curve=keys[i-1].get('curve')
   if isinstance(curve,list):
    transformed=[]
    for j in range(0,len(curve),4):
     x1,y1,x2,y2=curve[j:j+4]
     transformed.extend([duration-x2,1-y2 if deform else y2,duration-x1,1-y1 if deform else y1])
    k['curve']=transformed
   elif curve=='stepped':
    result.append(k)
    k=copy.deepcopy(keys[i-1]);k.pop('curve',None);k['time']=round(duration-keys[i].get('time',0)+.000001,7);k['curve']='stepped'
  result.append(k)
 return result
for name in ('charF','charM'):
 base=ROOT/'Docs/artwork/interrogation'/name
 data=json.loads((base/'source-export'/f'{name}.json').read_text())
 for region in json.loads((base/'original-regions.json').read_text()):
  skin=next(s for s in data['skins']if s['name']==region['skin']);a=skin['attachments'][region['slot']][region['attachment']]
  for axis,dimension in [('X','width'),('Y','height')]:a['scale'+axis]=region['scale'+axis]*region[dimension]/a[dimension]
 source=copy.deepcopy(data);stand=data['animations']['standUp'];duration=max(k.get('time',0)for tr in stand['bones'].values()for keys in tr.values()for k in keys)
 clip={'bones':{}}
 for bone,tracks in stand['bones'].items():
  clip['bones'][bone]={kind:reverse(keys,duration,{'x':1,'y':1}if kind=='scale'else {})for kind,keys in tracks.items()}
 if stand.get('attachments'):
  clip['attachments']=copy.deepcopy(stand['attachments'])
  for skin in clip['attachments'].values():
   for slot in skin.values():
    for attachment in slot.values():
     for kind,keys in attachment.items():attachment[kind]=reverse(keys,duration,deform=True)
 if stand.get('drawOrder'):
  assert len(stand['drawOrder'])==1 and stand['drawOrder'][0].get('time',0)==0
  clip['drawOrder']=copy.deepcopy(stand['drawOrder'])
 data['animations']['finalCollapse']=clip
 assert all(data[k]==source[k]for k in ('bones','slots','skins','constraints'))
 assert all(data['animations'][k]==v for k,v in source['animations'].items())
 (OUT/f'{name}.json').write_text(json.dumps(data,separators=(',',':')))
 print(name,'finalCollapse',duration,'seconds; original rig/animations preserved')
