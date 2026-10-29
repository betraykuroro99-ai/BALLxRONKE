"""Run native checks with an installed Godot 4 editor. No dependencies needed."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default=os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4'))
args = parser.parse_args()
if not args.godot:
    parser.error('Pass --godot /path/to/Godot or set GODOT_BIN to the editor executable.')

def run(label, flags, user_args=(), *, project=True, cwd=None):
    command = [args.godot, '--headless']
    if project:
        command += ['--path', str(ROOT)]
    command += flags
    if user_args:
        command += ['--', *user_args]
    result = subprocess.run(command, capture_output=True, text=True, timeout=240, cwd=cwd)
    output = result.stdout + '\n' + result.stderr
    print(f'\n--- {label} ---\n{output}')
    if result.returncode or any(marker in output for marker in ['SCRIPT ERROR', 'Parse Error', 'Failed to load script', 'FAIL:']):
        raise SystemExit(f'{label} failed (exit {result.returncode}).')
    return output

version = subprocess.run([args.godot, '--version'], capture_output=True, text=True, check=True).stdout.strip()
print('Godot editor:', version)
if not version.startswith('4.'):
    raise SystemExit('This project requires Godot 4.')
run('Import', ['--editor', '--import', '--quit'])
run('Native engine tests', ['--script', 'res://tests/engine_test.gd'])
run('Native UI/input/layout tests', ['--script', 'res://tests/ui_test.gd'])
run('Mobile UI/input/layout tests', ['--script', 'res://tests/ui_test.gd'], ['--mobile-ui'])
with tempfile.TemporaryDirectory(prefix='ballxronke-pack-') as temp:
    pack = Path(temp) / 'BALLxRONKE.pck'
    run('Export resource pack', ['--export-pack', 'Linux', str(pack)])
    if not pack.is_file() or pack.stat().st_size < 100000:
        raise SystemExit('Resource pack was not created.')
    # Run in an empty directory with no --path fallback to source assets.
    output = run('Packaged assets', ['--main-pack', str(pack), '--quit-after', '120'], ['--verify-pack', '--qa-profile'], project=False, cwd=temp)
    if 'PASS: all packaged crew resources' not in output:
        raise SystemExit('Packaged asset verification did not execute.')
    output = run('Run packaged game', ['--main-pack', str(pack), '--quit-after', '90'], ['--start-run', '--qa-profile'], project=False, cwd=temp)
    if 'SMOKE: native run started' not in output:
        raise SystemExit('Packaged game did not enter a run.')
print('\nPASS: native simulation, UI, input, layouts, resource pack, and packaged startup.')
print('Device testing and Windows/Android binary export require the matching export templates and platform SDKs.')
