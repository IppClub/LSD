#!/usr/bin/env python3
"""Build native joints and finite timelines from the untouched generated alpha atlas."""
from pathlib import Path
import xml.etree.ElementTree as E
import math,json,hashlib
ROOT=Path(__file__).resolve().parents[1];DEST=ROOT/'Image/Factory'
# name, atlas rectangle, pivot position, atlas anchor, uniform scale, parent
PARTS=[
 ('farLeg',(540,492,186,400),(-55,270),(.55,.97),.62,'rig'),
 ('farBoot',(59,921,281,245),(-66,85),(.36,.88),.52,'farLeg'),
 ('farArm',(879,87,331,347),(-48,485),(.23,.94),.65,'rig'),
 ('body',(441,101,337,340),(0,247),(.5,.06),.80,'rig'),
 ('nearLeg',(896,465,260,427),(55,263),(.46,.96),.60,'rig'),
 ('nearBoot',(431,935,285,239),(52,72),(.36,.88),.54,'nearLeg'),
 ('head',(62,71,348,365),(16,480),(.5,.07),.68,'rig'),
 ('rifle',(732,901,493,270),(114,347),(.26,.35),.67,'nearArm'),
 ('nearArm',(49,467,381,385),(-55,483),(.23,.91),.65,'rig')]
STATES={'idle':120,'prepare':90,'fmove':72,'shoot':84,'hit':36,'lose':96}
def vec(v):return ','.join(f'{x:.4f}' for x in v)
def pose(p,state,u):
 name,rect,(x,y),anchor,scale,parent=p; angle=0
 if name=='rig':
  if state in ('idle','prepare'): y=1.7*math.sin(u*2*math.pi)
  elif state=='fmove':y=4*math.sin(u*4*math.pi)
  elif state=='hit':x=14*math.sin(u*4*math.pi)*(1-u)
  elif state=='lose':angle=90*min(1,u/.72);y=100*min(1,u/.72);x=-110*min(1,u/.72)
 elif name.endswith('Leg') and state=='fmove':angle=17*math.sin(u*2*math.pi+(math.pi if name=='farLeg' else 0))
 elif name.endswith('Arm'):
  if state=='fmove':angle=3*math.sin(u*2*math.pi)
  elif state=='shoot':angle=-5*math.sin(u*math.pi)+5*math.exp(-((u-.58)/.08)**2)
  elif state=='lose':angle=22*min(1,u/.72)
 if parent not in ('rig',None):
  pp=next(v for v in PARTS if v[0]==parent);pa=pose(pp,state,u);px,py=pp[2];a=math.radians(-pa[2]);dx,dy=x-px,y-py
  x,y=pa[0]+dx*math.cos(a)-dy*math.sin(a),pa[1]+dx*math.sin(a)+dy*math.cos(a);angle+=pa[2]
 return x,y,angle
clip=E.Element('A',A='patrol-guard-parts-v1.png')
for name,rect,*_ in PARTS:E.SubElement(clip,'B',A=name,B=','.join(map(str,rect)))
E.ElementTree(clip).write(DEST/'patrol-guard.clip',encoding='unicode')
model=E.Element('A',A='patrol-guard.clip',D='800,760');root=E.SubElement(model,'B');rig=E.SubElement(root,'B',H='rig')
allparts=[('rig',None,(0,0),(.5,.5),1,None)]+PARTS
for part in allparts:
 name,rect,pos,anchor,scale,parent=part
 node=rig if name=='rig' else E.SubElement(rig,'B',A=vec(anchor),D=vec(pos),E=vec((scale,scale)),F='0',H=name,I=name,J='1')
 for state,frames in STATES.items():
  anim=E.SubElement(node,'C');last=0
  # Exact authored impact key and full finite end; do not schedule damage at action start.
  samples=sorted(set([round(frames*i/24) for i in range(25)]+([48] if state=='shoot' else [])))
  for f in samples:
   x,y,angle=pose(part,state,f/frames);attrs={'A':str(f-last),'C':'1','D':vec((x,y)),'E':vec((scale,scale)),'F':str(angle)}
   if name=='rig' and state=='shoot' and f==48:attrs['M']='guard-shot'
   E.SubElement(anim,'D',attrs);last=f
for i,state in enumerate(STATES):E.SubElement(model,'J',C=str(i),H=state)
E.ElementTree(model).write(DEST/'patrol-guard.model',encoding='unicode')
manifest={'artSource':'built-in image_gen','artStatus':'new adaptation: anonymous network patrol armour; not an original design sheet','source':'patrol-guard-parts-v1.png','sha256':hashlib.sha256((DEST/'patrol-guard-parts-v1.png').read_bytes()).hexdigest(),'parts':[{'name':p[0],'rect':p[1],'position':p[2],'anchor':p[3],'scale':p[4],'parent':p[5]} for p in PARTS],'animations':{k:v/60 for k,v in STATES.items()},'shotFrame':48,'framesPerSecond':60,'recovery':.2}
(DEST/'patrol-guard-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Built 9 guard joints and 6 timelines; source texture unchanged.')
