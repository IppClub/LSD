#!/usr/bin/env python3
"""Editable native rig candidate; generated parts preserve PNG bytes. Original Q art is retained."""
from pathlib import Path
import math,json,hashlib,xml.etree.ElementTree as E
DEST=Path(__file__).resolve().parents[1]/'Image/Companion'
# name, texture rectangle, rest pivot, anchor, scale, animated parent
PARTS=[('hair', (764, 40, 317, 403), (0, 402), (0.5, 0.9), 0.58, 'head'), ('farLeg', (869, 735, 104, 316), (40, 250), (0.5, 0.96), 0.62, 'rig'), ('farBoot', (1197, 778, 118, 270), (40, 105), (0.5, 0.9), 0.42, 'farLeg'), ('nearLeg', (151, 735, 104, 316), (-40, 250), (0.5, 0.96), 0.62, 'rig'), ('nearBoot', (507, 777, 116, 274), (-40, 105), (0.5, 0.9), 0.42, 'nearLeg'), ('farUpperArm', (846, 507, 146, 194), (55, 395), (0.15, 0.91), 0.4, 'body'), ('nearUpperArm', (133, 510, 131, 181), (-55, 395), (0.82, 0.91), 0.4, 'body'), ('body', (483, 119, 189, 283), (0, 315), (0.5, 0.5), 0.75, 'rig'), ('skirt', (1101, 77, 347, 311), (0, 250), (0.5, 0.9), 0.69, 'body'), ('farForearm', (1189, 512, 174, 197), (85, 336), (0.17, 0.91), 0.52, 'farUpperArm'), ('nearForearm', (452, 507, 178, 204), (-85, 336), (0.88, 0.91), 0.5, 'nearUpperArm'), ('head', (8, 25, 404, 425), (0, 427), (0.5, 0.16), 0.67, 'body')]
STATES={'idle':120,'move':60}
def vec(v):return ','.join(f'{x:.4f}' for x in v)
def pose(name,state,u):
 if name=='rig':return (0,1.5*math.sin(2*math.pi*u) if state=='idle' else 5*math.sin(2*math.pi*u)**2,0)
 p=next(p for p in PARTS if p[0]==name);x,y=p[2];rot=0
 wave=math.sin(2*math.pi*u)
 if state=='move':
  if name.endswith('Leg'):rot=9*wave*(1 if name.startswith('near') else -1);y+=max(0,wave*(1 if name.startswith('near') else -1))*8
  elif name.endswith('UpperArm'):rot=7*wave*(-1 if name.startswith('near') else 1)
  elif name=='skirt':rot=2.5*wave
 elif name=='head':rot=.6*wave
 if name=='hair':rot+=1.4*math.sin(2*math.pi*u-.5)
 parent=p[5]
 if parent not in ('rig',None):
  pp=next(p for p in PARTS if p[0]==parent);px,py=pp[2];ax,ay,pr=pose(parent,state,u);a=math.radians(-pr);dx,dy=x-px,y-py
  x,y=ax+dx*math.cos(a)-dy*math.sin(a),ay+dx*math.sin(a)+dy*math.cos(a);rot+=pr
 return x,y,rot
clip=E.Element('A',A='fox-chibi-parts-v2.png')
for name,rect,*_ in PARTS:E.SubElement(clip,'B',A=name,B=','.join(map(str,rect)))
E.ElementTree(clip).write(DEST/'fox-chibi-rig-v1.clip',encoding='unicode')
m=E.Element('A',A='fox-chibi-rig-v1.clip',D='617,699');root=E.SubElement(m,'B');rig=E.SubElement(root,'B',H='rig')
for name,rect,pos,anchor,scale,parent in [('rig',None,(0,0),(.5,.5),1,None)]+PARTS:
 n=rig if name=='rig' else E.SubElement(rig,'B',A=vec(anchor),D=vec(pos),E=vec((scale,scale)),F='0',H=name,I=name,J='1')
 for state,frames in STATES.items():
  c=E.SubElement(n,'C');last=0
  for i in range(25):
   f=round(frames*i/24);x,y,r=pose(name,state,i/24);attrs=dict(A=str(f-last),C='1',D=vec((x,y)),E=vec((scale,scale)),F=f'{r:.4f}')
   if name=='rig' and state=='move' and i in (6,18):attrs['M']='step'
   E.SubElement(c,'D',**attrs);last=f
for i,state in enumerate(STATES):E.SubElement(m,'J',C=str(i),H=state)
E.ElementTree(m).write(DEST/'fox-chibi-rig-v1.model',encoding='unicode')
(DEST/'fox-chibi-rig-v1-manifest.json').write_text(json.dumps(dict(status='candidate: native visual and joint acceptance required before adoption',source='fox-chibi-parts-v2.png',sha256=hashlib.sha256((DEST/'fox-chibi-parts-v2.png').read_bytes()).hexdigest(),reference='Q-huli.png',parts=PARTS,frames=STATES,recovery=.2),ensure_ascii=False,indent=2)+'\n')
print('Built 12-part Q fox candidate, original image retained.')
