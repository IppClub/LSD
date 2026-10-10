#!/usr/bin/env python3
"""Spine mesh prototype. Retarget actual authored Q timelines; preserve source PNGs.
This is a visual candidate, never an automatic art-quality acceptance.
"""
from pathlib import Path
import copy,json,math,shutil
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'Spine/FoxPrototype';OUT.mkdir(parents=True,exist_ok=True)
source=json.loads((ROOT/'Docs/artwork/reference-export/ninilite.json').read_text())
# Reuse measured pixel landmarks and corrected assembly without its procedural timelines.
ns={'__file__':str(ROOT/'Tools/build_fox_motion_v5.py')}
exec((ROOT/'Tools/build_fox_motion_v5.py').read_text().split("clip=E.Element")[0],ns)
art=ns['ART'];pose=ns['poses']('idle',0)
def rot(x,y,r):
 a=math.radians(r);return x*math.cos(a)-y*math.sin(a),x*math.sin(a)+y*math.cos(a)
bones=[];bind={};mapping={};factors={}
def add(name,parent,x,y,angle=0,length=0,source_name=None,translation=.43,inherit=None):
 px,py,pa=bind[parent] if parent else (0,0,0);lx,ly=rot(x-px,y-py,-pa)
 b={'name':name}
 if parent:b['parent']=parent
 b.update(x=lx,y=ly,rotation=angle if inherit else angle-pa)
 if length:b['length']=length
 if inherit:b['inherit']=inherit
 bones.append(b);bind[name]=(x,y,angle);mapping[name]=source_name or name;factors[name]=translation
add('root',None,0,0)
add('bone2','root',0,0)
add('bone','bone2',0,258)
add('shangbanshen','bone',0,258,90,82)
add('shangbanshen2','shangbanshen',0,340,90,70)
add('tou','shangbanshen2',0,410,90)
add('qunzi1','bone',0,258,-90,40)
for prefix,side in [('near','L'),('far','R')]:
 upper=prefix+'UpperArm';fore=prefix+'Forearm';hx,hy,r=pose[upper];v=ns['artvector'](upper);a=math.degrees(math.atan2(v[1],v[0]))-r
 parent='shangbanshen2'
 if side=='R':add('shangbiRfix',parent,hx,hy,70.71486);parent='shangbiRfix'
 add('shangbi'+side,parent,hx,hy,a,math.hypot(*v),translation=.30)
 ex,ey,r=pose[fore];v=ns['artvector'](fore);a=math.degrees(math.atan2(v[1],v[0]))-r
 add('xiabi'+side,'shangbi'+side,ex,ey,a,math.hypot(*v),translation=.40)
 wx,wy=ns['endpoint'](pose,fore);add('shou'+side,'xiabi'+side,wx,wy,a,translation=.40)
 thigh=prefix+'Thigh';shin=prefix+'Shin';foot=prefix+'Foot'
 hx,hy,r=pose[thigh];v=ns['artvector'](thigh);a=math.degrees(math.atan2(v[1],v[0]))-r
 add('datui'+side,'qunzi1',hx,hy,a,math.hypot(*v))
 kx,ky,r=pose[shin];v=ns['artvector'](shin);a=math.degrees(math.atan2(v[1],v[0]))-r
 add('xiaotui'+side,'datui'+side,kx,ky,a,math.hypot(*v))
 fx,fy,r=pose[foot];add('jiao'+side,'xiaotui'+side,fx,fy,0,inherit='noRotationOrReflection')
 add('1' if side=='L'else '2','root',fx,fy)
# Curved cloth/hair use multiple influences rather than rotating a whole card.
for side,prefix,sources,x in [('L','rearL',['fawei1','fawei2','fawei3','fawei4'], -85),('R','rearR',['fawei10','fawei14','fawei15','fawei16'],54)]:
 for i,src in enumerate(sources):add(prefix+str(i),'tou' if i==0 else prefix+str(i-1),x+(i*5 if side=='R'else -i*3),445-i*48,-90,48,src)
