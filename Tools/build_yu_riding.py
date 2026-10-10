#!/usr/bin/env python3
"""Author a separate seated-motion candidate on Yu's original weighted rig."""
from pathlib import Path
import copy,json,math
root=Path(__file__).resolve().parents[1];base=root/'Docs/artwork/yu-riding'
data=json.loads((base/'original-project-export/yu.json').read_text())
data['skeleton']['images']='./images/'
data['skeleton']['audio']='./audio/'
def first(node):
    if isinstance(node,list):
        if not node or node[0].get('time',0)>0:return []
        k=copy.deepcopy(node[0]);k.pop('time',None);k.pop('curve',None);return [k]
    return {k:v for k,c in node.items() if (v:=first(c))}
neutral=first(data['animations']['idle'])
def keys(start,end,duration,key):
    # Smooth acceleration/deceleration, preserving exact endpoints.
    return [{key:start,'curve':[duration/3,start,duration*2/3,end]}, {'time':duration,key:end}]
def motion(start,end,duration):
    anim=copy.deepcopy(neutral);bones=anim.setdefault('bones',{})
    # Move both foot targets together with their child ankle targets. The
    # original two-bone IK remains responsible for the knee bending direction.
    for name in ('target6','target3'):
        tracks=bones.setdefault(name,{})
        origin=tracks.get('translate',[{}])[0]
        tracks.pop('translatex',None);tracks.pop('translatey',None)
        tracks['translate']=[]
        for step in range(9):
            t=step/8;blend=start+(end-start)*t*t*(3-2*t)
            tracks['translate'].append({'time':duration*t,'x':origin.get('x',0)+250*blend,'y':origin.get('y',0)+160*blend})
    # Drapery follows the upper leg, then hangs down past the knee. These
    # offsets are an authoring candidate and require native silhouette review.
    for chain in [('zong2','zong3','zong4'),('zong7','zong8','zong9'),('zong12','zong13','zong14'),('zong15','zong16','zong17'),('zong19','zong20','zong21'),('zong66','zong67','zong68')]:
        for name,offset in zip(chain,(0,0,0)):
            tracks=bones.setdefault(name,{})
            origin=tracks.get('rotate',[{}])[0].get('value',0)
            tracks['rotate']=keys(origin+offset*start,origin+offset*end,duration,'value')
    return anim
# Deform only the front skirt panel, keeping its waist border attached.
# Each weighted influence receives the same world-space displacement through
# its inverse bone matrix; original skin weights and original clips stay intact.
pose={b['name']:b for b in json.loads((base/'idle-pose.json').read_text())['bones']}
world={}
for bone in data['bones']:
    b=pose[bone['name']];rx=math.radians(b['rotation']+b['shearX']);ry=math.radians(b['rotation']+90+b['shearY'])
    a,c=math.cos(rx)*b['scaleX'],math.sin(rx)*b['scaleX'];bb,d=math.cos(ry)*b['scaleY'],math.sin(ry)*b['scaleY']
    if 'parent' in bone:
        pa,pb,pc,pd=world[bone['parent']];a,bb,c,d=pa*a+pb*c,pa*bb+pb*d,pc*a+pd*c,pc*bb+pd*d
    world[bone['name']]=(a,bb,c,d)
panel=data['skins'][0]['attachments']['item21']['item21'];vertices=panel['vertices'];i=0;deform=[]
while i<len(vertices):
    count=int(vertices[i]);i+=1;influences=[];y=0
    for _ in range(count):
        idx,x,yy,w=vertices[i:i+4];i+=4;name=data['bones'][int(idx)]['name'];a,b,c,d=world[name]
        y+=(c*x+d*yy+pose[name]['worldY'])*w;influences.append((name,w))
    t=max(0,min(1,(94-y)/48));dx,dy=40*t,20*t
    for name,w in influences:
        a,b,c,d=world[name];det=a*d-b*c;deform.extend([(d*dx-b*dy)/det,(-c*dx+a*dy)/det])
for name,start,end,duration in [('sit',0,1,.8),('ride',1,1,2),('stand',1,0,.8)]:
    anim=motion(start,end,duration);frames=[]
    for step in range(9):
        t=step/8;blend=start+(end-start)*t*t*(3-2*t)
        frames.append({'time':duration*t,'vertices':[v*blend for v in deform]})
    anim['attachments']={'default':{'item21':{'item21':{'deform':frames}}}}
    data['animations'][name]=anim
(base/'riding-candidate.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
(base/'riding-candidate-manifest.json').write_text(json.dumps({'status':'AUTHORING_CANDIDATE_NOT_RUNTIME','animations':{'sit':.8,'ride':2,'stand':.8},'approach':'Original leg and foot IK, unchanged limb scales; weighted skirt joint offsets','requires':['native silhouette and foot orientation review','palms-to-pelvis contact binding','full finite animation and recovery validation'],'runtimeInstalled':False},ensure_ascii=False,indent=2)+'\n')
