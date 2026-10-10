#!/usr/bin/env python3
"""Author a contact-constrained loop on native evaluated character poses.

This is a candidate clip, never a replacement for the original combat assets.
The in-scene root must ascend risePerCycle over duration for planted contacts.
"""
from pathlib import Path
import copy,json,math,hashlib
R=Path(__file__).resolve().parents[1];OUT=R/'Spine/Roof';OUT.mkdir(exist_ok=True)
DURATION=2.4;RISE=60.;STANCE=.7;SAMPLES=144
rad=math.radians;deg=math.degrees

def contact(p,high):
    p%=1
    if p<=STANCE:return high-RISE*p
    t=(p-STANCE)/(1-STANCE);low=high-RISE*STANCE;m=-RISE*(1-STANCE)
    return (2*t**3-3*t*t+1)*low+(t**3-2*t*t+t)*m+(-2*t**3+3*t*t)*high+(t**3-t*t)*m

def fk(bones,local):
    out={}
    for b in bones:
        n=b['name'];p=local[n];par=out.get(b.get('parent'),(0,0,0,1))
        x,y,a,s=par;c=math.cos(rad(a));sn=math.sin(rad(a))
        angle=p['rotation']+(0 if b.get('inherit')=='noRotationOrReflection' else a)
        out[n]=(x+s*(p['x']*c-p['y']*sn),y+s*(p['x']*sn+p['y']*c),angle,s*p['scaleX'])
    return out

def wrap(a):return (a+180)%360-180

