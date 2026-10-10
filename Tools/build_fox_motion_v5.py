#!/usr/bin/env python3
"""Landmark-bound candidate: pivots are measured in the unmodified source atlas.
All rotations account for the source bone's slanted bind vector. No PNG edits.
"""
from pathlib import Path
import math,json,xml.etree.ElementTree as E
DEST=Path(__file__).resolve().parents[1]/'Image/Companion'
# rect, actual proximal pixel landmark, actual distal pixel landmark, scale
ART={
 'nearThigh':((145,733,114,195),(210,754),(196,898),.65),
 'farThigh':((861,732,115,196),(916,754),(924,898),.65),
 'nearShin':((501,773,129,222),(566,821),(563,993),.65),
 'nearFoot':((501,975,129,80),(563,993),None,.65),
 'farShin':((1192,773,135,222),(1262,821),(1262,993),.65),
 'farFoot':((1192,975,135,80),(1262,993),None,.65),
 'nearUpperArm':((130,506,139,188),(243,530),(159,671),.32),
 'farUpperArm':((842,505,156,201),(867,529),(964,681),.32),
 'nearForearm':((449,554,184,158),(590,556),(510,650),.44),
 'farForearm':((1187,559,183,154),(1244,560),(1306,651),.44),
 'body':((483,119,189,283),(577.5,260.5),None,.65),
 'skirt':((1101,77,347,311),(1268,103),None,.84),
 'head':((8,25,404,425),(210,382),None,.76)}
ORDER=['leftRear','rightRear','farThigh','farShin','farFoot','nearThigh','nearShin','nearFoot','farUpperArm','nearUpperArm','skirt','body','farForearm','nearForearm','head']
STATES={'idle':120,'move':60,'prepare':120}
def vec(v):return ','.join(f'{x:.6f}'for x in v)
def rotate(v,r):
 a=math.radians(-r);return(v[0]*math.cos(a)-v[1]*math.sin(a),v[0]*math.sin(a)+v[1]*math.cos(a))
def artvector(name):
 _,a,b,s=ART[name];return((b[0]-a[0])*s*(-1 if name=='farShin'else 1),(a[1]-b[1])*s)
def angle(v):return math.degrees(math.atan2(v[1],v[0]))
def endpoint(p,name):
 x,y,r=p[name];dx,dy=rotate(artvector(name),r);return x+dx,y+dy

def poses(state,u):
 # Begin at the idle foot X positions: near foot planted, far foot lifting.
 if state=='move':u=(u+.3)%1
 w=math.sin(2*math.pi*u);bob=1.5*w if state!='move' else -15+2*math.sin(4*math.pi*u)
 lean=.5*w if state!='move' else 1.1*w
 p={'rig':(0,0,0),'body':(0,340+bob,lean)}
 def attach(name,parent,offset,r=0):
  x,y,pr=p[parent];dx,dy=rotate(offset,pr);p[name]=(x+dx,y+dy,pr+r)
 attach('head','body',(0,70),.5*math.sin(2*math.pi*u-.3))
 attach('leftRear','head',(-85,27),1.5*math.sin(2*math.pi*u-.5))
 attach('rightRear','head',(54,64),1.3*math.sin(2*math.pi*u-.8))
 attach('skirt','body',(0,-60),1.8*math.sin(2*math.pi*u-.6))
 for side,prefix in [(-1,'near'),(1,'far')]:
  hip=(31*side,258+bob);foot=(40*side,57)
  if state=='move':
   phase=(u+(0 if side==-1 else .5))%1
   # Source faces left: a planted sole moves right in model coordinates.
   if phase<.6: foot=(40*side-70+140*phase/.6,57)
   else:
    t=(phase-.6)/.4;s=t*t*(3-2*t)
    foot=(40*side+70-140*s,57+26*math.sin(math.pi*t)**2)
  a=math.hypot(*artvector(prefix+'Thigh'));b=math.hypot(*artvector(prefix+'Shin'))
  dx,dy=foot[0]-hip[0],foot[1]-hip[1];d=math.hypot(dx,dy)
  assert abs(a-b)<d<a+b,(prefix,state,u,d,a+b)
  q=(a*a-b*b+d*d)/(2*d);h=math.sqrt(max(0,a*a-q*q));ux,uy=dx/d,dy/d
  knee=(hip[0]+q*ux+h*uy,hip[1]+q*uy-h*ux) # knee bends toward left-facing art
  for name,origin,target in [(prefix+'Thigh',hip,knee),(prefix+'Shin',knee,foot)]:
   desired=(target[0]-origin[0],target[1]-origin[1]);r=angle(artvector(name))-angle(desired)
   p[name]=(*origin,r)
  p[prefix+'Foot']=(*foot,0)
  swing=side*9*w if state=='move'else side*.9*math.sin(2*math.pi*u-.2)
  attach(prefix+'UpperArm','body',(-38.025 if side==-1 else 41.925,58.175),swing)
  elbow=endpoint(p,prefix+'UpperArm');p[prefix+'Forearm']=(*elbow,p[prefix+'UpperArm'][2]+(side*4*math.sin(2*math.pi*u-.4) if state=='move'else .7*math.sin(2*math.pi*u-.5)))
 return p
