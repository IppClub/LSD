#!/usr/bin/env python3
"""Rebuild authored actions and their matching native ground-contact samples."""
from pathlib import Path
import argparse, hashlib, json, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--bounds-tool',required=True);args=parser.parse_args()
art=ROOT/'Docs/artwork/researcher';editor='/Applications/Spine.app/Contents/MacOS/Spine'
def export():
    for label,command in [('import',[editor,'-i',str(art/'actions.json'),'-o',str(art/'actions.spine'),'--replace','-r']),('binary',[editor,'-i',str(art/'actions.spine'),'-o',str(art/'export'),'-e','binary'])]:
        with open('/private/tmp/researcher-actions-'+label+'.log','w') as log:
            subprocess.run(command,check=True,stdout=log,stderr=subprocess.STDOUT)
subprocess.run([sys.executable,str(ROOT/'Tools/build_researcher_actions.py'),'--raw'],check=True)
export()
data=json.loads((art/'actions.json').read_text());hashes={}
for name in ('knockout','unconscious'):
    with (art/(name+'-uncorrected-bounds.csv')).open('w') as out:
        subprocess.run([args.bounds_tool,str(ROOT/'Spine/shujuyuan.atlas'),str(art/'export/actions.skel'),name],check=True,stdout=out)
    hashes[name]=hashlib.sha256(json.dumps(data['animations'][name],sort_keys=True,separators=(',',':')).encode()).hexdigest()
(art/'ground-correction-source.json').write_text(json.dumps(hashes,indent=2)+'\n')
subprocess.run([sys.executable,str(ROOT/'Tools/build_researcher_actions.py')],check=True)
export()
subprocess.run([sys.executable,str(ROOT/'Tools/install_interrogation_runtime.py')],check=True)
print('Exported matching editable project, binary and ground correction samples.')
