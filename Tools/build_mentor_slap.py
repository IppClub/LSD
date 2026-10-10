#!/usr/bin/env python3
"""Dedicated interrogation slap on each original mentor rig."""
import copy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def zero(node):
 if isinstance(node,list):
  if not node or node[0].get('time',0)>0:return []
  k=copy.deepcopy(node[0]);k.pop('curve',None);k.pop('time',None);return [k]
 return {k:v for k,c in node.items() if (v:=zero(c))}
def track(times,values):
 result=[]
 for i,(t,v) in enumerate(zip(times,values)):
  k={'time':t,'value':v}
  if i+1<len(times):
   dt=times[i+1]-t;k['curve']=[t+dt/3,v,times[i+1]-dt/3,values[i+1]]
  result.append(k)
 return result
for name in ('charM','charF'):
 base=ROOT/'Docs/artwork/interrogation'/name
 data=json.loads((base/'source-export'/f'{name}.json').read_text())
 for region in json.loads((base/'original-regions.json').read_text()):
  skin=next(s for s in data['skins'] if s['name']==region['skin'])
  a=skin['attachments'][region['slot']][region['attachment']]
  for axis,dimension in [('X','width'),('Y','height')]:a['scale'+axis]=region['scale'+axis]*region[dimension]/a[dimension]
 original=copy.deepcopy(data)
 anim=zero(data['animations']['idle']);fit=json.loads((base/'hand-fit.json').read_text())
 times=[0,.22,.32,.43,.6,.9]
 for bone,target in fit['rotations'].items():
  b=anim['bones'].setdefault(bone,{})
  initial=b.get('rotate',[{}])[0].get('value',0)
  anticipation=target+(30 if bone=='R_UpArm' else 12 if bone=='R_Arm' else 0)
  follow=target-(18 if bone=='R_UpArm' else 8 if bone=='R_Arm' else 0)
  b['rotate']=track(times,[initial,anticipation,target,follow,initial,initial])
 data.setdefault('events',{})['interrogationSlap']={}
 anim['events']=[{'time':.32,'name':'interrogationSlap'}]
 data['animations']['interrogationSlap']=anim
 assert all(data[k]==original[k] for k in ('bones','slots','skins','constraints'))
 assert all(data['animations'][k]==v for k,v in original['animations'].items())
 (base/'actions.json').write_text(json.dumps(data,separators=(',',':')))
 print(name,'slap duration .9 contact .32 target',fit)
