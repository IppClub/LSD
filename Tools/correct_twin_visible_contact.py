#!/usr/bin/env python3
"""Isolated visible-contact baking from native meshes and real atlas alpha.
Transparent mesh margins are not treated as character contact. Never installs assets.
Requires the bundled NumPy/Pillow runtime; original rig and existing clips are preserved.
"""
import argparse,copy,hashlib,json,math,subprocess
from pathlib import Path
import numpy as np
from PIL import Image

p=argparse.ArgumentParser(description=__doc__)
for key in ['candidate','output','tool','game']:p.add_argument('--'+key,type=Path,required=True)
a=p.parse_args();a.output.mkdir(exist_ok=False)
records=[]
for name in ['vika','vivi']:
 source=a.candidate/name/(name+'-reactions.json');original=json.loads(source.read_text());data=copy.deepcopy(original)
 folder=a.output/name;folder.mkdir();file=folder/(name+'-reactions.json');atlas=a.game/'Spine'/(name+'.atlas')
 textures={};supports={}
 def native(path,clip,t):
  run=subprocess.run([str(a.tool),str(atlas),str(path),clip,str(t)],check=True,capture_output=True,text=True)
  return json.loads(run.stdout)['meshes']
 def visible_min(meshes):
  low=math.inf
  for m in meshes:
   page=m['page']
   if page not in textures:textures[page]=np.asarray(Image.open(atlas.parent/page).convert('RGBA'))[:,:,3]
   alpha=textures[page];h,w=alpha.shape
   uv=np.asarray(m['atlasUVs']).reshape(-1,2)*np.array([w,h]);world=np.asarray(m['vertices']).reshape(-1,2)
   key=(m['slot'],page,tuple(m['atlasUVs']),tuple(m['triangles']))
   if key not in supports:
    support=[]
    for offset in range(0,len(m['triangles']),3):
     ids=np.array(m['triangles'][offset:offset+3]);q=uv[ids]
     matrix=np.array([[q[0,0],q[1,0],q[2,0]],[q[0,1],q[1,1],q[2,1]],[1,1,1]])
     if abs(np.linalg.det(matrix))<1e-8:continue
     x0=max(0,int(np.floor(q[:,0].min())));x1=min(w,int(np.ceil(q[:,0].max())))
     y0=max(0,int(np.floor(q[:,1].min())));y1=min(h,int(np.ceil(q[:,1].max())))
     ys,xs=np.nonzero(alpha[y0:y1,x0:x1]>=128)
     pixels=np.stack([xs+x0+.5,ys+y0+.5,np.ones(len(xs))])
     bary=np.linalg.solve(matrix,pixels).T
     bary=bary[np.all(bary>=-1e-6,axis=1)]
     if len(bary):support.append((ids,bary))
    supports[key]=support
   for ids,bary in supports[key]:low=min(low,float((bary@world[ids,1]).min()))
  assert math.isfinite(low),'No visible atlas pixels'
  return low
 baseline=visible_min(native(source,'idle',0));corrections={}
 for clip,duration in [('fall',.9),('down',1),('standUp',1.14)]:
  root=data['animations'][clip]['bones'].setdefault('root',{})
  assert not root.get('translate'),'Use a candidate without previous root contact baking'
  times=[0,1] if clip=='down' else [min(duration,i/480) for i in range(math.ceil(duration*480)+1)]
  keys=[]
  for t in times:keys.append(dict(time=t,x=0,y=baseline-visible_min(native(source,clip,t))))
  root['translate']=keys;corrections[clip]=dict(minimum=min(k['y'] for k in keys),maximum=max(k['y'] for k in keys))
 file.write_text(json.dumps(data,separators=(',',':')))
 samples=[]
 for clip,duration in [('fall',.9),('down',1),('standUp',1.14)]:
  times=[0,.5,1] if clip=='down' else [min(duration,i/960) for i in range(math.ceil(duration*960)+1)]
  for t in times:
   meshes=native(file,clip,t);visible=visible_min(meshes)
   samples.append(dict(clip=clip,time=t,visibleMinimumY=visible,meshMinimumY=min(v for m in meshes for v in m['vertices'][1::2])))
 error=max(abs(s['visibleMinimumY']-baseline) for s in samples)
 (folder/'contact-analysis.json').write_text(json.dumps(dict(baseline=baseline,maximumError=error,samples=samples),indent=2))
 assert error<.6,(name,'Visible contact interpolation error',error)
 down=native(file,'down',0);rise=native(file,'standUp',0)
 assert all(x['slot']==y['slot'] and x['vertices']==y['vertices'] for x,y in zip(down,rise)) and len(down)==len(rise)
 for key in ['bones','slots','constraints','skins']:assert data[key]==original[key]
 for key,clip in original['animations'].items():
  if key not in ['fall','down','standUp']:assert data['animations'][key]==clip
 records.append(dict(model=name,originalVisibleIdleMinimumY=baseline,maximumContactError=error,
                     corrections=corrections,downRiseVerticesExact=True,samples=samples))
manifest=dict(status='CANDIDATE_NOT_INSTALLED',source=str(a.candidate),productionInstalled=False,
              editorExportVerified=False,fullVisualAcceptance=False,alphaThreshold=128,
              scope='Native atlas alpha contact only; game playback/recovery/scene acceptance pending',
              toolSha256=hashlib.sha256(a.tool.read_bytes()).hexdigest(),records=records)
(a.output/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps({'status':manifest['status'],'output':str(a.output),
                 'records':[{k:r[k] for k in ['model','originalVisibleIdleMinimumY','maximumContactError','corrections']} for r in records]}))
