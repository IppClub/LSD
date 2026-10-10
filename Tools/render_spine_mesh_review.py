#!/usr/bin/env python3
"""Diagnostic mesh render using native evaluated vertices and original images.
Not a replacement for in-engine animation/recovery, shaders, audio or scene QA.
"""
import argparse,json,math,subprocess
from pathlib import Path
from PIL import Image,ImageDraw
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--tool',type=Path,required=True);p.add_argument('--atlas',type=Path,required=True);p.add_argument('--json',type=Path,required=True);p.add_argument('--images',type=Path);p.add_argument('--atlas-textures',action='store_true');p.add_argument('--clip',required=True);p.add_argument('--time',type=float,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
if not a.atlas_textures and not a.images:p.error('Supply original images or --atlas-textures')
result=subprocess.run([str(a.tool),str(a.atlas),str(a.json),a.clip,str(a.time)],capture_output=True,text=True,check=True)
d=json.loads(result.stdout);canvas=Image.new('RGBA',(800,750),(25,34,46,255));floor=660;scale=2.4
ImageDraw.Draw(canvas).line((0,floor,800,floor),fill=(220,230,240),width=2)
actor=Image.new('RGBA',canvas.size)
for m in d['meshes']:
 texture=a.atlas.parent/m['page'] if a.atlas_textures else a.images/(m['path']+'.png')
 tex=Image.open(texture).convert('RGBA');vs=m['vertices'];uv=m['atlasUVs'] if a.atlas_textures else m['uvs'];layer=Image.new('RGBA',canvas.size)
 points=[(500+vs[i]*scale,floor-vs[i+1]*scale) for i in range(0,len(vs),2)]
 ts=m['triangles']
 for i in range(0,len(ts),3):
  ids=ts[i:i+3];dest=[points[j] for j in ids];src=[(uv[2*j]*tex.width,uv[2*j+1]*tex.height) for j in ids]
  x0,y0=dest[0];x1,y1=dest[1];x2,y2=dest[2];det=(x1-x0)*(y2-y0)-(x2-x0)*(y1-y0)
  if abs(det)<1e-6:continue
  def coeff(values):
   q0,q1,q2=values;A=((q1-q0)*(y2-y0)-(q2-q0)*(y1-y0))/det;B=((x1-x0)*(q2-q0)-(x2-x0)*(q1-q0))/det
   return A,B,q0-A*x0-B*y0
  left=max(0,math.floor(min(x for x,y in dest)));top=max(0,math.floor(min(y for x,y in dest)));right=min(800,math.ceil(max(x for x,y in dest)));bottom=min(750,math.ceil(max(y for x,y in dest)))
  if right<=left or bottom<=top:continue
  A,B,C=coeff([s[0] for s in src]);D,E,F=coeff([s[1] for s in src])
  patch=tex.transform((right-left,bottom-top),Image.Transform.AFFINE,(A,B,C+A*left+B*top,D,E,F+D*left+E*top),Image.Resampling.BICUBIC)
  mask=Image.new('L',patch.size);ImageDraw.Draw(mask).polygon([(x-left,y-top) for x,y in dest],fill=255)
  # Paste neighboring triangles into one slot layer, then alpha compose the slot once.
  layer.paste(patch,(left,top),mask)
 actor=Image.alpha_composite(actor,layer)
canvas=Image.alpha_composite(canvas,actor)
ImageDraw.Draw(canvas).text((12,12),a.clip+' '+str(a.time)+'s / native vertices diagnostic',fill='white')
a.output.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(a.output)
a.output.with_suffix('.mesh.json').write_text(json.dumps(d))
bbox=actor.getchannel('A').point(lambda value:255 if value>=128 else 0).getbbox()
a.output.with_suffix('.contact.json').write_text(json.dumps({'atlasTextures':a.atlas_textures,'alphaThreshold':128,'scale':scale,'silhouetteMinimumY':(floor-bbox[3]+1)/scale if bbox else None,'bbox':bbox,'scope':'Diagnostic atlas silhouette; scene rendering and recovery unverified'}))
print(a.output)
