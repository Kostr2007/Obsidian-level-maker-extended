#!/usr/bin/env python3
"""Verify the optional design preview in a real X11 window using isolated state."""
import os
from pathlib import Path
import subprocess
import time

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/design-preview-check'
ENV=os.environ.copy();ENV.update(DISPLAY=':93',QT_QUICK_BACKEND='software')

def command(*args,env=ENV):
    return subprocess.check_output(args,env=env,text=True,stderr=subprocess.DEVNULL).strip()

def wait_for(fn,message,timeout=30):
    deadline=time.monotonic()+timeout
    while time.monotonic()<deadline:
        try:
            result=fn()
            if result:return result
        except (subprocess.CalledProcessError,IndexError):pass
        time.sleep(.15)
    raise RuntimeError(message)

def main():
    os.chdir(ROOT);OUT.mkdir(parents=True,exist_ok=True)
    with (OUT/'xvfb.log').open('w') as log:
        display=subprocess.Popen(['Xvfb',ENV['DISPLAY'],'-screen','0','1800x1200x24','-nolisten','tcp'],env=ENV,stdout=log,stderr=subprocess.STDOUT)
    try:
        wait_for(lambda:command('xdotool','getdisplaygeometry'),'Display did not start')
        for mode in ('light','dark','hidpi'):
            state=OUT/mode;state.mkdir(exist_ok=True);results=state/'results'
            (state/'interface.ini').write_text('[General]\ndark='+('true' if mode=='dark' else 'false')+'\noutput='+str(results)+'\n')
            (state/'CONFIG.txt').write_text('engine = idtech_1\ngame = doom2\nport = boom\nlength = single\nseed = 12345\n@compress_output = 0\n')
            env=ENV.copy()
            if mode=='hidpi':env['QT_SCALE_FACTOR']='1.5'
            with (state/'launch.log').open('w') as log:
                app=subprocess.Popen(['./obsidian','--design-preview','--state-dir',str(state)],env=env,stdout=log,stderr=subprocess.STDOUT)
            try:
                window=wait_for(lambda:command('xdotool','search','--onlyvisible','--name','Design Preview',env=env).splitlines()[0],f'Preview failed; see {state}/launch.log')
                command('xdotool','windowmove',window,'0','0',env=env)
                command('xdotool','windowfocus',window,env=env);time.sleep(1)
                prior=set(results.glob('Obsidian-*'));command('xdotool','key','F2',env=env)
                folder=wait_for(lambda:next(iter(set(results.glob('Obsidian-*'))-prior),None),'Preview F2 did not finish',timeout=90)
                assert (folder/'level.wad').read_bytes().startswith(b'PWAD')
                command('import','-window',window,str(OUT/f'{mode}.png'),env=env)
                command('xdotool','key','alt+4',env=env);time.sleep(.2)
                command('import','-window',window,str(state/'result.png'),env=env)
                command('xdotool','key','alt+2','ctrl+f',env=env)
                command('xdotool','type','float_mons',env=env);time.sleep(.3)
                command('import','-window',window,str(state/'matched-search.png'),env=env)
                command('xdotool','key','ctrl+a',env=env)
                command('xdotool','type','zzzz-no-match',env=env);time.sleep(.2)
                command('import','-window',window,str(state/'search.png'),env=env)
                command('xdotool','key','ctrl+a','BackSpace',env=env)
                if mode!='hidpi':
                    command('xdotool','key','ctrl+plus',env=env);time.sleep(.3)
                    command('import','-window',window,str(state/'large-text.png'),env=env)
                    command('xdotool','key','ctrl+0',env=env)
                    command('xdotool','windowsize',window,'900','540',env=env)
                    time.sleep(.3)
                    command('import','-window',window,str(state/'minimum.png'),env=env)
                    command('xdotool','windowsize',window,'1050','640',env=env)
                command('xdotool','key','ctrl+i',env=env);time.sleep(.3)
                command('import','-window',window,str(state/'inspector.png'),env=env)
                command('xdotool','key','Escape',env=env);time.sleep(.3)
                command('xdotool','key','ctrl+g',env=env);time.sleep(.2)
                command('xdotool','key','Escape',env=env);time.sleep(.3)
                command('xdotool','key','Tab','Tab','ctrl+q',env=env);app.wait(timeout=10)
                assert app.returncode==0
                diagnostics=(state/'launch.log').read_text()
                for error in ('Binding loop','ReferenceError','TypeError','Cannot assign','Unable to assign','is not a function','failed to load component','Too many arguments','QML'):
                    assert error not in diagnostics,diagnostics
                config=(state/'CONFIG.txt').read_text()
                assert 'seed = 12345' in config and 'port = boom' in config
                print(f'{mode}: real generation, results, search, dialogs, keyboard and clean exit passed',flush=True)
            finally:
                if app.poll() is None:app.terminate();app.wait(timeout=10)
    finally:
        display.terminate();display.wait(timeout=10)

if __name__=='__main__':main()
