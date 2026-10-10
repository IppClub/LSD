#!/usr/bin/env python3
"""Compare diagnostic samples without interpreting a stable heap as acceptance."""
from pathlib import Path
import argparse,json
p=argparse.ArgumentParser();p.add_argument('result');p.add_argument('--output',required=True);a=p.parse_args()
source=Path(a.result);report=json.loads(source.read_text());run=report['runId']
rows=sorted((json.loads(x.read_text())for x in source.parent.glob(f'training-memory-diagnostic-{run}-cycle-*.json')),key=lambda x:x['index'])
assert rows and [r['index']for r in rows]==list(range(1,len(rows)+1))
changes=[]
for left,right in zip(rows,rows[1:]):
 old=left['census'];new=right['census'];old_tables={r['key']:r for r in old['registryTables']};new_tables={r['key']:r for r in new['registryTables']}
 changes.append({'from':left['index'],'to':right['index'],'luaDeltaKB':right['luaKB']-left['luaKB'],'modulesAdded':sorted(set(new['modules'])-set(old['modules'])),'modulesRemoved':sorted(set(old['modules'])-set(new['modules'])),'registryChanges':[{ 'key':k,'before':old_tables.get(k),'after':new_tables.get(k)} for k in sorted(old_tables.keys()|new_tables.keys()) if old_tables.get(k)!=new_tables.get(k)]})
result={'runId':run,'fileStatus':report['status'],'liveHandleCheckedByThisTool':False,'completedCycles':len(rows),'elapsed':report['elapsed'],'ranges':{k:[min(r[k]for r in rows),max(r[k]for r in rows)]for k in ('objects','luaRefs','callRefs','retainedArenas','luaKB')},'changes':changes,'acceptance':'REQUIRES_REVIEW','limitations':['Registry census does not expose Lua table capacity or string intern table.','The transient reference observer can affect one cycle heap reading.','This diagnostic does not replace the 30 minute soak, audio review, or actual input testing.']}
Path(a.output).write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items()if k!='changes'},ensure_ascii=False))
