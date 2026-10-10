#!/usr/bin/env python3
"""Check staged atlas pages, declared sizes, clip rectangles and model clip links."""
from pathlib import Path
import argparse,json,re,struct,xml.etree.ElementTree as ET
parser=argparse.ArgumentParser();parser.add_argument('stage');parser.add_argument('--report',required=True);args=parser.parse_args()
root=Path(args.stage).resolve();errors=[];counts={'atlases':0,'pages':0,'clips':0,'rectangles':0,'models':0}
def image_size(path):
    data=path.read_bytes()
    if data[:8]!=b'\x89PNG\r\n\x1a\n': raise ValueError(f'Unsupported page format: {path.relative_to(root)}')
    return struct.unpack('>II',data[16:24])
def resolve(owner,name):
    path=(owner.parent/name).resolve()
    if root not in path.parents: raise ValueError('Resource escapes stage')
    if not path.is_file(): raise ValueError(f'Missing {name} referenced by {owner.relative_to(root)}')
    return path
for atlas in sorted(root.rglob('*.atlas')):
    counts['atlases']+=1
    try:
        lines=atlas.read_text().splitlines();pages=0
        for i,line in enumerate(lines):
            if not re.search(r'\.(png|jpg|jpeg)$',line.strip(),re.I): continue
            path=resolve(atlas,line.strip());size=image_size(path);pages+=1;counts['pages']+=1
            if i+1<len(lines) and lines[i+1].strip().startswith('size:'):
                declared=tuple(map(int,lines[i+1].split(':',1)[1].split(',')))
                if size!=declared: raise ValueError(f'Page size mismatch: {atlas.relative_to(root)} {declared} vs {size}')
        if not pages: raise ValueError(f'No image page in {atlas.relative_to(root)}')
    except (ValueError,OSError) as e: errors.append(str(e))
for clip in sorted(root.rglob('*.clip')):
    counts['clips']+=1
    try:
        tree=ET.parse(clip).getroot();page=resolve(clip,tree.attrib['A']);w,h=image_size(page)
        for region in tree:
            x,y,rw,rh=map(float,region.attrib['B'].split(','));counts['rectangles']+=1
            if min(x,y)<0 or min(rw,rh)<=0 or x+rw>w or y+rh>h:
                raise ValueError(f'Out of bounds clip: {clip.relative_to(root)} region {region.attrib.get("A")}')
    except (ValueError,OSError,KeyError,ET.ParseError) as e: errors.append(str(e))
for model in sorted(root.rglob('*.model')):
    counts['models']+=1
    try:
        tree=ET.parse(model).getroot();resolve(model,tree.attrib['A'])
    except (ValueError,OSError,KeyError,ET.ParseError) as e: errors.append(str(e))
report={'status':'PASS' if not errors else 'FAIL','scope':'Static atlas dependencies and clip bounds only','stage':str(root),'counts':counts,'errors':errors,'runtimeVerified':False}
Path(args.report).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False));raise SystemExit(bool(errors))
