#!/usr/bin/env python3
"""Exercise the real Qt window and F2 generation in an isolated state directory."""
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'build/qt-ui-check'
ENV = os.environ.copy()
ENV['DISPLAY'] = os.environ.get('OBSIDIAN_TEST_DISPLAY', ':96')
ENV['QT_QUICK_BACKEND'] = 'software'


def command(*args):
    return subprocess.check_output(args, env=ENV, text=True, stderr=subprocess.DEVNULL).strip()


def wait_for(predicate, message, timeout=30):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            result = predicate()
            if result:
                return result
        except subprocess.CalledProcessError:
            pass
        time.sleep(.15)
    raise RuntimeError(message)


def main():
    os.chdir(ROOT)
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT / 'xvfb.log').open('w') as log:
        display = subprocess.Popen(['Xvfb', ENV['DISPLAY'], '-screen', '0', '1600x1000x24', '-nolisten', 'tcp'], env=ENV, stdout=log, stderr=subprocess.STDOUT)
    try:
        wait_for(lambda: command('xdotool', 'getdisplaygeometry'), 'Xvfb did not start')
        for mode in ('dark', 'light'):
            state = OUT / mode
            state.mkdir(exist_ok=True)
            results = state / 'results'
            (state / 'interface.ini').write_text('[General]\ndark=' + ('true' if mode == 'dark' else 'false') + '\noutput=' + str(results) + '\n')
            # A fixed seed makes this a reproducible UI test, not a user's session.
            (state / 'CONFIG.txt').write_text('engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n')
            with (state / 'launch.log').open('w') as log:
                app = subprocess.Popen(['./obsidian', '--state-dir', str(state)], env=ENV, stdout=log, stderr=subprocess.STDOUT)
            try:
                window = wait_for(lambda: command('xdotool', 'search', '--onlyvisible', '--name', 'Obsidian Extended').splitlines()[0], 'Qt window did not open')
                command('xdotool', 'windowmove', window, '0', '0')
                command('xdotool', 'windowfocus', window)
                time.sleep(1)
                prior = set(results.glob('Obsidian-*'))
                command('xdotool', 'key', 'F2')
                folder = wait_for(lambda: next(iter(set(results.glob('Obsidian-*')) - prior), None), 'F2 did not produce a completed result', timeout=90)
                data = (folder / 'level.wad').read_bytes()
                assert data.startswith(b'PWAD'), folder
                time.sleep(.2)
                command('import', '-window', window, str(OUT / f'qt-{mode}.png'))
                command('xdotool', 'key', 'ctrl+f')
                command('xdotool', 'type', 'zzzz-no-option')
                time.sleep(.2)
                command('import', '-window', window, str(state / 'search.png'))
                command('xdotool', 'key', 'ctrl+a', 'BackSpace')
                time.sleep(.25)  # Let delegates rebuild before re-focusing the search field.
                command('xdotool', 'key', 'ctrl+f')
                command('xdotool', 'type', '--clearmodifiers', '--delay', '30', 'float_mons')
                command('xdotool', 'mousemove', '--window', window, '40', '25')
                time.sleep(2)  # Initial broad matches create many delegates; wait for the final painted frame.
                command('import', '-window', window, str(OUT / f'qt-{mode}-gameplay.png'))
                # The controlled 1440x900 test window has the first gameplay thumbnail here.
                command('xdotool', 'mousemove', '--window', window, '1264', '390')
                command('xdotool', 'click', '1')
                time.sleep(.3)
                command('import', '-window', window, str(OUT / f'qt-{mode}-comparison.png'))
                command('xdotool', 'key', 'Escape')
                time.sleep(.3)
                command('xdotool', 'windowsize', window, '1050', '760')
                command('xdotool', 'key', 'alt+4')
                time.sleep(.2)
                command('import', '-window', window, str(OUT / f'qt-{mode}-compact.png'))
                command('xdotool', 'windowsize', window, '1050', '600')
                command('xdotool', 'key', 'alt+1')
                time.sleep(.2)
                command('import', '-window', window, str(OUT / f'qt-{mode}-small.png'))
                command('xdotool', 'key', 'ctrl+f')
                command('xdotool', 'type', '--clearmodifiers', '--delay', '30', 'float_mons')
                command('xdotool', 'mousemove', '--window', window, '40', '25')
                time.sleep(2)
                command('xdotool', 'key', 'ctrl+i')
                time.sleep(.3)
                command('import', '-window', window, str(state / 'inspector-dialog.png'))
                command('xdotool', 'key', 'Escape')
                time.sleep(.3)
                command('xdotool', 'key', 'ctrl+g')
                time.sleep(.2)
                command('import', '-window', window, str(state / 'game-dialog.png'))
                command('xdotool', 'key', 'Escape')
                time.sleep(.3)  # Wait for the native popup's close transition.
                command('xdotool', 'key', 'ctrl+q')
                app.wait(timeout=10)
                assert app.returncode == 0
                diagnostics = (state / 'launch.log').read_text()
                for error in ('Binding loop', 'ReferenceError', 'TypeError', 'Cannot assign', 'is not a function', 'failed to load component'):
                    assert error not in diagnostics, diagnostics
                saved = (state / 'CONFIG.txt').read_text()
                assert 'seed = 12345' in saved and 'port = boom' in saved
                print(f'{mode}: F2, WAD output, search, resize, preview navigation and clean exit passed', flush=True)
            finally:
                if app.poll() is None:
                    app.terminate()
                    app.wait(timeout=10)
    finally:
        display.terminate()
        display.wait(timeout=10)


if __name__ == '__main__':
    main()
