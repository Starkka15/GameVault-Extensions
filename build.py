#!/usr/bin/env python3
"""Package every extension and regenerate the catalog GameVault reads.

    python build.py            # all extensions -> out/<id>.zip, index.json
    python build.py Optima     # just one (index.json keeps the others' entries)

Each zip holds one top-level <id>/ folder. Text files are forced to LF and
scripts are marked executable, whatever the working tree looks like on Windows
(GameVault v1.3.0/1.3.1 shipped CRLF scripts and broke). index.json points at
the release asset for each version: tag <id>-v<version>, asset <id>.zip.

Publishing a version = run this, create the GitHub release <id>-v<version> with
out/<id>.zip attached, then commit index.json. GameVault only ever sees what
index.json on main says.
"""
import hashlib
import json
import os
import re
import sys
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
EXT = os.path.join(ROOT, 'extensions')
OUT = os.path.join(ROOT, 'out')
INDEX = os.path.join(ROOT, 'index.json')
REPO = 'Starkka15/GameVault-Extensions'
API = 1  # the extension API this repo targets; GameVault refuses newer ones

TEXT = ('.sh', '.py', '.json', '.conf', '.js', '.rb', '.md', '.txt', '.toml')
EXEC = ('.sh', '.py')
STAMP = (2020, 1, 1, 0, 0, 0)  # fixed, so an unchanged extension zips byte-identically


def fail(msg):
    sys.exit(f'build.py: {msg}')


def load_manifest(ext_id):
    path = os.path.join(EXT, ext_id, 'manifest.json')
    try:
        m = json.load(open(path, encoding='utf-8'))
    except Exception as e:
        fail(f'{path}: {e}')
    for key in ('id', 'name', 'version', 'api', 'description', 'platform'):
        if key not in m:
            fail(f'{path}: missing "{key}"')
    if m['id'] != ext_id:
        fail(f'{path}: id "{m["id"]}" must match its folder "{ext_id}"')
    if not re.fullmatch(r'\d+\.\d+\.\d+', m['version']):
        fail(f'{path}: version must be X.Y.Z')
    if m['api'] > API:
        fail(f'{path}: api {m["api"]} is newer than this repo targets ({API})')
    for need in ('static.json', 'store.sh'):
        if not os.path.isfile(os.path.join(EXT, ext_id, need)):
            fail(f'{ext_id}: no {need}; GameVault would not load it')
    return m


def package(ext_id):
    src = os.path.join(EXT, ext_id)
    os.makedirs(OUT, exist_ok=True)
    dest = os.path.join(OUT, f'{ext_id}.zip')
    entries = []
    for dirpath, dirnames, filenames in os.walk(src):
        dirnames[:] = sorted(d for d in dirnames if d != '__pycache__')
        for f in sorted(filenames):
            if f.endswith('.pyc'):
                continue
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, src).replace(os.sep, '/')
            entries.append((rel, full))
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
        for rel, full in entries:
            data = open(full, 'rb').read()
            if rel.endswith(TEXT):
                data = data.replace(b'\r\n', b'\n')
                if rel.endswith('.sh') and b'\r' in data:
                    fail(f'{ext_id}/{rel}: stray CR')
            info = zipfile.ZipInfo(f'{ext_id}/{rel}', STAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3  # Unix, so the mode bits mean something
            mode = 0o755 if rel.endswith(EXEC) else 0o644
            info.external_attr = (0o100000 | mode) << 16
            z.writestr(info, data)
    # The checks GameVault's installer makes, made here first.
    with zipfile.ZipFile(dest) as z:
        names = z.namelist()
        if any('\\' in n for n in names):
            fail(f'{dest}: backslash in a path')
        if {n.split('/')[0] for n in names} != {ext_id}:
            fail(f'{dest}: more than one top-level folder')
    blob = open(dest, 'rb').read()
    return dest, hashlib.sha256(blob).hexdigest(), len(blob)


def main():
    wanted = sys.argv[1:] or sorted(
        d for d in os.listdir(EXT) if os.path.isdir(os.path.join(EXT, d)))
    index = {'api': API, 'extensions': []}
    if os.path.exists(INDEX) and sys.argv[1:]:
        index = json.load(open(INDEX, encoding='utf-8'))
    by_id = {e['id']: e for e in index['extensions']}
    for ext_id in wanted:
        m = load_manifest(ext_id)
        dest, sha, size = package(ext_id)
        by_id[ext_id] = {
            'id': m['id'],
            'name': m['name'],
            'description': m['description'],
            'version': m['version'],
            'api': m['api'],
            'url': f'https://github.com/{REPO}/releases/download/{ext_id}-v{m["version"]}/{ext_id}.zip',
            'sha256': sha,
            'size': size,
        }
        print(f'{ext_id} {m["version"]}  {size:>9} bytes  {sha[:12]}  {os.path.relpath(dest, ROOT)}')
    index['extensions'] = [by_id[k] for k in sorted(by_id)]
    with open(INDEX, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(index, f, indent=2)
        f.write('\n')
    print(f'index.json: {len(index["extensions"])} extensions')


if __name__ == '__main__':
    main()