for prefix,sources,x in [('clothL',['qunzi2','qunzi3','qunzi4'],-40),('clothR',['qunzi5','qunzi6','qunzi7'],45)]:
 for i,src in enumerate(sources):add(prefix+str(i),'qunzi1' if i==0 else prefix+str(i-1),x+(-i*16 if prefix=='clothL'else i*16),265-i*72,-90,72,src)
for prefix,sources,x in [('frontL',['liuhai3','liuhai4','liuhai8'],-95),('frontR',['liuhai5','liuhai6','liuhai7'],95)]:
 for i,src in enumerate(sources):add(prefix+str(i),'tou' if i==0 else prefix+str(i-1),x,460-i*28,-90,28,src)
index={b['name']:i for i,b in enumerate(bones)}
def local(name,x,y):
 bx,by,ba=bind[name];return rot(x-bx,y-by,-ba)
# Midshaft alpha widths measured perpendicular to the unmodified source artwork.
# Scale only across the limb axis, preserving elbow/wrist positions and length.
ARM_WIDTHS={'nearUpperArm':(21.12,26),'farUpperArm':(23.36,27),
            'nearForearm':(33.88,31),'farForearm':(36.52,32)}
def weights(candidates,x,y,part=None):
 if part and part.endswith(('UpperArm','Thigh')):
  upper,lower=candidates;ax,ay,_=bind[upper];bx,by,_=bind[lower]
  vx,vy=bx-ax,by-ay;t=((x-ax)*vx+(y-ay)*vy)/(vx*vx+vy*vy)
  # Preserve upper-arm/thigh shafts; blend only the elbow/knee cap.
  u=max(0,min(1,(t-.85)/.22));u=u*u*(3-2*u)
  return [(upper,1-u),(lower,u)] if 0<u<1 else [(lower if u==1 else upper,1)]
 if len(candidates)==1:return [(candidates[0],1)]
 nearest=sorted(((math.hypot(x-bind[n][0],y-bind[n][1]),n)for n in candidates))[:2]
 a,b=nearest;u=(a[0]+.01)**-2;v=(b[0]+.01)**-2
 # Spine editor import requires each vertex's influences in skeleton order.
 # Runtime accepts distance order, which hid this error in native previews.
 return sorted([(a[1],u/(u+v)),(b[1],v/(u+v))],key=lambda influence:index[influence[0]])
def controls(name,x,y):
 if name.startswith('eyes'):return ['tou']
 if name=='head':
  # Keep the face rigid; soften only the lower side locks.
  if y<455 and abs(x)>75:return ['tou',('frontL'if x<0 else'frontR')+'1',('frontL'if x<0 else'frontR')+'2']
  return ['tou']
 if name=='body':return ['shangbanshen','shangbanshen2']
 if name=='skirt':return ['qunzi1']+[(('clothL' if x<0 else 'clothR')+str(i))for i in range(3)]
 if name in ('leftRear','rightRear'):return ['tou']+[(('rearL' if name=='leftRear' else 'rearR')+str(i))for i in range(4)]
 side='L'if name.startswith('near')else'R'
 if name.endswith('UpperArm'):return ['shangbi'+side,'xiabi'+side]
 # The whole painted gauntlet is rigid armor; wrist bending needs a separate hand attachment.
 if name.endswith('Forearm'):return ['xiabi'+side]
 if name.endswith('Thigh'):return ['datui'+side,'xiaotui'+side]
 # Keep the painted boot shaft rigid; ankle articulation belongs to the foot.
 if name.endswith('Shin'):return ['xiaotui'+side]
 return ['jiao'+side]
