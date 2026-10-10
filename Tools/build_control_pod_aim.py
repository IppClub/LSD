#!/usr/bin/env python3
"""Retain original pistol motion, add a native event on the pre-recoil aim plateau."""
from pathlib import Path
import copy,json
root=Path(__file__).resolve().parents[1];out=root/'Spine/ControlPod';out.mkdir(exist_ok=True)
for name in ['charM','charF','ninilite']:
 source=root/('Docs/artwork/reference-export/ninilite.json' if name=='ninilite' else f'Docs/artwork/interrogation/{name}/source-export/{name}.json')
 data=json.loads(source.read_text())
 # Editor JSON export normalizes region sizes to packed pixels; restore the
 # dimensions from the original runtime binary before loading JSON directly.
 for region in json.loads((out/(name+'-original-regions.json')).read_text()):
  skin=next(s for s in data['skins'] if s['name']==region['skin'])
  attachment=skin['attachments'][region['slot']][region['attachment']]
  for field in ['width','height','scaleX','scaleY']:attachment[field]=region[field]
 aim=copy.deepcopy(data['animations']['pistol'])
 attack=next(e['time'] for e in aim['events'] if e['name']=='attack')
 aim['events']=[{'time':attack-.10,'name':'aimReady'}]
 data.setdefault('events',{})['aimReady']={};data['animations']={k:v for k,v in data['animations'].items() if k in ['idle','fmove','prepare','pistol']};data['animations']['aim']=aim
 (out/(name+'.json')).write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
 print(name,attack-.10)
