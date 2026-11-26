#!/usr/bin/env python3
"""Validate the signed AAB using Google's bundletool and inspect ELF alignment."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('bundle', type=Path)
parser.add_argument('--bundletool', required=True, type=Path)
args = parser.parse_args()
java_dir = Path(os.environ['JAVA_HOME']) / 'bin' if os.environ.get('JAVA_HOME') else Path('/usr/bin')
def run(*command):
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout

def bundletool(*command):
    return run(str(java_dir / 'java'), '-Xmx256m', '-jar', str(args.bundletool), *command, '--bundle=' + str(args.bundle.resolve()))

validation = bundletool('validate')
manifest = bundletool('dump', 'manifest')
config = bundletool('dump', 'config')
assert 'package="br.com.sumula.sumula_app"' in manifest, 'Unexpected package'
assert 'android:targetSdkVersion="36"' in manifest, 'Target SDK must be 36'
assert 'android:minSdkVersion="24"' in manifest, 'Minimum SDK must be 24'
assert 'android:debuggable="true"' not in manifest, 'Debug build is not allowed'
assert 'android:usesCleartextTraffic="false"' in manifest, 'HTTPS required'
assert 'com.android.vending.BILLING' in manifest, 'Google Play Billing missing'
assert 'PAGE_ALIGNMENT_16K' in config, '16 KB bundle alignment missing'
signature = run(str(java_dir / 'jarsigner'), '-verify', str(args.bundle.resolve()))
assert 'jar verified.' in signature, 'Signature verification failed'
native = []
with zipfile.ZipFile(args.bundle) as archive:
    for name in archive.namelist():
        if not name.endswith('.so') or not any('/' + abi + '/' in name for abi in ('arm64-v8a', 'x86_64')):
            continue
        data = archive.read(name)
        assert data[:4] == b'\x7fELF' and data[4] == 2, 'Invalid 64-bit ELF'
        endian = '<' if data[5] == 1 else '>'
        phoff = struct.unpack_from(endian + 'Q', data, 32)[0]
        entsize, count = struct.unpack_from(endian + 'HH', data, 54)
        alignments = []
        for i in range(count):
            pos = phoff + i * entsize
            if struct.unpack_from(endian + 'I', data, pos)[0] == 1:
                alignment = struct.unpack_from(endian + 'Q', data, pos + 48)[0]
                assert alignment >= 16384, 'Unsupported ELF alignment: ' + name
                alignments.append(alignment)
        assert alignments, 'ELF has no loadable segments'
        native.append({'file': name, 'loadSegmentAlignment': alignments})
assert native, 'Native Flutter libraries not found'
report = {'bundle': args.bundle.name, 'sha256': hashlib.sha256(args.bundle.read_bytes()).hexdigest(),
          'package': 'br.com.sumula.sumula_app', 'targetSdk': 36, 'minSdk': 24,
          'signed': True, 'bundletoolValid': True, 'zipAlignment16k': True,
          'nativeLibraries': native, 'deviceTests': 'pending', 'licensedPlayPurchases': 'pending'}
args.bundle.with_name('validacao-android.json').write_text(json.dumps(report, indent=2) + '\n')
args.bundle.with_name('AndroidManifest.validado.xml').write_text(manifest)
print(json.dumps(report, indent=2))