clip=E.Element('A',A='fox-chibi-parts-v2.png')
for name,(rect,*_)in ART.items():E.SubElement(clip,'B',A=name,B=','.join(map(str,rect)))
m=E.Element('A',A='fox-chibi-motion-v5.clip',D='617,699');root=E.SubElement(m,'B');rig=E.SubElement(root,'B',H='rig')
# Native parent bones keep artwork endpoints connected during recovery as well.
# Visible sprites use transformTarget so drawing order stays independent of FK ancestry.
PARENT={'body':'rig','head':'body','skirt':'body','leftRear':'head','rightRear':'head'}
for prefix in ('near','far'):
 PARENT.update({prefix+'UpperArm':'body',prefix+'Forearm':prefix+'UpperArm',prefix+'Thigh':'rig',prefix+'Shin':prefix+'Thigh',prefix+'Foot':prefix+'Shin'})
BONE_ORDER=['body','head','skirt','leftRear','rightRear','farThigh','farShin','farFoot','nearThigh','nearShin','nearFoot','farUpperArm','farForearm','nearUpperArm','nearForearm']
bones={'rig':rig}
def local_pose(name,state,u):
 p=poses(state,u);parent=PARENT[name];x,y,r=p[name];px,py,pr=p[parent]
 dx,dy=rotate((x-px,y-py),-pr)
 return dx,dy,r-pr
for name in BONE_ORDER:
 x,y,r=local_pose(name,'idle',0)
 n=E.SubElement(bones[PARENT[name]],'B',D=vec((x,y)),F=str(r),H=name+'-bone');bones[name]=n
 for state,frames in STATES.items():
  c=E.SubElement(n,'C')
  for f in range(frames+1):
   x,y,r=local_pose(name,state,f/frames);E.SubElement(c,'D',A=str(0 if f==0 else 1),C='1',D=vec((x,y)),F=f'{r:.6f}')
for name in ORDER:
 if name in ART:
  rect,pivot,_,scale=ART[name];anchor=((pivot[0]-rect[0])/rect[2],1-(pivot[1]-rect[1])/rect[3])
  sx=-scale if name in ('farShin','farFoot')else scale
  E.SubElement(rig,'B',A=vec(anchor),D='0,0',E=vec((sx,scale)),H=name,I=name,J='1')
 else:E.SubElement(rig,'B',H=name)
clock=E.SubElement(rig,'B',H='step-clock')
for state,frames in STATES.items():
 c=E.SubElement(clock,'C');last=0
 keys=[0,12,27,42,57,60] if state=='move' else list(range(0,frames+1,15))
 for f in keys:
  attrs={'A':str(f-last),'C':'1','D':f'{f},0'}
  if state=='move'and f in (27,57):attrs['M']='step'
  E.SubElement(c,'D',**attrs);last=f
for i,state in enumerate(STATES):E.SubElement(m,'J',C=str(i),H=state)
for state,frames in STATES.items():
 for f in range(frames+1):
  p=poses(state,f/frames)
  for prefix in ['near','far']:
   assert math.dist(endpoint(p,prefix+'UpperArm'),p[prefix+'Forearm'][:2])<1e-8
   assert math.dist(endpoint(p,prefix+'Thigh'),p[prefix+'Shin'][:2])<1e-8
E.ElementTree(clip).write(DEST/'fox-chibi-motion-v5.clip',encoding='unicode')
E.ElementTree(m).write(DEST/'fox-chibi-motion-v5.model',encoding='unicode')
(DEST/'fox-chibi-motion-v5-manifest.json').write_text(json.dumps(dict(status='joint and direction repair integrated; startup blending and final animation polish pending',artFacesRight=False,reference='Q-huli.png',source='fox-chibi-parts-v2.png',landmarks=ART,parts=len(ORDER),renderParts=ORDER,nativeBoneHierarchy=PARENT,frames=STATES,strideDistance=140,stanceSeconds=.6,sourceAngleCorrection=True,mirroredParts=['farShin','farFoot'],footForwardLandmarks={'nearFoot':[525,1038],'farFoot':[1298,1038]},recovery=.2,startPhase=.3,anticipationSeconds=.2),ensure_ascii=False,indent=2)+'\n')
print('Built v5 using actual source attachment landmarks and bind-angle correction.')
