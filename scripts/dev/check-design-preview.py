#!/usr/bin/env python3
"""Exercise the Finder-inspired sample in an actual X11 window with isolated state.

Pass --motion to additionally record real transitions with ffmpeg; normal CI does
not require video tools. State assertions for keyboard/motion live in QtTest.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import time

from xvfb_session import XvfbSession, wait_for

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'build/design-preview-check'
ENV = os.environ.copy()
ENV['QT_QUICK_BACKEND'] = 'software'

def command(*args, env=ENV):
    return subprocess.check_output(args, env=env, text=True, stderr=subprocess.DEVNULL).strip()


def keys(*sequence, env=ENV):
    command('xdotool', 'key', *sequence, env=env)

def capture(window, path, env=ENV):
    # Keep the pointer outside the app: neither tooltips nor hover become part
    # of the documentation screenshot.
    command('xdotool', 'mousemove', '1760', '1180', env=env)
    command('import', '-window', window, str(path), env=env)
    logfile = (OUT / path.stem / 'launch.log') if path.parent == OUT else (path.parent / 'launch.log')
    if logfile.exists():
        diagnostics = logfile.read_text()
        assert 'QML' not in diagnostics, str(path) + ': ' + diagnostics

def motion_clip(window, path, action, env=ENV):
    geometry = dict(line.split('=', 1) for line in command('xdotool', 'getwindowgeometry', '--shell', window, env=env).splitlines())
    size = geometry['WIDTH'] + 'x' + geometry['HEIGHT']
    screen = env['DISPLAY'] + '+' + geometry['X'] + ',' + geometry['Y']
    with path.with_suffix('.log').open('w') as log:
        recorder = subprocess.Popen(['ffmpeg', '-y', '-nostdin', '-loglevel', 'error',
            '-f', 'x11grab', '-draw_mouse', '0', '-framerate', '30', '-video_size', size,
            '-i', screen, '-t', '1.8', '-c:v', 'libx264', '-threads', '2', '-preset', 'ultrafast',
            '-crf', '18', '-pix_fmt', 'yuv420p', str(path)], env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            time.sleep(.4)
            action()
            assert recorder.wait(timeout=15) == 0, path.with_suffix('.log').read_text()
        finally:
            if recorder.poll() is None:
                recorder.terminate()
                recorder.wait(timeout=5)
    assert path.stat().st_size > 1000
    subprocess.run(['ffmpeg', '-y', '-nostdin', '-loglevel', 'error', '-i', str(path),
        '-filter_complex', 'fps=15,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse',
        '-filter_complex_threads', '1', '-threads', '2', '-loop', '0', str(path.with_suffix('.gif'))], env=env, check=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--motion', action='store_true', help='Save real transition MP4/GIF clips (requires ffmpeg).')
    parser.add_argument('--modes', nargs='+', choices=['light', 'dark', 'hidpi'], default=['light', 'dark', 'hidpi'])
    args = parser.parse_args()
    if args.motion and not shutil.which('ffmpeg'):
        parser.error('--motion needs ffmpeg')
    os.chdir(ROOT)
    OUT.mkdir(parents=True, exist_ok=True)
    with XvfbSession(OUT / 'xvfb.log', '1800x1200x24', ENV, os.environ.get('OBSIDIAN_PREVIEW_DISPLAY')) as display:
        ENV['DISPLAY'] = display.name
        for mode in args.modes:
            state = OUT / mode
            state.mkdir(exist_ok=True)
            results = state / 'results'
            (state / 'interface.ini').write_text('[General]\ndark=' + ('true' if mode == 'dark' else 'false') + '\noutput=' + str(results) + '\n')
            (state / 'CONFIG.txt').write_text('engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n')
            env = ENV.copy()
            if mode == 'hidpi':
                env['QT_SCALE_FACTOR'] = '1.5'
            with (state / 'launch.log').open('w') as log:
                app = subprocess.Popen(['./obsidian', '--design-preview', '--state-dir', str(state)], env=env, stdout=log, stderr=subprocess.STDOUT)
            try:
                processes = ((display.process, OUT / 'xvfb.log'), (app, state / 'launch.log'))
                window = wait_for(lambda: command('xdotool', 'search', '--onlyvisible', '--name', 'Design Preview', env=env).splitlines()[0], f'Preview failed; see {state}/launch.log', processes=processes)
                command('xdotool', 'windowmove', window, '0', '0', env=env)
                command('xdotool', 'windowfocus', window, env=env)
                time.sleep(1)
                prior = set(results.glob('Obsidian-*'))
                keys('F2', env=env)
                folder = wait_for(lambda: next(iter(set(results.glob('Obsidian-*')) - prior), None), 'Preview F2 did not finish', timeout=90, processes=processes)
                assert (folder / 'level.wad').read_bytes().startswith(b'PWAD')
                keys('alt+3', 'ctrl+1', env=env)
                time.sleep(.7)
                capture(window, OUT / f'{mode}.png', env)
                keys('Right', env=env)
                time.sleep(.3)
                capture(window, state / 'resource-health.png', env)
                keys('Left', 'ctrl+2', env=env)
                time.sleep(.4)
                capture(window, state / 'resource-list.png', env)
                keys('ctrl+1', env=env)
                time.sleep(.3)
                if args.motion and mode == 'light':
                    keys('alt+1', env=env)
                    time.sleep(.6)
                    motion_clip(window, state / 'navigation-motion.mp4', lambda: keys('alt+3', env=env), env)
                    motion_clip(window, state / 'inspector-motion.mp4', lambda: keys('ctrl+i', env=env), env)
                    keys('ctrl+i', env=env)
                    time.sleep(.5)
                    motion_clip(window, state / 'sidebar-motion.mp4', lambda: keys('ctrl+shift+b', env=env), env)
                    keys('ctrl+shift+b', 'ctrl+shift+m', 'alt+1', env=env)
                    time.sleep(.5)
                    motion_clip(window, state / 'reduced-motion.mp4', lambda: keys('alt+3', env=env), env)
                    keys('ctrl+shift+m', env=env)
                    time.sleep(.5)
                keys('alt+4', env=env)
                time.sleep(.6)
                capture(window, state / 'result.png', env)
                keys('alt+2', 'ctrl+f', env=env)
                command('xdotool', 'type', 'float_mons', env=env)
                time.sleep(.6)
                capture(window, state / 'matched-search.png', env)
                keys('ctrl+a', env=env)
                command('xdotool', 'type', 'zzzz-no-match', env=env)
                time.sleep(.3)
                capture(window, state / 'search.png', env)
                keys('ctrl+a', 'BackSpace', 'alt+3', env=env)
                time.sleep(.6)
                if mode != 'hidpi':
                    keys('ctrl+plus', env=env)
                    time.sleep(.5)
                    capture(window, state / 'large-text.png', env)
                    keys('ctrl+0', env=env)
                    command('xdotool', 'windowsize', window, '900', '540', env=env)
                    time.sleep(.6)
                    capture(window, state / 'minimum.png', env)
                    keys('ctrl+2', 'alt+3', 'Down', 'Down', 'Down', 'Down', 'Down', env=env)
                    time.sleep(.6)
                    capture(window, state / 'minimum-list-last.png', env)
                    command('xdotool', 'windowsize', window, '1050', '640', env=env)
                    keys('ctrl+1', 'alt+3', env=env)
                    time.sleep(.6)
                keys('Return', env=env)
                time.sleep(.4)
                capture(window, state / 'inspector.png', env)
                keys('Escape', env=env)
                time.sleep(.3)
                keys('ctrl+g', env=env)
                time.sleep(.2)
                keys('Escape', env=env)
                time.sleep(.3)
                keys('Tab', 'Tab', 'ctrl+q', env=env)
                app.wait(timeout=10)
                assert app.returncode == 0
                diagnostics = (state / 'launch.log').read_text()
                for error in ('Binding loop', 'ReferenceError', 'TypeError', 'Cannot assign', 'Unable to assign', 'is not a function', 'failed to load component', 'Too many arguments', 'QML'):
                    assert error not in diagnostics, diagnostics
                config = (state / 'CONFIG.txt').read_text()
                assert 'seed = 12345' in config and 'port = boom' in config
                print(f'{mode}: WAD generation, Freedoom gallery, keyboard selection, grid/list, search, resize and dialogs passed', flush=True)
            finally:
                if app.poll() is None:
                    app.terminate()
                    app.wait(timeout=10)


if __name__ == '__main__':
    main()