slots=[];attachments={};regions=[]
def triangulate(points):
 # Incremental Delaunay triangulation. Four non-collinear hull corners avoid
 # ambiguous collinear editing edges when Spine imports a rectangular mesh.
 pts=list(points)+[(-10,-10),(10,-10),(0,10)];n=len(points);tri=[(n,n+1,n+2)]
 def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
 def contains(t,p):
  a,b,c=[(pts[k][0]-p[0],pts[k][1]-p[1])for k in t]
  determinant=(a[0]*a[0]+a[1]*a[1])*(b[0]*c[1]-b[1]*c[0])-(b[0]*b[0]+b[1]*b[1])*(a[0]*c[1]-a[1]*c[0])+(c[0]*c[0]+c[1]*c[1])*(a[0]*b[1]-a[1]*b[0])
  return determinant>1e-12
 for i,p in enumerate(points):
  bad=[t for t in tri if contains(t,p)];edges={}
  for t in bad:
   for a,b in zip(t,t[1:]+t[:1]):
    key=tuple(sorted((a,b)));edges[key]=edges.get(key,0)+1
  tri=[t for t in tri if t not in bad]
  for (a,b),count in edges.items():
   if count==1:
    if cross(pts[a],pts[b],p)<0:a,b=b,a
    tri.append((a,b,i))
 result=[t for t in tri if max(t)<n]
 assert len(result)==2*n-6 and set(v for t in result for v in t)==set(range(n))
 assert abs(sum(cross(pts[a],pts[b],pts[c])/2 for a,b,c in result)-1)<1e-8
 return [v for t in result for v in t]
def mesh(name,rect,pixel,scale,placement,mirror=False,grid=(5,8)):
 x,y,w,h=rect;px,py=pixel;ox,oy,r=placement;nx,ny=grid
 points=[(0,0),(1,0),(1,1),(0,1)]+[(col/nx,row/ny)for row in range(1,ny)for col in range(1,nx)]
 uv=[];verts=[]
 for u,v in points:
  uv.extend([u,v]);dx=(x+u*w-px)*scale[0]*(-1 if mirror else 1);dy=(py-y-v*h)*scale[1]
  if name in ARM_WIDTHS:
   vx,vy=ns['artvector'](name);length=math.hypot(vx,vy);vx,vy=vx/length,vy/length
   along=dx*vx+dy*vy;across=(-dx*vy+dy*vx)*ARM_WIDTHS[name][1]/ARM_WIDTHS[name][0]
   dx,dy=along*vx-across*vy,along*vy+across*vx
  dx,dy=rot(dx,dy,-r);wx,wy=ox+dx,oy+dy
  ws=weights(controls(name,wx,wy),wx,wy,name);verts.append(len(ws))
  for bone,weight in ws:
   lx,ly=local(bone,wx,wy);verts.extend([index[bone],round(lx,6),round(ly,6),round(weight,8)])
 slots.append({'name':name,'bone':'root','attachment':name})
 attachments[name]={name:{'type':'mesh','path':name,'uvs':uv,'triangles':triangulate(points),'vertices':verts,'edges':[0,2,2,4,4,6,6,0],'hull':4,'width':w,'height':h}}
regions_body=[];regions_hair=[]
rear=json.loads((ROOT/'Image/Companion/fox-chibi-rear-hair-manifest.json').read_text())
for part in rear['parts']:
 rect=part['rect'];anchor=part['anchor'];pixel=(rect[0]+rect[2]*anchor[0],rect[1]+rect[3]*(1-anchor[1]));name=part['name']
 mesh(name,rect,pixel,part['scale'],pose[name],grid=(7,12));regions_hair.append((name,rect))
# Artist/user-corrected depth: atlas left arm is behind, atlas right arm is in front.
# Legacy near/far part names describe atlas labels, not trustworthy anatomical depth.
# Mirror the entire skeleton; never swap this slot order when turning.
# Atlas-left leg is behind atlas-right, matching the user's depth correction.
DRAW_ORDER=['nearThigh','nearShin','nearFoot','farThigh','farShin','farFoot',
 'nearUpperArm','nearForearm','skirt','body','farUpperArm','farForearm','head']
