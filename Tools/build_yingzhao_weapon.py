"""Add a hand-mounted weapon socket; retain every original mesh and timeline."""
import json,subprocess,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[1];art=root/'Docs/artwork/yingzhao-weapon'
d=json.loads((art/'source-export/zhongyingzhao.json').read_text())
# Insert a neutral elbow control before the firing forearm. Rotation zero
# preserves the authored rig; runtime aiming moves forearm, hand and gun together.
index=next(i for i,b in enumerate(d['bones']) if b['name']=='bone14')
forearm=d['bones'][index]
d['bones'].insert(index,{'name':'weapon-aim','parent':forearm['parent'],'x':forearm.get('x',0),'y':forearm.get('y',0)})
forearm['parent']='weapon-aim';forearm['x']=0;forearm['y']=0
# Weighted attachments encode bone array indices, not names.
for skin in d['skins']:
 for attachments in skin['attachments'].values():
  for attachment in attachments.values():
   vertices=attachment.get('vertices')
   if not vertices: continue
   count=len(attachment['uvs'])//2 if 'uvs' in attachment else attachment.get('vertexCount')
   if count is None or len(vertices)==count*2: continue
   at=0
   for _ in range(count):
    weights=int(vertices[at]);at+=1
    for _ in range(weights):
     if vertices[at]>=index:vertices[at]+=1
     at+=4
   assert at==len(vertices),'Unexpected weighted attachment encoding'
# Trigger hand (bone52), behind the near hand so fingers cover the grip.
index=next(i for i,s in enumerate(d['slots']) if s['name']=='zhuazhiyou')
d['slots'].insert(index,{'name':'held-weapon','bone':'bone52','attachment':'s:pistol'})
for skin in d['skins']:skin['attachments']['held-weapon']={'s:pistol':{'type':'point','x':-100,'y':-25,'rotation':24}}
# Reconstruct each authored order, then insert the socket immediately before
# the trigger hand. Encode full offsets so original relative ordering is exact.
oldNames=[s['name'] for s in d['slots'] if s['name']!='held-weapon']
newNames=[s['name'] for s in d['slots']]
for animation in d['animations'].values():
 for frame in animation.get('drawOrder',[]):
  order=[None]*len(oldNames);unchanged=[];original=0
  for offset in frame.get('offsets',[]):
   target=oldNames.index(offset['slot'])
   while original<target:unchanged.append(original);original+=1
   order[original+offset['offset']]=original;original+=1
  while original<len(oldNames):unchanged.append(original);original+=1
  for i in range(len(order)-1,-1,-1):
   if order[i] is None:order[i]=unchanged.pop()
  names=[oldNames[i] for i in order]
  names.insert(names.index('zhuazhiyou'),'held-weapon')
  assert [n for n in names if n!='held-weapon']==[oldNames[i] for i in order]
  frame['offsets']=[{'slot':name,'offset':names.index(name)-i} for i,name in enumerate(newNames)]
(art/'zhongyingzhao-weapon.json').write_text(json.dumps(d,ensure_ascii=False))
editor='/Applications/Spine.app/Contents/MacOS/Spine'
for label,args in [('import',['-i',str(art/'zhongyingzhao-weapon.json'),'-o',str(art/'zhongyingzhao-weapon.spine'),'--replace','-r']),('binary',['-i',str(art/'zhongyingzhao-weapon.spine'),'-o',str(art/'export'),'-e','binary'])]:
 with (art/(label+'.log')).open('w') as log:subprocess.run([editor]+args,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=120)
shutil.copyfile(art/'export/zhongyingzhao-weapon.skel',root/'Spine/zhongyingzhao-weapon.skel')
