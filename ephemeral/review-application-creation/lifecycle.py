"""One-off review: start real generated apps twice and inspect shutdown."""
from pathlib import Path
import json, os, re, signal, socket, subprocess, time, urllib.request
base=Path(__file__).resolve().parent
results=[]
for app, port in [('empty',5272),('examples-reinstall',5274)]:
 for cycle in [1,2]:
  log=base/f'{app}-cycle-{cycle}.log'
  with log.open('w') as out:
   p=subprocess.Popen(['zig','build','dev','--','--port',str(port)],cwd=base/app,stdout=out,stderr=out,start_new_session=True)
   try:
    deadline=time.monotonic()+40
    while time.monotonic()<deadline:
     text=log.read_text();m=re.search(r'Vite socket: (\S+)',text)
     if m: break
     assert p.poll() is None,text
     time.sleep(.1)
    else: raise AssertionError(text)
    path=Path(m[1]);status=urllib.request.urlopen(f'http://127.0.0.1:{port}').status
    os.killpg(p.pid,signal.SIGINT);p.wait(timeout=8)
    deadline=time.monotonic()+5
    while path.parent.exists() and time.monotonic()<deadline: time.sleep(.05)
    assert status==200 and not path.parent.exists(),log.read_text()
    with socket.socket() as s:
     s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1);s.bind(('127.0.0.1',port))
    results.append({'app':app,'cycle':cycle,'http':status,'port_released':True,'socket_directory_removed':True})
   finally:
    if p.poll() is None: os.killpg(p.pid,signal.SIGTERM);p.wait(timeout=8)
(base/'lifecycle.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