for name in DRAW_ORDER:
 if name not in art:continue
 rect,pixel,_,scale=art[name];mesh(name,rect,pixel,(scale,scale),pose[name],name in ('farShin','farFoot'));regions_body.append((name,rect))
# Eye-only replacement meshes preserve the original head, ears and hair outline.
for phase in ('Half','Closed'):
 name='eyes'+phase
 mesh(name,(78,274,184,60),art['head'][1],(.76,.76),pose['head'],grid=(1,1))
eyes={name:attachments.pop(name)[name]for name in ('eyesHalf','eyesClosed')}
slots[-2:]=[{'name':'eyes','bone':'root'}];attachments['eyes']=eyes
animations={}
for state in ('idle','fmove','prepare'):
 original=source['animations'][state];tracks={}
 for name,src in mapping.items():
  if src not in original.get('bones',{}):continue
  track=copy.deepcopy(original['bones'][src]);factor=factors[name]
  # Preserve fox limb lengths: source character's corrective joint translations
  # are tailored to different attachment landmarks, not transferable proportions.
  if name.startswith(('xiabi','shou')):
   track={channel:keys for channel,keys in track.items()if not channel.startswith('translate')}
  for channel,keys in track.items():
   if channel.startswith('translate'):
    for key in keys:
     for prop in ('x','y','value'):
      if prop in key:key[prop]*=factor
     curve=key.get('curve')
     if isinstance(curve,list):
      for i in range(1,len(curve),2):curve[i]*=factor
  tracks[name]=track
 animations[state]={'bones':tracks,'slots':{'eyes':{'attachment':[{'name':None}]}}}
 if state in ('idle','prepare'):
  duration=max(key.get('time',0)for track in tracks.values()for keys in track.values()for key in keys)
  start=duration*.65
  animations[state]['slots']['eyes']['attachment'] += [{'time':start,'name':'eyesHalf'},{'time':start+.025,'name':'eyesClosed'},{'time':start+.075,'name':'eyesHalf'},{'time':start+.1,'name':None}]
 if 'events'in original:animations[state]['events']=copy.deepcopy(original['events'])
 if 'ik'in original:animations[state]['ik']=copy.deepcopy(original['ik'])
# Fox-specific foot contacts. Authored poses, with native two-bone IK, retain
# the reference upper-body curves without transferring its different leg lengths.
# Left-facing art: during stance the planted foot travels toward +X locally.
# Horizontal offsets/velocities are scaled by .8 below: 105.6 units per stance,
# or 192 model units/second. Lower foot clearance avoids excessive knee folding.
# time, x, y, angle, and their derivatives. Stance remains linear; flight is C1.
FOOT_KEYS=[(0,-66,57,0,240,0,0),(.55,66,57,0,240,0,0),
           (.67,58,67,-6,-380,58,0),(.8,-25,71,6,-420,0,0),
           (.94,-76,61,3,0,-72,-50),(1,-66,57,0,240,0,0)]
def foot_sample(phase):
 for a,b in zip(FOOT_KEYS,FOOT_KEYS[1:]):
  if a[0]<=phase<=b[0]:
   span=b[0]-a[0];u=(phase-a[0])/span
   values=[];slopes=[]
   for i in range(1,4):
    p,q,da,db=a[i],b[i],a[i+3],b[i+3]
    values.append((2*u**3-3*u*u+1)*p+(u**3-2*u*u+u)*span*da+(-2*u**3+3*u*u)*q+(u**3-u*u)*span*db)
    slopes.append(((6*u*u-6*u)*p+(3*u*u-4*u+1)*span*da+(-6*u*u+6*u)*q+(3*u*u-2*u)*span*db)/span)
   return values,slopes
