#!/usr/bin/env python3
"""Builds and VERIFIES an AddOns zip (pattern from GoldIntel tools/build_package.py).

Checks every file the TOC names exists, every shipped file is ASCII with LF endings, and nothing outside
the addon folder is packaged.
Usage (from the repository root):
  python3 tools/build_package.py                -> dist/EmpireIntelCheck_AddOns.zip   (the check package)
  python3 tools/build_package.py EmpireIntel    -> dist/EmpireIntel_AddOns_v<version>.zip (versioned)
"""
import hashlib, os, sys, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = sys.argv[1] if len(sys.argv) > 1 else 'EmpireIntelCheck'

def fail(msg):
    print('PACKAGE ERROR:', msg)
    sys.exit(1)

def main():
    folder = os.path.join(ROOT, ADDON)
    toc = os.path.join(folder, ADDON + '.toc')
    files = []
    for line in open(toc, encoding='ascii').read().splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            if '\\' in line:
                fail('backslash in TOC path: ' + line)
            files.append(line)
    shipped = [ADDON + '.toc', 'README.txt'] + files
    for rel in shipped:
        path = os.path.join(folder, rel)
        if not os.path.isfile(path):
            fail('missing file named by the TOC: ' + rel)
        data = open(path, 'rb').read()
        if any(b > 127 for b in data):
            fail('non-ASCII byte in ' + rel)
        if b'\r' in data:
            fail('CR line ending in ' + rel)
    version = None
    for line in open(toc, encoding='ascii').read().splitlines():
        if line.startswith('## Version:'):
            version = line.split(':', 1)[1].strip()
    os.makedirs(os.path.join(ROOT, 'dist'), exist_ok=True)
    name = ADDON + '_AddOns.zip' if ADDON == 'EmpireIntelCheck' else ADDON + '_AddOns_v' + str(version) + '.zip'
    out = os.path.join(ROOT, 'dist', name)
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        for rel in shipped:
            z.write(os.path.join(folder, rel), ADDON + '/' + rel)
    with zipfile.ZipFile(out) as z:
        names = z.namelist()
        if sorted(names) != sorted(ADDON + '/' + r for r in shipped):
            fail('zip content differs from the file list')
        for n in names:
            src = open(os.path.join(folder, n.split('/', 1)[1]), 'rb').read()
            if z.read(n) != src:
                fail('zip copy differs for ' + n)
    digest = hashlib.sha256(open(out, 'rb').read()).hexdigest()[:16]
    print('built', os.path.relpath(out, ROOT), 'version', version, len(names), 'files, sha256', digest)
    for n in sorted(names):
        print('  ', n)

if __name__ == '__main__':
    main()
