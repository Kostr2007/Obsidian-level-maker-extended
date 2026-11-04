#!/usr/bin/env python3
"""Exercise the native workspace in Xvfb; inspect its captured screenshots.
Run after the CI batch-generation step creates build/smoke/CONFIG.txt.
Requires Xvfb, xdotool and ImageMagick.
"""
import os,subprocess,time,pathlib,shutil,re
root=pathlib.Path(__file__).resolve().parents[2];os.chdir(root)
base=root/'build/workspace-check';base.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env['DISPLAY']=os.environ.get('OBSIDIAN_TEST_DISPLAY', ':96')
def call(*args):return subprocess.check_output(args,env=env,text=True,stderr=subprocess.DEVNULL).strip()
def run(*args):subprocess.run(args,env=env,check=True)
x=subprocess.Popen(['Xvfb',env['DISPLAY'],'-screen','0','1600x1000x24','-nolisten','tcp'],env=env,stdout=open(base/'xvfb.log','w'),stderr=subprocess.STDOUT)
try:
 for _ in range(30):
  try:call('xdotool','getdisplaygeometry');break
  except subprocess.CalledProcessError:time.sleep(.2)
 expected=dict(re.findall(r'^([a-zA-Z0-9_]+)\s*=\s*(.*)$', (root/'build/smoke/CONFIG.txt').read_text(), re.M))
 d=base/'dark';d.mkdir(exist_ok=True)
 shutil.copy('build/smoke/CONFIG.txt',d/'CONFIG.txt');shutil.copy('theme/material-you-dark.txt',d/'THEME.txt')
 p=subprocess.Popen(['./obsidian','--small','--config',str(d/'CONFIG.txt'),'--options',str(d/'OPTIONS.txt'),'--theme',str(d/'THEME.txt'),'--log',str(d/'LOGS.txt')],env=env,stdout=open(d/'launch.log','w'),stderr=subprocess.STDOUT)
 try:
  for _ in range(30):
   try:wid=call('xdotool','search','--onlyvisible','--name','Obsidian Extended').splitlines()[0];break
   except subprocess.CalledProcessError:
    if p.poll() is not None:raise RuntimeError('application exited')
    time.sleep(.3)
  run('xdotool','windowmove',wid,'0','0');run('xdotool','windowfocus',wid);time.sleep(.5)
  run('import','-window',wid,str(base/'dark.png'))
  run('xdotool','mousemove','65','168','click','1');time.sleep(.3)
  run('import','-window',wid,str(base/'gameplay.png'))
  run('xdotool','key','ctrl+f');run('xdotool','type','zzzz-no-matching-setting');time.sleep(.4)
  run('import','-window',wid,str(base/'empty-search.png'))
  run('xdotool','key','ctrl+a','BackSpace');time.sleep(.2)
  run('xdotool','windowsize',wid,'1000','680');time.sleep(.4)
  run('import','-window',wid,str(base/'compact.png'))
  run('xdotool','mousemove','65','216','click','1');time.sleep(.3)
  run('import','-window',wid,str(base/'preview.png'))
  run('xdotool','key','ctrl+q');p.wait(timeout=10)
  assert p.returncode==0
 finally:
  if p.poll() is None:p.terminate();p.wait(timeout=10)
finally:x.terminate();x.wait(timeout=10)
actual=dict(re.findall(r'^([a-zA-Z0-9_]+)\s*=\s*(.*)$', (d/'CONFIG.txt').read_text(), re.M))
for key in ['engine','game','port','length','theme','float_size']:
 assert actual[key] == expected[key], (key,expected[key],actual[key])
assert 'material_theme = 1' in (d/'THEME.txt').read_text()
print('GUI navigation, search, resize, theme persistence and exit exercised; screenshots:',base)
