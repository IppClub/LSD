#!/usr/bin/env python3
"""Summarize existing soak measurements; never infer live status or pass acceptance."""
from pathlib import Path
import argparse,json,statistics
p=argparse.ArgumentParser();p.add_argument('input');p.add_argument('--output',required=True);a=p.parse_args()
r=json.loads(Path(a.input).read_text());rows=r['cycles'];assert rows, 'No completed cycles'
deltas=[{'fromCycle':x['index'],'toCycle':y['index'],'luaKB':y['luaKB']-x['luaKB']} for x,y in zip(rows,rows[1:])]
summary={'runId':r['runId'],'fileStatus':r['status'],'liveStatusVerified':False,'completedCycles':len(rows),'elapsed':r['elapsed'],'requiredSeconds':r['targetSeconds'],'cycleAndTimeThresholdMet':len(rows)>=20 and r['elapsed']>=r['targetSeconds'],'ranges':{k:[min(x[k]for x in rows),max(x[k]for x in rows)]for k in ('objects','luaRefs','callRefs','retainedArenas','luaKB')},'luaDeltaKB':rows[-1]['luaKB']-rows[0]['luaKB'],'medianCycleDeltaKB':statistics.median(x['luaKB']for x in deltas)if deltas else None,'jumpsOver32KB':[x for x in deltas if abs(x['luaKB'])>32],'acceptance':'REQUIRES_REVIEW','limitations':['JSON file is not proof that the runtime is live','Includes test measurement rows and engine/developer runtime overhead','A stable range does not explain retained objects or a heap jump','Audio layering and real device input are outside this measurement']}
Path(a.output).write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n');print(json.dumps(summary,ensure_ascii=False))
