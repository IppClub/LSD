#!/usr/bin/env python3
"""Author a separate seated-motion candidate on Yu's original weighted rig."""
from pathlib import Path
import copy,json
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
            tracks['translate'].append({'time':duration*t,'x':origin.get('x',0)+350*blend,'y':origin.get('y',0)+300*blend})
    # Drapery follows the upper leg, then hangs down past the knee. These
    # offsets are an authoring candidate and require native silhouette review.
    for chain in [('zong2','zong3','zong4'),('zong7','zong8','zong9'),('zong12','zong13','zong14'),('zong15','zong16','zong17'),('zong19','zong20','zong21'),('zong66','zong67','zong68')]:
        for name,offset in zip(chain,(55,-30,-25)):
            tracks=bones.setdefault(name,{})
            origin=tracks.get('rotate',[{}])[0].get('value',0)
            tracks['rotate']=keys(origin+offset*start,origin+offset*end,duration,'value')
    return anim
for name,start,end,duration in [('sit',0,1,.8),('ride',1,1,2),('stand',1,0,.8)]:data['animations'][name]=motion(start,end,duration)
(base/'riding-candidate.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
(base/'riding-candidate-manifest.json').write_text(json.dumps({'status':'AUTHORING_CANDIDATE_NOT_RUNTIME','animations':{'sit':.8,'ride':2,'stand':.8},'approach':'Original leg and foot IK, unchanged limb scales; weighted skirt joint offsets','requires':['native silhouette and foot orientation review','palms-to-pelvis contact binding','full finite animation and recovery validation'],'runtimeInstalled':False},ensure_ascii=False,indent=2)+'\n')
