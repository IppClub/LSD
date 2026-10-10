#!/usr/bin/env python3
"""Create a fresh runtime-only staging directory; this is not a platform installer."""
from pathlib import Path
import argparse, hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[1]
DIRECTORIES=('Data','Font','Image','Music','Script','Sound','Spine','UI')
FILES=('init.lua','init.yue','LICENSE','README.md')
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True);args=parser.parse_args()
    target=Path(args.output).resolve()
    if target==ROOT or ROOT in target.parents: raise RuntimeError('Stage must be outside the source project')
    if target.exists(): raise RuntimeError('Stage already exists; choose a fresh directory')
    paths=[]
    for directory in DIRECTORIES:
        for src in sorted((ROOT/directory).rglob('*')):
            relative=src.relative_to(ROOT)
            if any(part.startswith('.') or part=='__pycache__' for part in relative.parts): continue
            if src.is_symlink(): raise RuntimeError(f'Symlink requires review: {relative}')
            if src.is_file(): paths.append(src)
    paths.extend(ROOT/name for name in FILES)
    for src in paths:
        if src.suffix in ('.lua','.yue','.xml','.tsx','.ts'):
            text=src.read_text()
            if any(term in text for term in ('Docs/artwork/','/Users/','/private/tmp/')):
                raise RuntimeError(f'Development path in runtime source: {src.relative_to(ROOT)}')
    target.mkdir(parents=True)
    manifest=[]
    for src in paths:
        relative=src.relative_to(ROOT);dst=target/relative;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
        data=dst.read_bytes();manifest.append(dict(path=relative.as_posix(),bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
    metadata={'kind':'runtime-stage','engineBundled':False,'runtimeVerified':False,'files':manifest,'fileCount':len(manifest),'totalBytes':sum(row['bytes'] for row in manifest),'excludedRoots':['Docs','Test','Tools','.agent','.git']}
    (target/'runtime-manifest.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in metadata.items() if k!='files'},ensure_ascii=False));print(target)
if __name__=='__main__': main()
