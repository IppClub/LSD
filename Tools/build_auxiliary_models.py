#!/usr/bin/env python3
"""Generate editable Dora models from Zhou Daxi's untouched transparent part sheets.
Atlas rectangles are in source pixels. Joints and timelines are in model space.
Run from any directory; no raster processing or generated replacement artwork.
"""
from pathlib import Path
import shutil, hashlib, json, math, xml.etree.ElementTree as E
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT.parent.parent/'github/LSD-doc/docs/source/img/machine'
DEST=ROOT/'Image/Auxiliary'
# name, full original-pixel rectangle, joint position, anchor, motion role, parent.
# Positions use the artist's finished assembly, not the exploded-sheet spacing.
PARTS={
'defence':[
 ('frontBracket',(617,365,74,103),(-173.24,77.74),(.5,.5),'panel','rig'),
 ('rearTrack',(688,784,225,90),(-103.5,50),(.5,.5),'track','rig'),
 ('rearTread',(913,885,108,65),(-151,48),(.5,.5),'tread','rearTrack'),
 ('core',(859,403,219,135),(80.43,152.61),(.5,.5),'core','rig'),
 ('sensor',(849,651,144,96),(-74.62,133.35),(.5,.5),'sensor','rig'),
 ('rearBracket',(650,278,114,55),(-43,88.5),(.5,.5),'panel','rig'),
 ('frontArmour',(709,523,200,112),(-62.07,157.34),(.5,.5),'panel','rig'),
 ('vent',(954,559,57,54),(-16,164),(.5,.5),'panel','frontArmour'),
 ('frontTrack',(924,736,234,94),(32.68,48.27),(.5,.5),'track','rig'),
 ('frontTread',(1041,891,110,64),(-16,48),(.5,.5),'tread','frontTrack'),
 ('frontJoint',(977,602,150,71),(45.77,86.41),(.5,.5),'joint','rig'),
 ('sideRod',(797,376,58,24),(132,101),(.5,.5),'joint','rig'),
 ('sideKnee',(781,406,23,29),(114,58),(.5,.5),'joint','rig'),
 ('sideFoot',(812,428,27,23),(123,45),(.5,.5),'joint','rig'),
 ('sidePad',(780,476,32,17),(130,42),(.5,.5),'joint','rig'),
 ('sidePlate',(749,292,74,87),(152.15,95.1),(.5,.5),'panel','rig'),
 ('rearArmour',(859,256,268,131),(10.26,197.68),(.22,.8),'lid','rig')],
'cargo':[
 ('farLeftArm',(790,586,73,60),(-62,164),(.5,.5),'joint','rig'),
 ('rearLeft',(784,717,78,142),(-71.19,139.33),(.5,.9),'legBack','rig'),
 ('rearRight',(962,717,78,142),(83.23,139.75),(.5,.9),'legBack','rig'),
 ('rearLeftFoot',(742,831,39,25),(-91,32),(.5,.5),'foot','rearLeft'),
 ('rearRightFoot',(1043,831,39,25),(89,32),(.5,.5),'foot','rearRight'),
 ('hub',(859,586,141,159),(31.6,128.34),(.5,.5),'hub','rig'),
 ('leftLeg',(712,636,88,141),(-100.24,125.13),(.7,.9),'leg','rig'),
 ('rightLeg',(1047,636,87,141),(109.95,126.13),(.3,.9),'leg','rig'),
 ('leftFoot',(675,773,48,31),(-145,14),(.5,.5),'foot','leftLeg'),
 ('rightFoot',(1112,780,48,32),(161,14),(.5,.5),'foot','rightLeg'),
 ('leftArm',(802,877,72,61),(-62,84),(.5,.5),'joint','rig'),
 ('rightArm',(939,882,73,60),(76.2,85.87),(.5,.5),'joint','rig'),
 ('leftCrate',(679,466,198,97),(-101.7,206.95),(.5,.5),'crate','rig'),
 ('rightCrate',(923,461,213,102),(157.9,201.6),(.5,.5),'crate','rig'),
 ('lid',(778,42,125,133),(31,311),(.5,.05),'hatch','rig'),
 ('sensorBack',(935,95,94,90),(-17.59,357.29),(.5,.5),'panel','rig'),
 ('body',(651,213,209,235),(-9.02,284.07),(.5,.5),'body','rig'),
 ('sensor',(935,95,49,76),(-40.86,364.72),(.5,.5),'sensor','body'),
 ('crateLid',(975,327,145,105),(188.4,162.3),(.5,.1),'hatch','rightCrate')],
'mobility':[
 ('tail',(1017,252,145,79),(183.35,303.39),(.5,.5),'tail','rig'),
 ('sensorBack',(937,476,189,102),(-115.45,220.58),(.5,.5),'panel','rig'),
 ('rearHose',(1052,374,68,80),(-151,135),(.5,.5),'hose','rig'),
 ('body',(608,252,390,234),(-44.79,237.23),(.5,.5),'body','rig'),
 ('wing',(828,413,128,202),(-2.25,102.59),(.5,.5),'wing','rig'),
 ('frontShell',(486,273,145,91),(-87.79,311.49),(.5,.5),'panel','rig'),
 ('cap',(759,80,70,69),(-155,246),(.5,.5),'joint','rig'),
 ('nearThruster',(862,34,300,83),(125.22,240.03),(.5,.5),'thruster','rig'),
 ('hose',(862,148,168,91),(39.49,162.55),(.5,.5),'hose','rig'),
 ('sensor',(937,476,90,102),(-171.09,220.58),(.5,.5),'sensor','rig'),
 ('hood',(589,137,214,124),(-13.09,271.72),(.5,.5),'panel','rig'),
 ('pipe',(1077,185,58,48),(-74,211),(.5,.5),'joint','rig')]
}
PART_META={
 'defence':{'rearTread':{'keepAll':True},'frontTread':{'keepAll':True}},
 'cargo':{'lid':{'scaleY':.68,'openOffset':92},'crateLid':{'openOffset':76}},
 'mobility':{'sensor':{'scale':1.124},'sensorBack':{'scale':1.124},'rearHose':{'scale':.85,'rotation':17}}
}
REFERENCE={
 'defence':{'rect':[75,35,475,230],'origin':[320,260]},
 'cargo':{'rect':[42,289,470,494],'origin':[241.18,779]},
 'mobility':{'rect':[31,31,539,362],'origin':[270,390]}
}
STATES={'deploy':48,'idle':120,'move':72,'collect':96,'shield':60,'hit':30,'carry':84,'depleted':54,'lose':72}
def vec(v): return ','.join(f'{n:.4f}'.rstrip('0').rstrip('.') if n else '0' for n in v)
def pose(kind,role,name,x,y,state,u):
 meta=PART_META.get(kind,{}).get(name,{}); r=meta.get('rotation',0); sx=meta.get('scale',1); sy=meta.get('scaleY',sx); a=1; wave=math.sin(u*math.pi*2)
 if role=='rig':
  if kind=='mobility': y+=4*wave
  if state=='deploy': y+=(1-u)**2*65; a=min(1,u*3)
  elif state=='move': y+=4*math.sin(u*math.pi*4); r=3*wave if kind=='mobility' else 0
  elif state=='collect': r=-3*math.sin(u*math.pi); y-=4*math.sin(u*math.pi)
  elif state=='hit': x+=12*math.sin(u*math.pi*6)*(1-u); r=5*math.sin(u*math.pi*2)*(1-u)
  elif state in ('depleted','lose'): y-=u*(52 if kind=='mobility' else 12); r=u*(9 if state=='lose' else 3)
 elif role in ('leg','legBack'):
  if state=='move':
   phase=(0 if x<0 else math.pi)+(math.pi if role=='legBack' else 0)
   r=9*math.sin(u*math.pi*2+phase); y+=max(0,math.sin(u*math.pi*2+phase))*5
 elif role=='track' and state=='move': y+=1.5*math.sin(u*math.pi*8+(0 if x<0 else math.pi))
 elif role=='lid':
  if state in ('collect','carry'): r+=(-55 if kind=='defence' else -28 if x<=0 else 25)*math.sin(u*math.pi)**2
  elif state=='deploy': r+=-18*(1-u)
 elif role=='hatch':
  if state in ('collect','carry'): y+=meta['openOffset']*math.sin(u*math.pi)**2
 elif role=='sensor':
  if state=='idle': r=2*wave
  elif state=='collect': r=-10*math.sin(u*math.pi)
  elif state in ('depleted','lose'): r=18*u
 elif role=='wing': r=(4 if state=='move' else 1.5)*wave
 elif role=='thruster':
  if state=='move': sx=1+.025*wave
 elif role in ('core','light'):
  if state=='collect': sx=sy=1+.04*math.sin(u*math.pi)
 return {'C':str(a),'D':vec((x,y)),'E':vec((sx,sy)),'F':str(round(r,4))}
