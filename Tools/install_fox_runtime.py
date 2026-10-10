#!/usr/bin/env python3
"""Package the reviewed rig with non-rendering face anchors; no pixel/curve changes."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'Docs/artwork/fox-export/fox-chibi-spine.json').read_text())
# Mouth center (165,348) in the unchanged head atlas; head bind pivot (210,382),
# scale .76, head bone points upward. Second point defines the local face X axis.
for name,x,y in [('mouthCenter',25.84,34.2),('mouthAxis',25.84,24.2)]:
 data['slots'].append({'name':name,'bone':'tou','attachment':name})
 data['skins'][0]['attachments'][name]={name:{'type':'point','x':x,'y':y,'rotation':0}}
(root/'Spine/FoxPrototype/fox-runtime.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
