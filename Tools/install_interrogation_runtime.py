#!/usr/bin/env python3
"""Install authored exports into runtime resources; --check detects stale copies."""
from pathlib import Path
import argparse, hashlib, json, shutil
ROOT = Path(__file__).resolve().parents[1]
PAIRS = [('Docs/artwork/researcher/export/actions.skel', 'Spine/StoryActions/researcher.skel')]
for role in ('wuyun', 'charM', 'charF'):
    PAIRS.append((f'Docs/artwork/interrogation/{role}/export/actions.skel', f'Spine/StoryActions/{role}.skel'))
for role in ('charM', 'charF'):
    PAIRS.append((f'Docs/artwork/interrogation/{role}/hand-fit.json', f'Spine/StoryActions/{role}-hand-fit.json'))
def install(check=False):
    rows=[]
    for source, target in PAIRS:
        src, dst = ROOT/source, ROOT/target
        if not src.is_file(): raise RuntimeError(f'Missing exported source: {source}')
        if not check:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
        if not dst.is_file() or src.read_bytes()!=dst.read_bytes():
            raise RuntimeError(f'Runtime export differs: {target}')
        rows.append(dict(source=source, asset=target, sha256=hashlib.sha256(dst.read_bytes()).hexdigest()))
    if not check:
        (ROOT/'Spine/StoryActions/source-manifest.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
    else:
        actual=json.loads((ROOT/'Spine/StoryActions/source-manifest.json').read_text())
        if actual!=rows: raise RuntimeError('Runtime provenance manifest is stale')
    print(f'{len(rows)} authored runtime assets verified')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true')
    install(parser.parse_args().check)
