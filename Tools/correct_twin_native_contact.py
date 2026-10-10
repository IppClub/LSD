#!/usr/bin/env python3
"""Bake baseline-relative contact into isolated clips using native Spine IK.
Does not install assets or change existing animations, bone lengths or actor position.
"""
import argparse, copy, hashlib, json, math, subprocess
from pathlib import Path

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--candidate',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--tool',type=Path,required=True)
p.add_argument('--game',type=Path,required=True)
a=p.parse_args();a.output.mkdir(exist_ok=False)
records=[]
for name in ['vika','vivi']:
 source=a.candidate/name/(name+'-reactions.json')
 original=json.loads(source.read_text());data=copy.deepcopy(original)
 folder=a.output/name;folder.mkdir();file=folder/(name+'-reactions.json')
 atlas=a.game/'Spine'/(name+'.atlas')
 def minimum(path,clip,t):
  result=subprocess.run([str(a.tool),str(atlas),str(path),clip,str(t)],check=True,capture_output=True,text=True)
  meshes=json.loads(result.stdout)['meshes']
  return min(v for mesh in meshes for v in mesh['vertices'][1::2])
 # Original animations remain in the candidate byte-for-byte as authored JSON.
 baseline=minimum(source,'idle',0)
 # Preserve the source shoe outline below zero; a positive idle clearance
 # does not require lifting every FK pose to exactly the same height.
 target=min(.5,baseline-.05)
 corrections={}
 for clip,duration in [('fall',.9),('standUp',1.14)]:
  root=data['animations'][clip]['bones'].setdefault('root',{})
  assert not root.get('translate'),'Existing root motion requires explicit adaptation'
  keys=[]
  for i in range(math.ceil(duration*120)+1):
   t=min(duration,i/120);low=minimum(source,clip,t)
   keys.append({'time':t,'x':0,'y':max(0,target-low)})
  root['translate']=keys;corrections[clip]=max(k['y'] for k in keys)
 file.write_text(json.dumps(data,separators=(',',':')))
 samples=[]
 for clip,duration in [('fall',.9),('standUp',1.14)]:
  for i in range(math.ceil(duration*240)+1):
   t=min(duration,i/240);low=minimum(file,clip,t)
   samples.append(dict(clip=clip,time=t,minY=low))
 # Dense native evaluation is independent of the 60 Hz authoring samples.
 low=min(x['minY'] for x in samples)
 assert low>=target-.10,(name,'Baseline-relative penetration',baseline,low)
 for key in ['bones','slots','constraints','skins']:assert data[key]==original[key]
 for key,clip in original['animations'].items():
  if key not in ['fall','standUp']:assert data['animations'][key]==clip
 records.append(dict(model=name,originalIdleMinimumY=baseline,correctedMinimumY=low,
                     correctionMaximum=corrections,samples=samples))
manifest=dict(status='CANDIDATE_NOT_INSTALLED',source=str(a.candidate),
              productionInstalled=False,editorExportVerified=False,fullVisualAcceptance=False,
              scope='Native baseline-relative mesh contact only; scene playback and recovery pending',
              toolSha256=hashlib.sha256(a.tool.read_bytes()).hexdigest(),records=records)
(a.output/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps({k:v for k,v in manifest.items() if k!='records'}))
