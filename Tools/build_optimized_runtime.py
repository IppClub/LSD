"""Build a macOS ARM64 QA runtime without changing Dora's source or active config.

Usage: python3 Tools/build_optimized_runtime.py --engine /path/to/Dora-SSR
       --output /private/tmp/lsd-runtime-release

Release mode alone did not add optimization to the Dora target in the inspected
xmake graph. Explicitly request -O3 and verify the Lua VM's actual compile record.
This produces an engine for QA/packaging; it does not open any game save or publish.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--xmake', default=shutil.which('xmake') or '/opt/homebrew/bin/xmake')
    parser.add_argument('--jobs', type=int, default=6)
    args = parser.parse_args()
    engine, output = args.engine.resolve(), args.output.resolve()
    if not (engine / 'Projects/xmake/engine.lua').is_file():
        parser.error('--engine must point to the Dora source checkout')
    if args.jobs < 1:
        parser.error('--jobs must be positive')
    if output == engine or engine in output.parents:
        parser.error('--output must be outside the engine checkout to isolate configuration')
    output.mkdir(parents=True, exist_ok=True)
    current_config = engine / '.xmake/macosx/arm64/xmake.conf'
    original_config = current_config.read_bytes() if current_config.exists() else None
    def git(*arguments):
        return subprocess.check_output(['git', *arguments], cwd=engine)
    metadata = {
        'engine': str(engine), 'directory': str(output),
        'sourceHead': git('rev-parse', 'HEAD').decode().strip(),
        'sourceStatusBefore': git('status', '--porcelain').decode(),
        'sourceDiffSha256': sha(git('diff', 'HEAD', '--binary')),
        'debugConfigSha256': sha(original_config) if original_config is not None else None,
        'optimizationOverride': 'Explicit xmake cxflags=-O3; source remains unchanged',
        'status': 'configuring',
    }
    manifest = output / 'manifest.json'
    def save():
        manifest.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n')
    environment = os.environ.copy()
    environment['XMAKE_CONFIGDIR'] = str(output)
    environment['XMAKE_COLORTERM'] = 'nocolor'
    configure = [args.xmake, 'f', '-y', '-p', 'macosx', '-a', 'arm64', '-m', 'release',
                 '-o', str(output / 'build'), '--cxflags=-O3', '--dora_native_tests=n',
                 '--dora_builtin_libs=y', '--dora_love=y', '--dora_model_3d=y',
                 '--dora_music=y', '--dora_yue=y']
    build = [args.xmake, 'build', '-y', '-j', str(args.jobs), 'Dora']
    metadata['configureArguments'], metadata['buildArguments'] = configure, build
    save()
    try:
        for name, command in [('configure', configure), ('build', build)]:
            metadata['status'] = 'configuring' if name == 'configure' else 'building'
            save()
            with (output / (name + '.log')).open('w') as log:
                subprocess.run(command, cwd=engine, env=environment, stdout=log,
                               stderr=subprocess.STDOUT, check=True)
        dependencies = list((output / 'build/.deps/Dora').rglob('lvm.c.o.d'))
        if len(dependencies) != 1:
            raise RuntimeError('Expected exactly one Lua VM compile record')
        record = dependencies[0].read_text()
        flags = re.findall(r'"(-O[^"\s]*)"', record)
        if '-O3' not in flags or flags[-1] != '-O3':
            raise RuntimeError('Lua VM did not compile with the requested optimization')
        (output / 'lua-compile-evidence.txt').write_text(record)
        binaries = list((output / 'build').glob('**/Dora.app/Contents/MacOS/Dora'))
        if len(binaries) != 1:
            raise RuntimeError('Expected exactly one built Dora application')
        binary = binaries[0]
        metadata.update(binary=str(binary), binarySha256=sha(binary.read_bytes()),
                        luaOptimizationFlags=flags, status='built')
    except Exception as error:
        metadata.update(status='failed', error=str(error))
        raise
    finally:
        now = current_config.read_bytes() if current_config.exists() else None
        metadata['originalConfigUnchanged'] = now == original_config
        metadata['sourceStatusAfter'] = git('status', '--porcelain').decode()
        metadata['sourceDiffUnchanged'] = metadata['sourceDiffSha256'] == sha(git('diff', 'HEAD', '--binary'))
        save()
    if not metadata['originalConfigUnchanged'] or not metadata['sourceDiffUnchanged']:
        metadata.update(status='failed', error='Source or active build configuration changed during the build')
        save()
        raise RuntimeError(metadata['error'] + '; inspect manifest')
    print(json.dumps({'status': metadata['status'], 'binary': metadata['binary'],
                      'manifest': str(manifest)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
