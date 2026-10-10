"""Author an isolated reaction candidate on the original twin rigs, never install it."""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path
import subprocess

parser=argparse.ArgumentParser()
parser.add_argument('--output',type=Path,required=True)
parser.add_argument('--full-reactions',action='store_true',help='Author fall/down/standUp candidates as well; never install')
parser.add_argument('--folded-rest',action='store_true',help='Isolated folded knees and near-hand support experiment')
parser.add_argument('--staged-rise',action='store_true',help='Lift torso before extending hips, for isolated visual review')
parser.add_argument('--json-only',action='store_true',help='Native mesh review without launching the editor; export still pending')
args=parser.parse_args()
assert not args.output.exists(),'Use a fresh candidate directory'
args.output.mkdir(parents=True)
editor='/Applications/Spine.app/Contents/MacOS/Spine'
origins={
 'vika':Path('/Users/Jin/Desktop/LSD/LSD美术/Q版/Q版 spine 双子 姐姐'),
 'vivi':Path('/Users/Jin/Desktop/LSD/LSD美术/Q版/Q版 spine 双子 妹妹')}

def freeze(node):
 if isinstance(node,list):
  if not node or node[0].get('time',0)>0:return []
  key=copy.deepcopy(node[0]);key.pop('curve',None);key['time']=0;return [key]
 if isinstance(node,dict):return {k:v for k,child in node.items() if (v:=freeze(child))}
 return copy.deepcopy(node)

def rotate(times,values):
 result=[]
 for i,(t,v) in enumerate(zip(times,values)):
  key={'time':t,'value':v}
  if i+1<len(times):
   span=times[i+1]-t;key['curve']=[t+span/3,v,times[i+1]-span/3,values[i+1]]
  result.append(key)
 return result

def translate(times,values):
 return [{'time':t,'x':x,'y':y}for t,(x,y)in zip(times,values)]

def equivalent(a,b):
 # The editor rounds exported float decimals. No track, key, or property may
 # disappear; only sub-pixel numerical roundoff is accepted.
 if isinstance(a,bool) or isinstance(b,bool):return type(a)==type(b) and a==b
 if isinstance(a,(int,float)) and isinstance(b,(int,float)):return abs(a-b)<1e-4
 if type(a)!=type(b):return False
 if isinstance(a,dict):return a.keys()==b.keys() and all(equivalent(a[k],b[k])for k in a)
 if isinstance(a,list):return len(a)==len(b) and all(equivalent(x,y)for x,y in zip(a,b))
 return a==b

def timeline_value(keys,time,field,default):
 if not keys:return default
 prev=keys[0]
 for nxt in keys[1:]:
  if nxt.get('time',0)>time:
   start,end=prev.get('time',0),nxt.get('time',0)
   v0,v1=prev.get(field,default),nxt.get(field,default)
   curve=prev.get('curve')
   if curve=='stepped':return v0
   u=max(0,min(1,(time-start)/(end-start)))
   if isinstance(curve,list):
    # Generated rotation tracks have one time/value cubic, shared by runtime.
    assert field=='value' and len(curve)==4
    lo,hi=0,1
    for _ in range(32):
     z=(lo+hi)/2;q=1-z
     t=q*q*q*start+3*q*q*z*curve[0]+3*q*z*z*curve[2]+z*z*z*end
     if t<time:lo=z
     else:hi=z
    z=(lo+hi)/2;q=1-z
    return q*q*q*v0+3*q*q*z*curve[1]+3*q*z*z*curve[3]+z*z*z*v1
   return v0+(v1-v0)*u
  prev=nxt
 return prev.get(field,default)

