#!/usr/bin/env python3
"""Isolated rear-hair motion candidate based on authored Q rhythms. Does not replace FoxCompanion.
Atlas rectangles subdivide existing candidate textures; PNG bytes remain intact.
Art fidelity, blink layers and hair chains still require separate acceptance.
"""
from pathlib import Path
import math,json,xml.etree.ElementTree as E
DEST=Path(__file__).resolve().parents[1]/'Image/Companion'
# texture rectangle, bind anchor, bind scale; order is deliberate.
PARTS=[
 ('leftRear',None,(.5,.5),1),('rightRear',None,(.5,.5),1),
 ('farThigh',(869,735,104,316),(.5,.96),.34),('farShin',(1197,778,118,240),(.5,.95),.65),('farFoot',(1197,1008,118,40),(.5,.5),.65),
 ('nearThigh',(151,735,104,316),(.5,.96),.34),('nearShin',(507,777,116,244),(.5,.95),.65),('nearFoot',(507,1010,116,41),(.5,.5),.65),
 ('farUpperArm',(846,550,146,151),(.15,.96),.4),('nearUpperArm',(133,550,131,141),(.82,.96),.4),
 ('body',(483,119,189,283),(.5,.5),.65),('skirt',(1101,77,347,311),(.5,.9),.69),
 ('farForearm',(1189,542,174,167),(.17,.96),.52),('nearForearm',(452,540,178,171),(.88,.96),.5),('head',(8,25,404,425),(.5,.16),.8)]
STATES={'idle':120,'move':60,'prepare':120}
def foot(side,state,u):
 x=45*side
 if state!='move':return x,15,0
 # Planted 60% of a stride, then a raised return; the opposite leg is half a stride behind.
 p=(u-.25+(0 if side==-1 else .5))%1
 if p<.6:return x+90-180*p/.6,15,0
 t=(p-.6)/.4;s=t*t*(3-2*t)
 return x-90+180*s,15+40*math.sin(math.pi*t)**2,10*math.sin(math.pi*t)
def solve(hip,ankle):
 hx,hy=hip;ax,ay=ankle;dx,dy=ax-hx,ay-hy;d=math.hypot(dx,dy);a,b=108,158
 assert abs(a-b)<d<a+b,'Unreachable ankle'
 q=(a*a-b*b+d*d)/(2*d);h=math.sqrt(max(0,a*a-q*q));ux,uy=dx/d,dy/d
 # Knees bend toward the direction of travel.
 return hx+q*ux-h*uy,hy+q*uy+h*ux
def poses(state,u):
 wave=math.sin(2*math.pi*u)
 bob=1.8*wave if state!='move' else -20+3.2*math.sin(4*math.pi*u-.3)
 lean=.7*wave if state!='move' else 1.2*math.sin(4*math.pi*u-.1)
 p={'rig':(0,0,0),'body':(0,325+bob,lean)}
 def attach(name,parent,bind_parent,bind_child,relative=0):
  x,y,r=p[parent];dx,dy=bind_child[0]-bind_parent[0],bind_child[1]-bind_parent[1];a=math.radians(-r)
  p[name]=(x+dx*math.cos(a)-dy*math.sin(a),y+dx*math.sin(a)+dy*math.cos(a),r+relative)
 attach('head','body',(0,325),(0,405),.6*math.sin(2*math.pi*u-.3))
 attach('leftRear','head',(0,405),(-85,445),2.3*math.sin(2*math.pi*u-.5))
 attach('rightRear','head',(0,405),(54,482),1.8*math.sin(2*math.pi*u-.8))
 attach('skirt','body',(0,325),(0,270),2.7*math.sin(2*math.pi*u-.6))
 for side,prefix in [(-1,'near'),(1,'far')]:
  hip=(33*side,270+bob);ax,ay,fr=foot(side,state,u);knee=solve(hip,(ax,ay))
  tr=-math.degrees(math.atan2(knee[0]-hip[0],hip[1]-knee[1]))
  sr=-math.degrees(math.atan2(ax-knee[0],knee[1]-ay))
  p[prefix+'Thigh']=(*hip,tr);p[prefix+'Shin']=(*knee,sr);p[prefix+'Foot']=(ax,ay,fr)
  swing=(20*side*wave if state=='move' else 1.6*side*math.sin(2*math.pi*u-.2))
  attach(prefix+'UpperArm','body',(0,325),(55*side,395),swing)
  attach(prefix+'Forearm',prefix+'UpperArm',(55*side,395),(80*side,345),(7*side*math.sin(2*math.pi*u-.45) if state=='move' else 1.5*math.sin(2*math.pi*u-.6)))
 return p
