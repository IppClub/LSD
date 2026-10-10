#!/usr/bin/env python3
"""Decode every staged audio stream without playback. This is not an audible mix review."""
from pathlib import Path
import argparse, concurrent.futures, hashlib, json, subprocess
parser=argparse.ArgumentParser();parser.add_argument('stage');parser.add_argument('--report',required=True);args=parser.parse_args()
root=Path(args.stage).resolve()
paths=sorted(p for d in ('Music','Sound') for p in (root/d).rglob('*') if p.suffix.lower() in ('.mp3','.ogg','.wav'))
def audit(path):
    row={'path':path.relative_to(root).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    try:
        probe=subprocess.run(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(path)],capture_output=True,text=True,timeout=30,check=True)
        metadata=json.loads(probe.stdout);streams=[s for s in metadata['streams'] if s['codec_type']=='audio']
        if len(streams)!=1: raise ValueError('Expected exactly one audio stream')
        stream=streams[0];duration=float(metadata['format']['duration'])
        if duration<=0 or int(stream['channels'])<1: raise ValueError('Empty audio')
        decoded=subprocess.run(['ffmpeg','-nostdin','-v','error','-xerror','-i',str(path),'-map','0:a:0','-f','null','-'],capture_output=True,text=True,timeout=120)
        if decoded.returncode or decoded.stderr.strip(): raise ValueError(decoded.stderr or 'Decoder failed')
        row.update(status='PASS',codec=stream['codec_name'],sampleRate=int(stream['sample_rate']),channels=int(stream['channels']),seconds=duration)
    except (ValueError,KeyError,subprocess.SubprocessError) as error: row.update(status='FAIL',error=str(error))
    return row
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool: rows=list(pool.map(audit,paths))
report={'status':'PASS' if rows and all(r['status']=='PASS' for r in rows) else 'FAIL','stage':str(root),'scope':'Full audio file decoding only; playback, gain, loop seam and lifecycle not verified','files':rows}
Path(args.report).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False));raise SystemExit(report['status']!='PASS')