def fk_mesh_min_y(data,clip,time):
 # This is only valid when all IK is released. It evaluates active weighted
 # mesh geometry, not the setup skeleton's stale bounding rectangle.
 assert all(b.get('inherit','normal')=='normal'for b in data['bones'])
 assert not clip.get('deform'),'FK contact evaluator does not support deform'
 world={};indexed=[]
 for bone in data['bones']:
  c=clip['bones'].get(bone['name'],{})
  def v(channel,field,default):return timeline_value(c.get(channel,[]),time,field,default)
  rot=bone.get('rotation',0)+v('rotate','value',0)
  rx=math.radians(rot+bone.get('shearX',0)+v('shear','x',0))
  ry=math.radians(rot+90+bone.get('shearY',0)+v('shear','y',0))
  sx=bone.get('scaleX',1)*v('scale','x',1);sy=bone.get('scaleY',1)*v('scale','y',1)
  q=[math.cos(rx)*sx,math.cos(ry)*sy,math.sin(rx)*sx,math.sin(ry)*sy,
   bone.get('x',0)+v('translate','x',0),bone.get('y',0)+v('translate','y',0)]
  if bone.get('parent'):
   A,B,C,E,X,Y=world[bone['parent']];a,b,c,e,x,y=q
   q=[A*a+B*c,A*b+B*e,C*a+E*c,C*b+E*e,A*x+B*y+X,C*x+E*y+Y]
  world[bone['name']]=q;indexed.append(q)
 points=[];skin=data['skins'][0]['attachments']
 for slot in data['slots']:
  name=slot.get('attachment');keys=clip.get('slots',{}).get(slot['name'],{}).get('attachment',[])
  for key in keys:
   if key.get('time',0)<=time:name=key.get('name')
  if not name:continue
  a=skin[slot['name']][name];assert a['type']=='mesh'
  vs=a['vertices'];count=len(a['uvs'])//2
  if len(vs)==count*2:
   A,B,C,E,X,Y=world[slot['bone']]
   points.extend(C*vs[2*i]+E*vs[2*i+1]+Y for i in range(count))
  else:
   k=0
   for _ in range(count):
    weights=int(vs[k]);k+=1;y=0
    for __ in range(weights):
     bi,vx,vy,w=vs[k:k+4];k+=4;A,B,C,E,X,Y=indexed[int(bi)]
     y+=(C*vx+E*vy+Y)*w
    points.append(y)
 return min(points)

def correct_fk_contact(data,clip,start,end):
 # Contact lives inside the asset. Never shift the actor's logical position or
 # stretch limbs to repair mesh penetration. Sample original motion at 60 Hz.
 channels=clip['bones']['zong'];source=copy.deepcopy(channels['translate'])
 root_scale=data['bones'][0].get('scaleY',1);assert root_scale>0
 times=sorted({round(i/60,8)for i in range(math.ceil(end*60)+1)if i/60<=end}|{start,end})
 fixed=[];adjustments=[]
 for t in times:
  x=timeline_value(source,t,'x',0);y=timeline_value(source,t,'y',0)
  delta=0
  if t>=start:
   low=fk_mesh_min_y(data,clip,t)
   # Less than one game unit of clearance also protects interpolation between
   # 60 Hz authored samples; a dense review found up to .49 unit undershoot.
   delta=max(0,.75-low)/root_scale
  fixed.append({'time':t,'x':x,'y':y+delta});adjustments.append({'time':t,'rootY':delta})
 channels['translate']=fixed
 # Only sample within the released-IK interval; the caller supplies that range.
 for row in adjustments:
  if row['time']>=start:assert fk_mesh_min_y(data,clip,row['time'])>=-1e-3,'Contact correction failed'
 return adjustments