def vec(v):return ','.join(f'{x:.5f}'for x in v)
clip=E.Element('A',A='fox-chibi-parts-v2.png')
for name,rect,*_ in PARTS:
 if rect:E.SubElement(clip,'B',A=name,B=','.join(map(str,rect)))
m=E.Element('A',A='fox-chibi-motion-v3.clip',D='617,699');root=E.SubElement(m,'B');rig=E.SubElement(root,'B',H='rig')
for name,rect,anchor,scale in [('rig',None,(.5,.5),1)]+PARTS:
 n=rig if name=='rig' else E.SubElement(rig,'B',A=vec(anchor),D=vec(poses('idle',0)[name][:2]),E=vec((scale,scale)),F=f"{poses('idle',0)[name][2]:.5f}",H=name,**({'I':name,'J':'1'}if rect else{}))
 for state,frames in STATES.items():
  c=E.SubElement(n,'C');last=0
  for f in range(frames+1):
   x,y,r=poses(state,f/frames)[name];attrs=dict(A=str(f-last),C='1',D=vec((x,y)),E=vec((scale,scale)),F=f'{r:.5f}')
   E.SubElement(c,'D',**attrs);last=f
# Model emits events at segment start. An emit-only frame consumes no duration;
# keep a separate invisible clock with a duration-bearing position property.
clock=E.SubElement(rig,'B',H='step-clock')
for state,frames in STATES.items():
 c=E.SubElement(clock,'C')
 for f in range(0,frames+1,15):
  attrs={'A':str(0 if f==0 else 15),'C':'1','D':f'{f},0'}
  if state=='move'and f in (30,60):attrs['M']='step'
  E.SubElement(c,'D',**attrs)
for i,state in enumerate(STATES):E.SubElement(m,'J',C=str(i),H=state)
# Pure geometry validation is supplementary to native interpolation and visual checks.
for state,frames in STATES.items():
 for f in range(frames+1):
  p=poses(state,f/frames)
  for prefix in ['near','far']:
   h,k,a=[p[prefix+s][:2]for s in ['Thigh','Shin','Foot']]
   assert abs(math.dist(h,k)-108)<1e-8 and abs(math.dist(k,a)-158)<1e-8
   if state!='move':assert a[1]==15
E.ElementTree(clip).write(DEST/'fox-chibi-motion-v3.clip',encoding='unicode')
E.ElementTree(m).write(DEST/'fox-chibi-motion-v3.model',encoding='unicode')
(DEST/'fox-chibi-motion-v3-manifest.json').write_text(json.dumps(dict(status='rear-hair and proportion candidate; NOT adopted; blink and scene acceptance pending',reference='Q-huli.png',learnedFrom=['ninilite','wuyun','charF'],parts=len(PARTS),externalParts='fox-chibi-rear-hair-manifest.json',frames=STATES,recovery=.2,footPlant='two-bone IK to separate foot with fixed idle ground contact and 60 percent stance',stanceDistance=180,stanceSeconds=.6,speedAtWorldVelocity200AndHeight300=200/(180*(300/699)/.6),stepClockKeyFrames=[0,15,30,45,60],stepEventAttributeFrames=[30,60],stepContactFrames=[15,45],remaining=['match original silhouette and rear bow','blink and separate front hair','review knee texture seam and torso occlusion','actual scene transitions and long loops']),ensure_ascii=False,indent=2)+'\n')
print('Built 15-part composite Q motion candidate; original companion unchanged.')
