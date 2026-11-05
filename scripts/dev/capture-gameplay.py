#!/usr/bin/env python3
"""Build controlled UDMF comparisons and capture unedited UZDoom screenshots.
Requires UZDoom, Freedoom2, Xvfb and xdotool; see docs/artwork/gameplay/README.md.
"""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import struct
import subprocess
import time
import zlib

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'docs/artwork/gameplay'
SCENES = ASSETS / 'scenes'
VARIANTS = {'lighting-low': (144, 0, 3), 'lighting-high': (208, 0, 3),
            'steepness-low': (192, 8, 0), 'steepness-high': (192, 24, 0),
            'monsters-low': (192, 0, 3), 'monsters-high': (192, 0, 9)}


def block(kind, **fields):
    def value(v):
        if isinstance(v, str): return json.dumps(v)
        if isinstance(v, bool): return str(v).lower()
        return str(v)
    return kind + ' { ' + ' '.join(k + '=' + value(v) + ';' for k,v in fields.items()) + ' }\n'


def scene(light, step, monsters):
    text = 'namespace="ZDoom";\n'
    vertices, sectors, sides, lines, points, edges = [], [], [], [], {}, {}
    xs = [-384,-288,-256,256,288,384]
    ys = [-256,-128,0,128,256,384,512,640,768]
    for j in range(len(ys)-1):
        for i in range(len(xs)-1):
            # Solid perimeter buttresses, same in all six scenes.
            if i in (0,4) and j in (2,4,6): continue
            floor = max(0,j-2) * step
            sector = len(sectors)
            sectors.append(block('sector',heightfloor=floor,heightceiling=288,
                                 texturefloor='FLOOR4_8' if i==2 else 'FLAT5_4',
                                 textureceiling='CEIL3_5',lightlevel=light))
            # Clockwise: UDMF front sector is to the right of each edge.
            coords=[(xs[i],ys[j]),(xs[i],ys[j+1]),(xs[i+1],ys[j+1]),(xs[i+1],ys[j])]
            ids=[]
            for coord in coords:
                if coord not in points:
                    points[coord]=len(vertices);vertices.append(block('vertex',x=coord[0],y=coord[1]))
                ids.append(points[coord])
            for a,b in zip(ids,ids[1:]+ids[:1]):
                side=len(sides)
                sides.append(block('sidedef',sector=sector,texturemiddle='STARTAN2',texturetop='STARTAN2',texturebottom='STEP1'))
                if (b,a) in edges:
                    line=lines[edges[(b,a)]];line['sideback']=side;line['twosided']=True;line['blocking']=False
                    # Remove middle textures from both faces of a portal.
                    sides[line['sidefront']]=sides[line['sidefront']].replace('texturemiddle="STARTAN2"','texturemiddle="-"')
                    sides[side]=sides[side].replace('texturemiddle="STARTAN2"','texturemiddle="-"')
                else:
                    edges[(a,b)]=len(lines);lines.append(dict(v1=a,v2=b,sidefront=side,blocking=True))
    things=[block('thing',x=0,y=-192,height=0,angle=90,type=1,skill1=True,skill2=True,skill3=True,skill4=True,skill5=True,single=True,coop=True,dm=True)]
    positions=[(-210,128),(0,128),(210,128),(-288,416),(-192,416),(-96,416),(96,416),(192,416),(288,416)]
    for x,y in positions[:monsters]:
        things.append(block('thing',x=x,y=y,height=0,angle=270,type=3004,ambush=True,skill1=True,skill2=True,skill3=True,skill4=True,skill5=True,single=True,coop=True,dm=True))
    return text+''.join(vertices+sectors+sides+[block('linedef',**line) for line in lines]+things)


def wad(text):
    payload=text.encode();offset=12+len(payload)
    lumps=[(12,0,b'MAP01'),(12,len(payload),b'TEXTMAP'),(offset,0,b'ENDMAP')]
    return b'PWAD'+struct.pack('<II',3,offset)+payload+b''.join(struct.pack('<II8s',o,n,name) for o,n,name in lumps)


def build():
    SCENES.mkdir(parents=True,exist_ok=True)
    for name,values in VARIANTS.items():
        source=scene(*values)
        (SCENES/(name+'.udmf')).write_text(source)
        (SCENES/(name+'.wad')).write_bytes(wad(source))
    # One factor per pair, verified from the complete source rather than screenshots.
    for prefix,field in [('lighting','lightlevel'),('steepness','heightfloor')]:
        low=(SCENES/(prefix+'-low.udmf')).read_text();high=(SCENES/(prefix+'-high.udmf')).read_text()
        assert re.sub(field+r'=\d+',field+'=X',low)==re.sub(field+r'=\d+',field+'=X',high)
    low=(SCENES/'monsters-low.udmf').read_text();high=(SCENES/'monsters-high.udmf').read_text()
    assert low.split('thing {')[0]==high.split('thing {')[0]
    assert high.startswith(low) # Same player + first 3 guards; only 6 guards added.


def png_dimensions(path):
    data=path.read_bytes()
    assert data[:8]==b'\x89PNG\r\n\x1a\n',path
    offset=8; dimensions=None; ended=False
    while offset<len(data):
        size=struct.unpack('>I',data[offset:offset+4])[0]
        kind=data[offset+4:offset+8];payload=data[offset+8:offset+8+size]
        checksum=struct.unpack('>I',data[offset+8+size:offset+12+size])[0]
        assert zlib.crc32(kind+payload)&0xffffffff==checksum,path
        if kind==b'IHDR':dimensions=struct.unpack('>II',payload[:8])
        offset+=size+12
        if kind==b'IEND':ended=True;break
    assert ended and offset==len(data) and dimensions==(1280,720),path
    return dimensions