manifest={'status':'CANDIDATE_NOT_INSTALLED','scope':'hurt only; fall and standUp still pending','models':{}}
for name,origin in origins.items():
 # Author from the runtime's 4.3 JSON. A 4.3 import of legacy 4.2 JSON can
 # silently discard the old root `ik` array; source JSON equality is insufficient.
 source=Path('/private/tmp/lsd-twins-source-review')/('current-'+name)/(name+'.json')
 original=json.loads(source.read_text());data=copy.deepcopy(original)
 assert original['skeleton']['spine'].startswith('4.3.')
 constraints=[c for c in original.get('constraints',[]) if c.get('type')=='ik']
 assert len(constraints)==4,'Original twin foot constraints missing'
 target=args.output/name;target.mkdir()
 data['skeleton']['images']=str(origin/'images')+'/'
 clip=freeze(original['animations']['idle'])
 times=[0,.055,.16,.28,.43,.64]
 weight=[0,.35,1,.60,-.12,0]
 # Pelvis, torso/neck, then delayed head: never stretch bone lengths or meshes.
 # The original root-space foot IK controllers retain their idle positions.
 angles={'zong3':9,'zong4':5,'zong5':-2,'zong6':-7}
 if name=='vika':angles.update(zong32=-5,zong33=8,zong36=5,zong37=-6)
 else:angles.update(zong40=-5,zong41=8,zong44=5,zong45=-6)
 for bone,amplitude in angles.items():
  channels=clip['bones'].setdefault(bone,{});base=channels.get('rotate',[{}])[0].get('value',0)
  channels['rotate']=rotate(times,[base+amplitude*w for w in weight])
 channels=clip['bones']['zong2'];base=channels.get('translate',[{}])[0]
 x,y=base.get('x',0),base.get('y',0)
 channels['translate']=translate(times,[(x-30*w,y-45*max(0,w))for w in weight])
 data['animations']['hurt']=clip
 if args.full_reactions:
  # Follow the original Wuyun fall's recoil/contact/settle timing, not its rig.
  # Root-space foot IK must release for a fall; otherwise the feet remain nailed
  # to the ground while the torso tips over. Original constraint topology stays.
  fall=freeze(original['animations']['idle'])
  ft=[0,.10,.24,.38,.56,.72,.90]
  w=[0,.12,.52,1.05,.94,1,1]
  angles={'zong':86,'zong3':-6,'zong4':4,'zong5':-3,'zong6':7}
  if name=='vika':
   angles.update(zong32=-24,zong33=30,zong36=22,zong37=-28,zong39=0,zong40=-5,zong42=5,zong43=-7,
    bone2=65,zong7=16,zong8=-5,zong10=8,zong11=10,zong12=5)
  else:
   angles.update(zong40=-24,zong41=30,zong44=22,zong45=-28,zong7=0,zong8=-5,zong10=5,zong11=-7)
  for bone,amplitude in angles.items():
   channels=fall['bones'].setdefault(bone,{});base=channels.get('rotate',[{}])[0].get('value',0)
   channels['rotate']=rotate(ft,[base+amplitude*v for v in w])
  # Independent limb arcs: knees lift/fold during loss of balance, then settle.
  # Avoid treating a fall as the standing pose rotated like a rigid plank.
  if name=='vika':
   arcs={'zong39':[0,18,52,30,4,-2,0],'zong40':[0,-12,-50,-35,-14,-7,-5],
    'zong42':[0,23,62,32,9,3,5],'zong43':[0,-14,-55,-38,-16,-9,-7],
    'zong32':[0,16,35,15,-12,-24,-24],'zong36':[0,-12,-34,-10,15,22,22]}
  else:
   arcs={'zong7':[0,18,52,30,4,-2,0],'zong8':[0,-12,-50,-35,-14,-7,-5],
    'zong10':[0,23,62,32,9,3,5],'zong11':[0,-14,-55,-38,-16,-9,-7],
    'zong40':[0,16,35,15,-12,-24,-24],'zong44':[0,-12,-34,-10,15,22,22]}
  idle=freeze(original['animations']['idle'])
  if args.folded_rest:
   # Keep bone lengths and topology. Fold the knees in the held pose, while
   # the near arm extends toward the floor instead of retaining idle silhouette.
   legs=('zong39','zong40','zong42','zong43') if name=='vika' else ('zong7','zong8','zong10','zong11')
   arms=('zong32','zong33') if name=='vika' else ('zong40','zong41')
   for bone,values in zip(legs,[[0,18,52,36,20,13,14],[0,-12,-50,-50,-43,-38,-38],[0,23,62,44,29,21,22],[0,-14,-55,-58,-49,-44,-44]]):arcs[bone]=values
   arcs[arms[0]]=[0,16,35,5,-26,-42,-42]
   arcs[arms[1]]=[0,8,24,12,-2,-4,-4]
   for bone,value in zip(legs+arms,[14,-38,22,-44,-42,-4]):angles[bone]=value
  for bone,values in arcs.items():
   baseline=idle.get('bones',{}).get(bone,{}).get('rotate',[{}])[0].get('value',0)
   fall['bones'][bone]['rotate']=rotate(ft,[baseline+v for v in values])
  z=fall['bones'].setdefault('zong',{});base=z.get('translate',[{}])[0]
  x,y=base.get('x',0),base.get('y',0)
  z['translate']=translate(ft,[(x-115*v,y-240*v)for v in w])
  fall['ik']={ik['name']:[{'time':0,'mix':1,'bendPositive':ik.get('bendPositive',True)},
    {'time':.05,'mix':0,'bendPositive':ik.get('bendPositive',True)}]for ik in constraints}
  fall_contact=correct_fk_contact(data,fall,.05,.90)
  data['animations']['fall']=fall
  down=copy.deepcopy(fall)
  for channels in down['bones'].values():
   for channel,keys in channels.items():
    last=copy.deepcopy(keys[-1]);last.pop('curve',None);last['time']=0
    terminal=copy.deepcopy(last);terminal['time']=1
    channels[channel]=[last,terminal]
  for channels in down['ik'].values():
   last=copy.deepcopy(channels[-1]);last['time']=0;channels[:]=[last]
  data['animations']['down']=down
  # Rise starts at exactly the held down pose, braces, then lifts hips and torso.
  # It is a separate paced action, not fall played backwards at arbitrary speed.
  up=freeze(original['animations']['idle']);ut=[0,.18,.40,.70,.96,1.14]
  uw=[1,.93,.67,.29,-.035,0]
  for bone in angles:
   channels=up['bones'].setdefault(bone,{});base=channels.get('rotate',[{}])[0].get('value',0)
   channels['rotate']=rotate(ut,[base+angles[bone]*v for v in uw])
  if name=='vika':
   arcs={'zong39':[0,8,56,25,4,0],'zong40':[-5,-25,-58,-28,-5,0],
    'zong42':[5,12,73,35,5,0],'zong43':[-7,-31,-62,-38,-6,0]}
  else:
   arcs={'zong7':[0,8,56,25,4,0],'zong8':[-5,-25,-58,-28,-5,0],
    'zong10':[5,12,73,35,5,0],'zong11':[-7,-31,-62,-38,-6,0]}
  if args.folded_rest:
   legs=('zong39','zong40','zong42','zong43') if name=='vika' else ('zong7','zong8','zong10','zong11')
   arms=('zong32','zong33') if name=='vika' else ('zong40','zong41')
   for bone,values in zip(legs,[[14,24,56,25,4,0],[-38,-54,-58,-28,-5,0],[22,35,73,35,5,0],[-44,-62,-62,-38,-6,0]]):arcs[bone]=values
   arcs[arms[0]]=[-42,-40,-26,-12,-2,0]
   arcs[arms[1]]=[-4,-12,-8,4,2,0]
  for bone,values in arcs.items():
   baseline=idle.get('bones',{}).get(bone,{}).get('rotate',[{}])[0].get('value',0)
   up['bones'][bone]['rotate']=rotate(ut,[baseline+v for v in values])
  if args.staged_rise:
   # Torso sits up while the pelvis and knees remain folded, then the hips
   # extend. This separates the rise from a rigid reversal of the fall.
   baseline=idle['bones'].get('zong3',{}).get('rotate',[{}])[0].get('value',0)
   up['bones']['zong3']['rotate']=rotate(ut,[baseline-6*v+extra for v,extra in zip(uw,[0,-18,-25,-8,0,0])])
  up['bones']['zong']['translate']=translate(ut,[(x-115*v,y-240*v)for v in uw])
  up['ik']={ik['name']:[{'time':0,'mix':0,'bendPositive':ik.get('bendPositive',True)},
    {'time':.70,'mix':0,'bendPositive':ik.get('bendPositive',True)},
    {'time':1.14,'mix':1,'bendPositive':ik.get('bendPositive',True)}]for ik in constraints}
  # Original rise translation is kept after the released-IK phase. The last
  # corrected sample blends into the original .96/1.14 keys without a snap.
  original_rise=copy.deepcopy(up['bones']['zong']['translate'])
  rise_contact=correct_fk_contact(data,up,0,.70)
  up['bones']['zong']['translate'].extend(k for k in original_rise if k['time']>.70)
  assert equivalent(down['bones']['zong']['translate'][0],up['bones']['zong']['translate'][0]),'Down/rise contact discontinuity'
  data['animations']['standUp']=up
  (target/'contact-samples.json').write_text(json.dumps({'scope':'released IK FK mesh contact only; native visual pending','fall':fall_contact,'standUp':rise_contact},indent=2))
 for key in ['bones','slots','ik','transform','constraints','skins']:
  assert data.get(key)==original.get(key),'Topology changed: '+key
 assert all(data['animations'][k]==v for k,v in original['animations'].items())
 file=target/(name+'-reactions.json');file.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')))
 if args.json_only:
  manifest['models'][name]={'source':str(source),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'json':str(file),'rigPreserved':True,'editorExportVerified':False,'nativeVisualAcceptance':False}
  continue
 project=target/(name+'-reactions.spine');export=target/'export'
 for label,argv in [
  ('import',[editor,'-i',str(file),'-o',str(project),'--replace','-r']),
  ('export',[editor,'-i',str(project),'-o',str(export),'-e','binary']),
  ('roundtrip',[editor,'-i',str(project),'-o',str(target/'roundtrip'),'-e','json'])]:
  with (target/(label+'.log')).open('w')as log:
   p=subprocess.run(argv,stdout=log,stderr=subprocess.STDOUT,timeout=120)
  assert p.returncode==0, label+' failed: '+str(target/(label+'.log'))
 roundtrip=json.loads((target/'roundtrip'/(name+'-reactions.json')).read_text())
 assert roundtrip.get('constraints')==original.get('constraints'),'Exported native constraints changed'
 assert len(roundtrip['bones'])==len(original['bones']) and len(roundtrip['slots'])==len(original['slots'])
 assert all(equivalent(a,roundtrip['animations'].get(k))for k,a in original['animations'].items()),'Original animation changed during editor import/export'
 manifest['models'][name]={'source':str(source),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'project':str(project),'export':str(export),'duration':.64,'originalAnimations':list(original['animations']),'rigPreserved':True,'exportConstraintsVerified':True,'exportOriginalAnimationsVerified':True,'candidateAnimations':{k:v for k,v in [('hurt',.64),('fall',.90),('down',1),('standUp',1.14)] if k in data['animations']}}
if args.full_reactions:manifest['scope']='hurt/fall/down/standUp candidates; visual ground contact and controller integration pending'
(args.output/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print(json.dumps({'status':manifest['status'],'output':str(args.output)}))
