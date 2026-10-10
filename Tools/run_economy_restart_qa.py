"""Kill an owned native QA process after durable consumption, then restart it."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime-manifest', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads(args.runtime_manifest.read_text())
    binary = Path(manifest['binary'])
    assert manifest['status'] == 'built' and manifest['luaOptimizationFlags'][-1] == '-O3'
    assert hashlib.sha256(binary.read_bytes()).hexdigest() == manifest['binarySha256']
    assert subprocess.run(['pgrep', '-f', 'Dora[.]app/Contents/MacOS/Dora'], capture_output=True).returncode != 0
    evidence = args.evidence.resolve()
    evidence.mkdir(parents=True, exist_ok=False)
    base = Path(tempfile.mkdtemp(prefix='lsd-economy-restart-', dir='/private/tmp'))
    assets, save = base/'assets', base/'save'
    (assets/'Script').mkdir(parents=True)
    save.mkdir()
    engine = Path(manifest['engine'])
    for name in ['Font', 'Image', 'Shader', 'Audio', 'Doc', 'dora-wa', 'www', 'LICENSES', 'gamecontrollerdb.txt']:
        source = engine/'Assets'/name
        if source.exists():
            (assets/name).symlink_to(source, target_is_directory=source.is_dir())
    (assets/'Script/Lib').symlink_to(engine/'Assets/Script/Lib', target_is_directory=True)
    quote = lambda value: json.dumps(str(value), ensure_ascii=False)
    sources = lambda: {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
                       for p in sorted((root/'Script').rglob('*.lua'))}
    record = {'status': 'RUNNING', 'runtime': manifest, 'workDirectory': str(base), 'sources': sources(), 'phases': []}
    process = None
    try:
        for phase in ['prepare', 'recover']:
            result = evidence/(phase+'.json')
            paths = [root, root/'Script', root/'Spine', root/'Image', root/'Font', engine/'Assets/Script/Lib']
            bootstrap = f'''local D=require('Dora')
D.Content.writablePath={quote(save)}
D.Content.searchPaths={{{','.join(quote(p) for p in paths)}}}
local path={quote(root/'Test/EconomyRestartNative.lua')}
assert(load(D.Content:load(path),'@'..path))({quote(root/'Test/EconomyRestartNative')},{quote(phase)},{quote(save/'restart.db')},{quote(result)})
'''
            (assets/'Script/init.lua').write_text(bootstrap)
            with (evidence/(phase+'.log')).open('w') as log:
                process = subprocess.Popen([str(binary), '--asset', str(assets)], stdout=log, stderr=subprocess.STDOUT)
                deadline = time.monotonic()+60
                while True:
                    data = None
                    if result.exists():
                        try:
                            data = json.loads(result.read_text())
                        except json.JSONDecodeError:
                            pass
                    if data and data['status'] in ('READY', 'PASS', 'FAIL'):
                        break
                    assert process.poll() is None, 'Process exited without result'
                    assert time.monotonic() < deadline, 'QA timeout'
                    time.sleep(.1)
                assert data['status'] == ('READY' if phase == 'prepare' else 'PASS'), data
                if phase == 'prepare':
                    assert process.poll() is None
                    process.kill()
                code = process.wait(timeout=10)
                assert code == (-9 if phase == 'prepare' else 0), code
                record['phases'].append({'phase': phase, 'pid': process.pid, 'exit': code, 'result': data})
                process = None
        assert record['sources'] == sources(), 'Source changed during QA'
        assert record['phases'][0]['pid'] != record['phases'][1]['pid']
        record['status'] = 'PASS'
    except Exception as error:
        record.update(status='FAIL', error=str(error))
        raise
    finally:
        if process and process.poll() is None:
            process.kill()
            process.wait(timeout=10)
        (evidence/'run.json').write_text(json.dumps(record, ensure_ascii=False, indent=2))
    print(json.dumps({'status': 'PASS', 'evidence': str(evidence)}))


if __name__ == '__main__':
    main()