def verify_assets():
    manifest=json.loads((ASSETS/'manifest.json').read_text())
    assert set(manifest['images'])==set(VARIANTS)
    for name,values in VARIANTS.items():
        image=ASSETS/(name+'.png');record=manifest['images'][name]
        png_dimensions(image)
        assert hashlib.sha256(image.read_bytes()).hexdigest()==record['sha256'],name
        assert hashlib.sha256((SCENES/(name+'.wad')).read_bytes()).hexdigest()==record['scene_sha256'],name
        assert (record['light'],record['step'],record['guards'])==values,name
    print('Six PNGs: dimensions, CRC, hashes and controlled scene pairs verified.')


def wait_for(predicate, timeout=30):
    deadline=time.monotonic()+timeout
    while time.monotonic()<deadline:
        result=predicate()
        if result:return result
        time.sleep(.15)
    raise RuntimeError('Timed out waiting for game/capture')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-only',action='store_true')
    parser.add_argument('--verify-assets',action='store_true')
    parser.add_argument('--uzdoom',default=shutil.which('uzdoom'))
    parser.add_argument('--iwad',type=Path)
    parser.add_argument('--display',default=':94')
    parser.add_argument('--only',choices=VARIANTS)
    args=parser.parse_args();build()
    if args.verify_assets:
        verify_assets();return
    if args.build_only:return
    if not args.uzdoom or not args.iwad:parser.error('--uzdoom and --iwad are required for capture')
    work=ROOT/'build/gameplay-capture';work.mkdir(parents=True,exist_ok=True)
    runtime=work/'runtime';runtime.mkdir(exist_ok=True);runtime.chmod(0o700)
    env=os.environ.copy();env.update(DISPLAY=args.display,XDG_RUNTIME_DIR=str(runtime),LIBGL_ALWAYS_SOFTWARE='1')
    server=subprocess.Popen(['Xvfb',args.display,'-screen','0','1280x720x24','-nolisten','tcp'],env=env,stdout=(work/'xvfb.log').open('w'),stderr=subprocess.STDOUT)
    report={}
    try:
        wait_for(lambda: subprocess.run(['xdotool','getdisplaygeometry'],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0)
        for name in ([args.only] if args.only else VARIANTS):
            output=work/name
            output.mkdir(exist_ok=True)
            for p in output.glob('*.png'):p.unlink()
            config=output/'uzdoom.ini'
            config.write_text('[GlobalSettings]\nvid_fullscreen=false\nwin_w=1280\nwin_h=720\nvid_defwidth=1280\nvid_defheight=720\nvid_preferbackend=0\nvid_rendermode=0\nvid_aspect=0\n')
            logfile=output/'engine.log'
            command=[args.uzdoom,'-iwad',str(args.iwad.resolve()),'-file',str(SCENES/(name+'.wad')),
                     '-config',str(config),'-nosound','-nomusic','-window','-width','1280','-height','720',
                     '-rngseed','12345','+vid_preferbackend','0','+vid_rendermode','0','+vid_aspect','0',
                     '+screenblocks','12','+crosshair','0',
                     '+r_drawplayersprites','0','+con_notifytime','0','+screenshot_dir',str(output),
                     '+bind','F12','screenshot','+map','map01','+freeze']
            with logfile.open('w') as log:
                game=subprocess.Popen(command,env=env,cwd=output,stdout=log,stderr=subprocess.STDOUT)
                try:
                    def find_window():
                        if game.poll() is not None:raise RuntimeError(logfile.read_text())
                        result=subprocess.run(['xdotool','search','--onlyvisible','--pid',str(game.pid)],env=env,capture_output=True,text=True)
                        return result.stdout.strip().splitlines()[-1] if result.returncode==0 else None
                    window=wait_for(find_window)
                    time.sleep(4)
                    subprocess.run(['xdotool','windowfocus',window],env=env,check=True)
                    subprocess.run(['xdotool','key','F12'],env=env,check=True)
                    screenshot=wait_for(lambda:next(iter(output.glob('*.png')),None))
                    time.sleep(.25)
                    target=ASSETS/(name+'.png');shutil.copyfile(screenshot,target)
                    data=target.read_bytes();png_dimensions(target)
                    report[name]={'dimensions':struct.unpack('>II',data[16:24]),'sha256':hashlib.sha256(data).hexdigest(),
                                  'scene_sha256':hashlib.sha256((SCENES/(name+'.wad')).read_bytes()).hexdigest(),
                                  'light':VARIANTS[name][0],'step':VARIANTS[name][1],'guards':VARIANTS[name][2]}
                    print(name,report[name]['dimensions'],flush=True)
                finally:
                    if game.poll() is None:game.terminate();game.wait(timeout=10)
            logtext=logfile.read_text(errors='replace')
            assert 'MAP01' in logtext and 'Freeze mode: ON' in logtext,logtext
            assert not re.search(r'unknown\s+(?:wall\s+|flat\s+)?texture', logtext, re.IGNORECASE),logtext
            for error in ['Unknown command','Script error','Execution could not continue']:
                assert error not in logtext,logtext
    finally:
        server.terminate();server.wait(timeout=10)
    (work/'capture-report.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
