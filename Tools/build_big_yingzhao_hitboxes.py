"""Derive animated body regions from the current runtime export, retaining original art."""
import json, subprocess, hashlib, shutil
from pathlib import Path
root=Path(__file__).resolve().parents[1];base=root/'Docs/artwork/big-yingzhao-hitboxes'
d=json.loads((base/'source-export/dayingzhao.json').read_text());assert len(d['skins'])==1
attachments=d['skins'][0]['attachments'];slots={s['name']:s for s in d['slots']}
regions={'lian':'head','bozhi':'torso','qugan':'torso','masheng':'flank','kuajiabei':'flank','kuajiaqian':'flank','kuajiashang':'flank'}
for slot in attachments:
 if slot.startswith(('shangbi','xiaobi','qiajnbishouzhang','shouzhi','muzhi')):regions[slot]='arms'
 elif slot.startswith(('qiandatui','qianguanjie','qianxiaotui','qiantizi','qiantizhi','qianjiaogen','qianhougen','qianqigai','qianqiyou','qianxigai')) and 'deng'not in slot:regions[slot]='forelegs'
 elif slot.startswith(('houdatui','houguanjie','houxiaotui','houtizi','houtizhi')) and 'deng'not in slot:regions[slot]='hindlegs'
# The sole deform track is the eye white on death, outside our body hulls.
for animation in d['animations'].values():
 for skin,per_slot in animation.get('attachments',{}).items():assert not set(per_slot).intersection(regions),'Mapped deform needs explicit transfer'
 assert not animation.get('deform')
priorities={'head':60,'arms':40,'forelegs':30,'hindlegs':30,'torso':20,'flank':10}
bases={};manifest=[]
for slot,part in regions.items():
 mesh=attachments[slot][slot];assert mesh['type']=='mesh';v=mesh['vertices'];offset=0;vertices=[]
 for index in range(mesh['hull']):
  if len(v)==len(mesh['uvs']):influences=[(slots[slot]['bone'],v[2*index],v[2*index+1],1)]
  else:
   count=int(v[offset]);offset+=1;influences=[]
   for _ in range(count):
    bone,x,y,weight=v[offset:offset+4];offset+=4;influences.append((d['bones'][int(bone)]['name'],x,y,weight))
  refs=[]
  for bone,x,y,weight in influences:
   if bone not in bases:
    name=f'armor-basis-{len(bases)}';bases[bone]=name;d['slots'].append({'name':name,'bone':bone,'attachment':name+'-o'})
    attachments[name]={name+'-'+suffix:{'type':'point','x':px,'y':py}for suffix,px,py in [('o',0,0),('x',1024,0),('y',0,1024)]}
   refs.append({'basis':bases[bone],'basisSlot':bases[bone],'x':x,'y':y,'weight':weight})
  vertices.append(refs)
 manifest.append({'id':part,'sourceSlot':slot,'geometryId':slot,'priority':priorities[part],'vertices':vertices})
(base/'dayingzhao-hitboxes.json').write_text(json.dumps(d,ensure_ascii=False));(base/'regions.json').write_text(json.dumps(manifest))
lines=['struct Ref {const char* slot;float weight,x,y;};','struct Part {const char* slot;std::vector<std::vector<Ref>> vertices;};','std::vector<Part> parts={']
for p in manifest:
 lines.append('{"'+p['sourceSlot']+'",{')
 for refs in p['vertices']:lines.append('{'+','.join('{"%s",%sf,%sf,%sf}'%(r['basis'],repr(float(r['weight'])),repr(float(r['x'])),repr(float(r['y'])))for r in refs)+'},')
 lines.append('}},')
lines.append('};');(base/'probe-manifest.h').write_text('\n'.join(lines))
editor='/Applications/Spine.app/Contents/MacOS/Spine'
for label,args in [('import-derived',['-i',str(base/'dayingzhao-hitboxes.json'),'-o',str(base/'dayingzhao-hitboxes.spine'),'--replace','-r']),('export-derived',['-i',str(base/'dayingzhao-hitboxes.spine'),'-o',str(base/'export'),'-e','binary'])]:
 with (base/(label+'.log')).open('w')as log:subprocess.run([editor]+args,check=True,stdout=log,stderr=subprocess.STDOUT,timeout=120)
shutil.copyfile(base/'export/dayingzhao-hitboxes.skel',root/'Spine/dayingzhao-hitboxes.skel');shutil.copyfile(base/'regions.json',root/'Data/Combat/big-yingzhao-regions.json')
report={'status':'candidate-awaiting-parity','sourceSha256':hashlib.sha256((root/'Spine/dayingzhao.skel').read_bytes()).hexdigest(),'derivedSha256':hashlib.sha256((root/'Spine/dayingzhao-hitboxes.skel').read_bytes()).hexdigest(),'meshPieces':len(manifest),'parts':sorted(set(regions.values())),'basisSlots':len(bases),'deformExcluded':'yanbai eye white during lose; original track preserved','sourceExportVersion':d['skeleton']['spine']}
(base/'manifest.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
