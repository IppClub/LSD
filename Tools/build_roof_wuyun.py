#!/usr/bin/env python3
"""Preserve original Wuyun animation geometry and add non-rendering forearm anchors."""
from pathlib import Path
import json, copy
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'Docs/artwork/interrogation/wuyun/source-export/wuyun.json').read_text())
for r in json.loads((root/'Docs/artwork/interrogation/wuyun/original-regions.json').read_text()):
    skin=next(s for s in data['skins'] if s['name']==r['skin'])
    a=skin['attachments'][r['slot']][r['attachment']]
    for key in ['width','height','scaleX','scaleY']: a[key]=r[key]
data['animations']={k:v for k,v in data['animations'].items() if k in ['idle','prepare','comp','fmove','jump','jumping','landing','melee','pistol','lose','hit','throw','standUp','comm']}
(root/'Spine/Roof/wuyun-original-clips.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
for name,x in [('roofMark',85),('roofMarkAxis',115)]:
    data['slots'].append({'name':name,'bone':'zuobi3','attachment':name})
    data['skins'][0]['attachments'][name]={name:{'type':'point','x':x,'y':0}}
# Bake a deliberate arm lift from the native idle pose, keeping limb lengths/skin intact.
pose=json.loads((root/'Spine/Roof/wuyun-idle-pose.json').read_text())
base={b['name']:b for b in pose['bones']}
defs={b['name']:b for b in data['bones']}
clip={'bones':{},'slots':{v['name']:{'attachment':[{'name':v['attachment']}]} for v in pose['slots']}}
for name,b in defs.items():
    v=base[name]
    clip['bones'][name]={'translate':[{'x':v['x']-b.get('x',0),'y':v['y']-b.get('y',0)}], 'rotate':[{'value':v['rotation']-b.get('rotation',0)}], 'scale':[{'x':v['scaleX']/b.get('scaleX',1),'y':v['scaleY']/b.get('scaleY',1)}]}
clip['ik']={v['name']:[{'mix':0}] for v in data.get('constraints',[])if v['type']=='ik'}
clip['transform']={v['name']:[{'mixRotate':0,'mixX':0,'mixY':0,'mixScaleX':0,'mixScaleY':0,'mixShearY':0}]for v in data.get('constraints',[])if v['type']=='transform'}
def freeze(v):
    if isinstance(v,list)and v and isinstance(v[0],dict):
        k=copy.deepcopy(v[0]);k.pop('curve',None);k['time']=0;return [k]
    if isinstance(v,dict):return {k:freeze(x)for k,x in v.items()}
    return copy.deepcopy(v)
if 'attachments'in data['animations']['idle']:clip['attachments']=freeze(data['animations']['idle']['attachments'])
wrap=lambda a:(a+180)%360-180
accumulated=0
for name,target in [('zuobi1',110),('zuobi3',145),('zuoshou',160)]:
    delta=wrap(target-base[name]['worldRotation']-accumulated);accumulated+=delta
    start=base[name]['rotation']-defs[name].get('rotation',0)
    clip['bones'][name]['rotate']=[{'time':round(i/48*.8,6),'value':start+delta*(3*(i/48)**2-2*(i/48)**3)}for i in range(49)]
data.setdefault('events',{})['roofArmRaised']={}
clip['events']=[{'time':.8,'name':'roofArmRaised'}]
data['animations']['roofRaise']=clip
lower=copy.deepcopy(clip)
for timelines in lower['bones'].values():
    keys=timelines['rotate']
    if len(keys)>1:timelines['rotate']=[dict(k,time=round(.6-k['time']/.8*.6,6))for k in reversed(keys)]
data['events']['roofArmLowered']={}
lower['events']=[{'time':.6,'name':'roofArmLowered'}]
data['animations']['roofLower']=lower
(root/'Spine/Roof/wuyun.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