reports=[]
for name in ['charM','charF','ninilite']:
    data=json.loads((R/f'Spine/ControlPod/{name}.json').read_text());bones=data['bones'];defs={b['name']:b for b in bones}
    original=R/('Docs/artwork/reference-export/ninilite.json' if name=='ninilite' else f'Docs/artwork/interrogation/{name}/source-export/{name}.json')
    original_data=json.loads(original.read_text())
    for action in ['jump','jumping','landing']:data['animations'][action]=copy.deepcopy(original_data['animations'][action])
    pose=json.loads((OUT/f'{name}-idle-pose.json').read_text());base={b['name']:b for b in pose['bones']};world=fk(bones,base)
    chains=([('shangbiL','xiabiL','shouL',1,0,'HandL'),('shangbiR','xiabiR','shouR',1,.5,'HandR'),('datuiL','xiaotuiL','jiaoL',-1,.5,'FootL'),('datuiR','xiaotuiR','jiaoR',-1,0,'FootR')] if name=='ninilite' else [('L_UpArm','L_Arm','L_Hand',1,0,'HandL'),('R_UpArm','R_Arm','R_Hand',1,.5,'HandR'),('L_UpLeg','L_Leg','L_Foot',-1,.5,'FootL'),('r_UpLeg','R_Leg','R_Foot',-1,0,'FootR')])
    # Start from native idle locals. Retain original skin/mesh/slot topology.
    clip={'bones':{},'slots':{s['name']:{'attachment':[{'name':s['attachment']}]} for s in pose['slots']}}
    for b in bones:
        n=b['name'];p=base[n]
        clip['bones'][n]={'translate':[{'x':p['x']-b.get('x',0),'y':p['y']-b.get('y',0)}],'rotate':[{'value':p['rotation']-b.get('rotation',0)}],'scale':[{'x':p['scaleX']/b.get('scaleX',1),'y':p['scaleY']/b.get('scaleY',1)}]}
    # Spine 4.3 stores constraints in the unified constraints list. Disable
    # them only for this baked contact clip, retaining original idle/aim behavior.
    clip['ik']={c['name']:[{'mix':0}] for c in data.get('constraints',[]) if c['type']=='ik'}
    clip['transform']={c['name']:[{'mixRotate':0,'mixX':0,'mixY':0,'mixScaleX':0,'mixScaleY':0,'mixShearY':0}] for c in data.get('constraints',[]) if c['type']=='transform'}
    if name=='charM':clip['slots']['body_21']={'attachment':[{'name':None}]}
    # Preserve sampled mesh deformations (the original idle starts at time zero).
    def freeze(v):
        if isinstance(v,list) and v and isinstance(v[0],dict):
            key=copy.deepcopy(v[0]);key.pop('curve',None);key['time']=0;return [key]
        if isinstance(v,dict):return {k:freeze(x) for k,x in v.items()}
        return copy.deepcopy(v)
    if 'attachments' in data['animations']['idle']:clip['attachments']=freeze(data['animations']['idle']['attachments'])
    report={'name':name,'maxReachClamp':0,'duration':DURATION,'risePerCycle':RISE,'stanceFraction':STANCE,'status':'candidate awaiting native visual and contact acceptance'}
    for upper,lower,end,bend,phase,label in chains:
        ishand=label.startswith('Hand');side=-1 if label.endswith('L') else 1
        high=world[upper][1]+36 if ishand else 55
        tx=(30 if side<0 else 40) if ishand else (10 if side<0 else 20)
        handoff=defs[end].get('length',0)*.35*world[end][3]
        delta=(0,handoff) if ishand else (7,-15)
        endangle=90 if ishand else world[end][2]
        off=( (delta[0]*math.cos(rad(endangle))+delta[1]*math.sin(rad(endangle)))/world[end][3],(-delta[0]*math.sin(rad(endangle))+delta[1]*math.cos(rad(endangle)))/world[end][3])
        point='climb'+label;data['slots'].append({'name':point,'bone':end,'attachment':point});data['skins'][0]['attachments'][point]={point:{'type':'point','x':off[0],'y':off[1]}}
        for n in [upper,lower,end]:clip['bones'][n]['rotate']=[]
        prev={}
        for i in range(SAMPLES+1):
            t=i/SAMPLES;local=copy.deepcopy(base);wx,wy=tx,contact(t+phase,high);target=(wx-delta[0],wy-delta[1]);w=fk(bones,local)
            ux,uy,ua,us=w[upper];l1=math.hypot(base[lower]['x'],base[lower]['y'])*us;l2=math.hypot(base[end]['x'],base[end]['y'])*w[lower][3]
            dx=target[0]-ux;dy=target[1]-uy;distance=math.hypot(dx,dy);clamped=min(l1+l2-.2,max(abs(l1-l2)+.2,distance));report['maxReachClamp']=max(report['maxReachClamp'],abs(clamped-distance))
            beta=bend*math.acos(max(-1,min(1,(clamped**2-l1*l1-l2*l2)/(2*l1*l2))))
            a=math.atan2(dy,dx)-math.atan2(l2*math.sin(beta),l1+l2*math.cos(beta))
            lowerOffset=deg(math.atan2(base[lower]['y'],base[lower]['x']));endOffset=deg(math.atan2(base[end]['y'],base[end]['x']))
            local[upper]['rotation']=deg(a)-lowerOffset-w[defs[upper]['parent']][2]
            local[lower]['rotation']=deg(beta)+lowerOffset-endOffset
            w=fk(bones,local);local[end]['rotation']=endangle-(0 if defs[end].get('inherit')=='noRotationOrReflection' else w[lower][2])
            for n in [upper,lower,end]:
                value=wrap(local[n]['rotation']-defs[n].get('rotation',0))
                if n in prev:value=prev[n]+wrap(value-prev[n])
                prev[n]=value;clip['bones'][n]['rotate'].append({'time':round(t*DURATION,6),'value':round(value,5)})
        report[label]={'x':tx,'highY':high,'phase':phase}
    data.setdefault('events',{}).update({'roofGripRight':{},'roofGripLeft':{}})
    clip['events']=[{'time':DURATION*STANCE,'name':'roofGripRight'},{'time':DURATION,'name':'roofGripLeft'}]
    data['animations']['climb']=clip
    # Release the wall at a cycle boundary and settle the lifted limbs before
    # enabling the original idle constraints through native recovery.
    settle=copy.deepcopy(clip);settle.pop('events',None)
    for n,timelines in settle['bones'].items():
        first=timelines['rotate'][0]['value'];last=base[n]['rotation']-defs[n].get('rotation',0)
        last=first+wrap(last-first)
        timelines['rotate']=[{'time':round(i/24*.4,6),'value':round(first+(last-first)*(3*(i/24)**2-2*(i/24)**3),5)} for i in range(25)]
    data['animations']['climbSettle']=settle
    enter=copy.deepcopy(settle)
    for timelines in enter['bones'].values():
        keys=timelines['rotate'];timelines['rotate']=[dict(k,time=round(.5-k['time']/.4*.5,6)) for k in reversed(keys)]
    data['animations']['climbEnter']=enter
    # At the wall lip, retain the left hand while pulling the body up 58 units.
    pull=copy.deepcopy(clip);pull.pop('events',None)
    for n,timelines in pull['bones'].items():timelines['rotate']=[dict(timelines['rotate'][0],time=0)]
    upper,lower,end,bend,phase,label=chains[0];delta=defs[end].get('length',0)*.35*world[end][3]
    for n in [upper,lower,end]:pull['bones'][n]['rotate']=[]
    for i in range(31):
        t=i/30;rise=58*(3*t*t-2*t*t*t);local=copy.deepcopy(base)
        ux,uy,ua,us=world[upper];l1=math.hypot(base[lower]['x'],base[lower]['y'])*us;l2=math.hypot(base[end]['x'],base[end]['y'])*world[lower][3]
        dx=30-ux;dy=report['HandL']['highY']-rise-delta-uy;distance=math.hypot(dx,dy)
        assert abs(l1-l2)<distance<l1+l2,(name,'pull reach',distance,l1+l2)
        beta=bend*math.acos(max(-1,min(1,(distance**2-l1*l1-l2*l2)/(2*l1*l2))))
        a=math.atan2(dy,dx)-math.atan2(l2*math.sin(beta),l1+l2*math.cos(beta))
        lo=deg(math.atan2(base[lower]['y'],base[lower]['x']));eo=deg(math.atan2(base[end]['y'],base[end]['x']))
        local[upper]['rotation']=deg(a)-lo-world[defs[upper]['parent']][2]
        local[lower]['rotation']=deg(beta)+lo-eo
        w=fk(bones,local);local[end]['rotation']=90-w[lower][2]
        for n in [upper,lower,end]:
            value=wrap(local[n]['rotation']-defs[n].get('rotation',0));keys=pull['bones'][n]['rotate']
            if keys:value=keys[-1]['value']+wrap(value-keys[-1]['value'])
            keys.append({'time':round(t*.5,6),'value':value})
    # The free arm relaxes without requiring another stationary handhold.
    for n in chains[1][:3]:
        first=clip['bones'][n]['rotate'][0]['value'];last=base[n]['rotation']-defs[n].get('rotation',0)
        pull['bones'][n]['rotate']=[{'time':round(i/30*.5,6),'value':first+wrap(last-first)*(3*(i/30)**2-2*(i/30)**3)} for i in range(31)]
    data.setdefault('events',{})['roofReleased']={};pull['events']=[{'time':.5,'name':'roofReleased'}]
    data['animations']['roofPull']=pull
    tuck=copy.deepcopy(pull);tuck.pop('events',None)
    for timelines in tuck['bones'].values():
        key=copy.deepcopy(timelines['rotate'][-1]);key['time']=0;timelines['rotate']=[key,dict(key,time=.6)]
    data['animations']['roofTuck']=tuck

    path=OUT/f'{name}.json';path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n');report['sha256']=hashlib.sha256(path.read_bytes()).hexdigest();reports.append(report)
(OUT/'climb-authoring.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(reports,ensure_ascii=False,indent=2))