def joint_pose(kind,role,name,x,y,state,u):
 attrs=pose(kind,role,name,x,y,state,u)
 part=next((p for p in PARTS[kind] if p[0]==name),None)
 if part and part[5]!='rig':
  parent=next(p for p in PARTS[kind] if p[0]==part[5])
  px,py=parent[2]; pa=pose(kind,parent[4],parent[0],px,py,state,u)
  ax,ay=map(float,pa['D'].split(',')); angle=math.radians(-float(pa['F']))
  own_x,own_y=map(float,attrs['D'].split(',')); dx,dy=own_x-px,own_y-py
  attrs['D']=vec((ax+dx*math.cos(angle)-dy*math.sin(angle),ay+dx*math.sin(angle)+dy*math.cos(angle)))
  attrs['F']=str(round(float(attrs['F'])+float(pa['F']),4))
 return attrs
def component_mask(image, rect, keep_all=False):
 """Read-only alpha analysis: retain the largest connected part as native geometry.
 This prevents rectangular clips from including neighbouring detached components.
 Original texture bytes are never modified.
 """
 if keep_all: return None
 x,y,w,h=rect; alpha=image.getchannel('A').crop((x,y,x+w,y+h)); pixels=alpha.load()
 seen=set(); groups=[]
 for py in range(h):
  for px in range(w):
   if (px,py) in seen or pixels[px,py]==0: continue
   stack=[(px,py)]; seen.add((px,py)); group=[]
   while stack:
    xx,yy=stack.pop(); group.append((xx,yy))
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,1),(1,-1),(-1,-1)):
     nx,ny=xx+dx,yy+dy
     if 0<=nx<w and 0<=ny<h and (nx,ny) not in seen and pixels[nx,ny]>0:
      seen.add((nx,ny)); stack.append((nx,ny))
   groups.append(group)
 if len([g for g in groups if len(g)>20])<2: return None
 chosen=set(max(groups,key=len)); runs=[]; active={}
 for py in range(h):
  spans=[]; px=0
  while px<w:
   if (px,py) not in chosen: px+=1; continue
   first=px
   while px<w and (px,py) in chosen: px+=1
   spans.append((first,px-first))
  next_active={}
  for first,width in spans:
   key=(first,width)
   if key in active: index=active[key]; runs[index][3]+=1
   else: index=len(runs); runs.append([first,py,width,1])
   next_active[key]=index
  active=next_active
 return runs