move=animations['fmove'];move['ik']={}
for side,target,offset,hip in [('L','1',.5,-31),('R','2',0,31)]:
 for bone_name in ('datui'+side,'xiaotui'+side):move['bones'][bone_name]={}
 move['ik'][target]=[{'mix':1,'bendPositive':True}]
 times=sorted({0.,1.}|{round((key[0]-offset)%1,6)for key in FOOT_KEYS})
 tx,ty,_=bind[target];translations=[];rotations=[];derivatives=[]
 for t in times:
  (x,y,r),slope=foot_sample((t+offset)%1)
  x*=.8;slope[0]*=.8
  translations.append({'time':t,'x':hip+x-tx,'y':y-ty});rotations.append({'time':t,'value':r});derivatives.append(slope)
 for i in range(len(times)-1):
  t0,t1=times[i:i+2];dt=(t1-t0)/3;curve=[]
  for axis,field in enumerate(('x','y')):
   curve += [t0+dt,translations[i][field]+derivatives[i][axis]*dt,t1-dt,translations[i+1][field]-derivatives[i+1][axis]*dt]
  translations[i]['curve']=curve
  rotations[i]['curve']=[t0+dt,rotations[i]['value']+derivatives[i][2]*dt,t1-dt,rotations[i+1]['value']-derivatives[i+1][2]*dt]
 move['bones'][target]={'translate':translations};move['bones']['jiao'+side]={'rotate':rotations}
# Reverse arm swing within its authored range to oppose the mirrored leg stride.
# Copying the old arm phase made the same-side arm and leg swing together.
for bone_name in ('shangbiL','shangbiR'):
 keys=move['bones'].get(bone_name,{}).get('rotate',[])
 if keys:
  center=min(k.get('value',0)for k in keys)+max(k.get('value',0)for k in keys)
  for key in keys:
   key['value']=center-key.get('value',0)
   if isinstance(key.get('curve'),list):
    for i in (1,3):key['curve'][i]=center-key['curve'][i]
# Elbows flex toward the character's front; they are not shoulder swing axes.
# Foreground is atlas-right (R), per the user's depth correction.
# Retarget each state's local flex independently. Preserve the source key times
# and breathing rhythm, while keeping all elbows on the same anatomical side.
for state,bone_name,min_flex,gain in [
 ('fmove','xiabiL',8,.55),('fmove','xiabiR',12,.7),
 ('idle','xiabiR',4,.5),
 ('prepare','xiabiL',40,1),('prepare','xiabiR',45,1)]:
 keys=animations[state]['bones'][bone_name].get('rotate',[])
 if not keys:continue
 source_min=min(key.get('value',0)for key in keys)
 source_max=max(key.get('value',0)for key in keys)
 setup=next(b['rotation']for b in bones if b['name']==bone_name)
 def flex(value):return -min_flex-gain*(max(source_min,min(source_max,value))-source_min)-setup
 for key in keys:
  key['value']=flex(key.get('value',0))
  if isinstance(key.get('curve'),list):
   for i in (1,3):key['curve'][i]=flex(key['curve'][i])
for key in move['bones']['bone'].get('rotate',[]):key['value']=-key.get('value',0)
# Reduce the copied crouch and bounce for the fox's longer reverse-jointed legs.
# Keep authored phase timing; lift the pelvis and reduce its vertical excursion.
for key in move['bones']['bone']['translate']:
 key['y']=-12.5+.3*(key.get('y',0)+12)
 if isinstance(key.get('curve'),list):
  for i in (5,7):
   if i<len(key['curve']):key['curve'][i]=-12.5+.3*(key['curve'][i]+12)
# Retarget the reference combat-ready stance to the fox's leg lengths. Its
# original lateral pelvis offset and unequal target heights overextend one leg.
ready=animations['prepare']
for key in ready['bones']['bone'].get('translate',[]):
 key['x']=-8+.3*(key.get('x',0)+101.3726849)
 key['y']=-18+.3*(key.get('y',0)+53.7405529)
 if isinstance(key.get('curve'),list):
  for i in (1,3):key['curve'][i]=-8+.3*(key['curve'][i]+101.3726849)
  for i in (5,7):key['curve'][i]=-18+.3*(key['curve'][i]+53.7405529)
