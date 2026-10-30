"""Check the exported APK's ZIP structure and bundled ARM runtime."""
import argparse
from pathlib import Path
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('apk', type=Path)
args = parser.parse_args()
with zipfile.ZipFile(args.apk) as apk:
    if apk.testzip() is not None:
        raise SystemExit('APK ZIP integrity check failed')
    names = set(apk.namelist())
    for required in ['AndroidManifest.xml', 'classes.dex',
                     'lib/arm64-v8a/libgodot_android.so',
                     'lib/armeabi-v7a/libgodot_android.so']:
        if required not in names:
            raise SystemExit(f'APK is missing {required}')
    if not any(name.startswith('assets/') for name in names):
        raise SystemExit('APK is missing bundled game assets')
    if any(name.startswith('lib/x86') for name in names):
        raise SystemExit('Unexpected desktop/emulator architecture in phone APK')
print(f'PASS: APK ZIP, manifest, DEX, game assets and both ARM runtimes ({args.apk.stat().st_size:,} bytes)')
