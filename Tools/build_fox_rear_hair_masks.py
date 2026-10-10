#!/usr/bin/env python3
"""Read generated alpha into native stencil runs. Never modify source PNG bytes."""
from pathlib import Path
from collections import deque
from array import array
from PIL import Image
import json,hashlib
root=Path(__file__).resolve().parents[1];dest=root/'Image/Companion';source=dest/'fox-chibi-rear-hair-v1.png'
im=Image.open(source);w,h=im.size;alpha=im.getchannel('A').tobytes();labels=array('i',[0])*(w*h);components=[];part_id=0
for start in range(w*h):
 if labels[start] or not alpha[start]:continue
 part_id+=1;q=deque([start]);labels[start]=part_id;count=0;x0=w;y0=h;x1=y1=0
 while q:
  i=q.popleft();y,x=divmod(i,w);count+=1;x0=min(x0,x);x1=max(x1,x);y0=min(y0,y);y1=max(y1,y)
  for j in [i-w if y else -1,i+w if y+1<h else -1,i-1 if x else -1,i+1 if x+1<w else -1]:
   if j>=0 and not labels[j]and alpha[j]:labels[j]=part_id;q.append(j)
 if count>10000:components.append(dict(id=part_id,count=count,rect=[x0,y0,x1-x0+1,y1-y0+1]))
assert len(components)==2,'Hair parts must be disconnected, got '+str(components)
parts=[]
for i,c in enumerate(sorted(components,key=lambda c:c['rect'][0])):
 x0,y0,rw,rh=c['rect'];runs=[];previous={}
 for y in range(y0,y0+rh):
  current={};x=x0
  while x<x0+rw:
   if labels[y*w+x]!=c['id']:x+=1;continue
   start=x
   while x<x0+rw and labels[y*w+x]==c['id']:x+=1
   key=(start-x0,x-start)
   if key in previous:
    idx=previous[key];runs[idx][3]+=1
   else:
    idx=len(runs);runs.append([start-x0,y-y0,x-start,1])
   current[key]=idx
  previous=current
 name='leftRear'if i==0 else'rightRear'
 parts.append(dict(name=name,rect=c['rect'],anchor=[.58,.95]if i==0 else[.2,.9],scale=[.28,.22]if i==0 else[.29,.29],maskRuns=runs,sourcePixels=c['count']))
manifest=dict(source=source.name,sha256=hashlib.sha256(source.read_bytes()).hexdigest(),sourceCanvas=[w,h],status='native component isolation; visual assembly still required',parts=parts)
(dest/'fox-chibi-rear-hair-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
import xml.etree.ElementTree as E
clip=E.Element('A',A=source.name)
for p in parts:E.SubElement(clip,'B',A=p['name'],B=','.join(map(str,p['rect'])))
E.ElementTree(clip).write(dest/'fox-chibi-rear-hair.clip',encoding='unicode')
print([(p['name'],p['rect'],len(p['maskRuns']))for p in parts])