for side,target,offset in [('L','1',-30),('R','2',30)]:
 for bone_name in ('datui'+side,'xiaotui'+side):ready['bones'][bone_name]={}
 ready['bones'][target]={'translate':[{'x':offset,'y':0}]}
 ready['bones']['jiao'+side]={'rotate':[{'value':0}]}
# Fox setup knees have positive local flex (~24 degrees). The reference rig's
# negative IK branch is incompatible with this bind geometry. Mirror the whole
# skeleton for facing; never change the anatomical bend branch on a turn.
for animation in animations.values():
 for target,keys in animation.get('ik',{}).items():
  if target in ('1','2'):
   for key in keys:key['bendPositive']=True
# Named, non-rendering points expose actual ankle positions to the game's
# existing Playable.getKey API, including native IK/recovery/mirroring.
for side in ('L','R'):
 name='contact'+side
 slots.append({'name':name,'bone':'jiao'+side,'attachment':name})
 attachments[name]={name:{'type':'point','x':0,'y':0,'rotation':0}}
# Keep IK active in the setup pose: Dora recovery briefly mixes through setup.
# Disabling it there lets the ankles sag below the ground during state changes.
data={'skeleton':{'spine':'4.3.10','images':'./fox-images','width':617,'height':699},'bones':bones,'slots':slots,'constraints':[{'type':'ik','name':s,'target':s,'bones':['datui'+side,'xiaotui'+side],'mix':1,'bendPositive':True}for s,side in [('1','L'),('2','R')]],'skins':[{'name':'default','attachments':attachments}],'events':source['events'],'animations':animations}
(OUT/'fox-chibi-spine.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
def atlas_page(filename,size,regions):
 s=f'{filename}\nsize:{size[0]},{size[1]}\nfilter:Linear,Linear\n'
 for name,rect in regions:s+=name+'\nbounds:'+','.join(map(str,rect))+'\n'
 return s
shutil.copyfile(ROOT/'Image/Companion/fox-chibi-parts-v2.png',OUT/'fox-parts.png');shutil.copyfile(ROOT/'Image/Companion/fox-chibi-rear-hair-v1.png',OUT/'fox-rear-hair.png')
(OUT/'fox-chibi-spine.atlas').write_text(atlas_page('fox-parts.png',(1448,1086),regions_body)+'\n'+atlas_page('fox-rear-hair.png',(1254,1254),regions_hair))
for phase in ('half','closed'):
 filename='fox-blink-'+phase+'.png';shutil.copyfile(ROOT/('Image/Companion/fox-chibi-blink-'+phase+'-atlas-v1.png'),OUT/filename)
 with (OUT/'fox-chibi-spine.atlas').open('a')as stream:stream.write('\n'+atlas_page(filename,(1448,1086),[('eyes'+phase.title(),(78,274,184,60))]))
(OUT/'manifest.json').write_text(json.dumps({'status':'prototype; visual and deformation acceptance required','sourceAnimation':'ninilite original authored curves; translations retargeted by bone family','bones':len(bones),'slots':len(slots),'meshAttachments':sum(v.get('type')=='mesh' for a in attachments.values() for v in a.values()),'contactPoints':2,'animations':list(animations),'reference':'Q-huli.png','gait':{'facesRight':False,'cycleSeconds':1,'stanceFraction':.55,'stanceTravel':105.6,'stanceModelSpeed':192,'ankleGroundY':57},'armWidths':ARM_WIDTHS,'retainedPNGBytes':True,'remaining':['native silhouette and motion review','rear hair region overlap','walking facial animation','joint weight refinement','start/stop/facing and scene acceptance']},ensure_ascii=False,indent=2)+'\n')
print('Built Spine prototype:',len(bones),'bones,',len(slots),'slots,',sum(v.get('type')=='mesh' for a in attachments.values() for v in a.values()),'mesh attachments, authored idle/fmove/prepare curves.')
