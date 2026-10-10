#!/usr/bin/env python3
"""Summarize read-only bundled Spine exports with angles unwrapped across phases."""
import json,sys
from collections import defaultdict
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1]) if len(sys.argv)>1 else root/'Docs/evidence/2026-10-03/q-character-bone-motion.tsv'
rows=defaultdict(list);duration={}
for line in source.read_text().splitlines():
 p=line.split('\t');asset=Path(p[1]).name
 if p[0]=='ANIM':duration.setdefault(asset,{})[p[2]]=float(p[3])
 elif p[0]=='BONE':rows[(asset,p[2],p[4])].append(tuple(map(float,p[5:])))
summary=[]
for (asset,animation,bone),vs in rows.items():
 if animation not in ['idle','fmove']:continue
 if bone not in ['bone','tou','jiaoL','jiaoR','zuotui4','youtui4','qun2','qun4','fawei1','fawei2','fawei5','jiaoik']:continue
 angles=[vs[0][2]]
 for v in vs[1:]:angles.append(angles[-1]+(v[2]-angles[-1]+180)%360-180)
 summary.append(dict(asset=asset,animation=animation,bone=bone,worldXRange=max(v[0]for v in vs)-min(v[0]for v in vs),worldYRange=max(v[1]for v in vs)-min(v[1]for v in vs),unwrappedAngleRange=max(angles)-min(angles)))
out=source.with_name('q-character-motion-analysis.json')
out.write_text(json.dumps(dict(method='Bundled Spine SkeletonBinary; 25 phases with setupPose+animation.apply+Physics_Reset, no playback physics history, sampled ranges not exact continuous extrema; angles unwrapped',durationSeconds=duration,bones=summary),indent=2)+'\n')
print(out)