manifest={'artist':'周大西','source':'LSD-doc/docs/source/gamedoc/setting/machine.md','format':'Dora Model / original PNG clip rectangles','variants':{}}
for kind,parts in PARTS.items():
 source={'defence':'d-machine','cargo':'a-machine','mobility':'s-machine'}[kind]
 shutil.copyfile(SOURCE/f'{source}.png',DEST/f'{source}.png')
 source_image=Image.open(SOURCE/f'{source}.png')
 clip=E.Element('A',A=f'{source}.png')
 for name,rect,*_ in parts: E.SubElement(clip,'B',A=name,B=','.join(map(str,rect)))
 E.ElementTree(clip).write(DEST/f'{kind}.clip',encoding='unicode')
 model=E.Element('A',A=f'{kind}.clip',D='640,560'); root=E.SubElement(model,'B'); rig=E.SubElement(root,'B',H='rig')
 allparts=[('rig',None,(0,0),(.5,.5),'rig',None)]+parts
 for name,rect,pos,anchor,role,parent in allparts:
  meta=PART_META.get(kind,{}).get(name,{})
  node=rig if name=='rig' else E.SubElement(rig,'B',A=vec(anchor),D=vec(pos),E=vec((meta.get('scale',1),meta.get('scaleY',meta.get('scale',1)))),F=str(meta.get('rotation',0)),H=name,I=name,J='1')
  for state,frames in STATES.items():
   anim=E.SubElement(node,'C'); steps=12
   previous=0
   for i in range(steps+1):
    f=round(frames*i/steps); attrs=joint_pose(kind,role,name,*pos,state,i/steps); attrs['A']=str(f-previous)
    if name=='rig' and state=='collect' and i==7: attrs['M']='energy-transfer'
    if name=='rig' and state=='shield' and i==4: attrs['M']='shield-ready'
    E.SubElement(anim,'D',attrs); previous=f
 for index,state in enumerate(STATES): E.SubElement(model,'J',C=str(index),H=state)
 E.SubElement(model,'K',A='core',B=vec((-98,114) if kind=='defence' else (-41,365) if kind=='cargo' else (-140,218)))
 E.ElementTree(model).write(DEST/f'{kind}.model',encoding='unicode')
 manifest['variants'][kind]={'source':source+'.png','sha256':hashlib.sha256((DEST/f'{source}.png').read_bytes()).hexdigest(),'parts':[{'name':p[0],'rect':p[1],'position':p[2],'anchor':p[3],'role':p[4], 'maskRuns':component_mask(source_image,p[1],PART_META.get(kind,{}).get(p[0],{}).get('keepAll',False)), 'parent':p[5], 'scale':PART_META.get(kind,{}).get(p[0],{}).get('scale',1), 'restScaleY':PART_META.get(kind,{}).get(p[0],{}).get('scaleY',PART_META.get(kind,{}).get(p[0],{}).get('scale',1)), 'openOffset':PART_META.get(kind,{}).get(p[0],{}).get('openOffset',0)} for p in parts],'reference':dict(REFERENCE[kind],maskRuns=component_mask(source_image,REFERENCE[kind]['rect'])), 'animations':{s:f/60 for s,f in STATES.items()}}
(DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Built three original-art models with 9 complete timelines each.')
