"""Check the exported APK's ZIP structure and bundled ARM runtime."""
import argparse
from pathlib import Path
import zipfile
import re
from struct import unpack_from

parser = argparse.ArgumentParser()
parser.add_argument('apk', type=Path)
parser.add_argument("--badging", type=Path)
parser.add_argument("--permissions", type=Path)
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
    arm64 = apk.read('lib/arm64-v8a/libgodot_android.so')
    if arm64[:6] != b'\x7fELF\x02\x01':
        raise SystemExit('ARM64 library is not a little-endian ELF64 binary')
    phoff = unpack_from('<Q', arm64, 32)[0]
    phsize, phcount = unpack_from('<HH', arm64, 54)
    alignments = [unpack_from('<Q', arm64, phoff + i * phsize + 48)[0]
                  for i in range(phcount)
                  if unpack_from('<I', arm64, phoff + i * phsize)[0] == 1]
    if not alignments or any(alignment < 16384 for alignment in alignments):
        raise SystemExit('ARM64 load segments are not aligned for 16 KB pages')
    print('PASS: ARM64 ELF load segments support 16 KB page alignment')
    if any(name.startswith('lib/x86') for name in names):
        raise SystemExit('Unexpected desktop/emulator architecture in phone APK')
print(f'PASS: APK ZIP, manifest, DEX, game assets and both ARM runtimes ({args.apk.stat().st_size:,} bytes)')

if args.badging:
    badging = args.badging.read_text()
    if "package: name='com.betraykuroro99.ballxronke'" not in badging:
        raise SystemExit('Unexpected Android package identifier')
    if "launchable-activity:" not in badging:
        raise SystemExit('APK does not declare a launcher activity')
    sdk = re.search(r"sdkVersion:'(\d+)'", badging)
    if not sdk:
        raise SystemExit('APK minimum Android SDK is missing')
    print(f"PASS: package name, launcher activity and minimum SDK {sdk.group(1)}")
if args.permissions:
    permissions = args.permissions.read_text()
    if 'android.permission.INTERNET' in permissions or 'android.permission.ACCESS_NETWORK_STATE' in permissions:
        raise SystemExit('Unexpected Android network permission')
    print('PASS: APK requests no Internet/network-state permission')
