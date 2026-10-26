"""One-off demonstration against the real example, run from the repository root.
The temporary Kit endpoint used here is retained as transport-fixture.js.
"""
import http.client
import json
import os
from pathlib import Path
import re
import signal
import socket
import subprocess
import time

HERE = Path(__file__).resolve().parent
sessions = []
results = []

def launch(name, port=0, app='example', ready=True):
    log = HERE / f'{name}.log'
    output = log.open('w')
    process = subprocess.Popen(['zig-out/bin/z-kit-dev', '--port', str(port), '--app', app], stdout=output, stderr=output)
    sessions.append(process)
    deadline = time.monotonic() + 35
    while time.monotonic() < deadline:
        text = log.read_text()
        match = re.search(r'z-kit ready at http://127.0.0.1:(\d+)\nVite socket: (\S+)', text)
        if match:
            assert ready, text
            child = int(subprocess.check_output(['pgrep', '-P', str(process.pid)], text=True).strip())
            return process, int(match[1]), Path(match[2]), child
        if process.poll() is not None:
            assert not ready and process.returncode != 0, text
            assert 'z-kit ready at' not in text
            return process
        time.sleep(.05)
    raise AssertionError(f'startup did not settle: {log.read_text()}')

def request(port, method, path, body=None, headers=None):
    connection = http.client.HTTPConnection('127.0.0.1', port, timeout=5)
    connection.request(method, path, body, headers or {})
    response = connection.getresponse()
    result = response.status, {key.lower(): value for key, value in response.getheaders()}, response.read()
    connection.close()
    return result

def stopped(process, port, path, child, expected):
    assert process.wait(timeout=5) == expected
    assert not path.exists() and not path.parent.exists()
    try:
        os.kill(child, 0)
    except ProcessLookupError:
        pass
    else:
        raise AssertionError('Vite child survived shutdown')
    with socket.socket() as probe:
        probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        probe.bind(('127.0.0.1', port))

try:
    process, port, path, child = launch('normal')
    status, headers, html = request(port, 'GET', '/')
    assert status == 200 and b'A little Zig.' in html, (status, html[:1000])
    assert request(port, 'GET', '/@vite/client')[0] == 200
    status, _, icon = request(port, 'GET', '/favicon.svg')
    assert status == 200 and icon.startswith(b'<svg')
    assert request(port, 'HEAD', '/favicon.svg')[2] == b''
    assert request(port, 'GET', '/missing')[0] == 404
    payload = bytes(range(256)) * 1024
    for method in ['POST', 'PATCH']:
        status, headers, body = request(port, method, '/proxy-check/nested/path?q=one%20two&x=1', payload, {'content-type': 'application/octet-stream', 'x-proxy-check': 'untouched'})
        assert status == 207 and body == payload
        assert headers['x-request-method'] == method
        assert headers['x-request-target'] == '/proxy-check/nested/path?q=one%20two&x=1'
        assert headers['x-request-header'] == 'untouched'
        assert headers['set-cookie'] == 'proof=one; Path=/'
    status, headers, body = request(port, 'GET', '/proxy-check/stream')
    assert status == 200 and body == b'first chunk\nlast chunk\n'
    assert headers['transfer-encoding'] == 'chunked'
    with socket.create_connection(('127.0.0.1', port), timeout=5) as client:
        client.sendall(f'GET /favicon.svg HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nConnection: close\r\n\r\n'.encode())
        client.shutdown(socket.SHUT_WR)
        response = b''
        while chunk := client.recv(65536):
            response += chunk
        with socket.socket(socket.AF_UNIX) as direct:
            direct.settimeout(5)
            direct.connect(str(path))
            direct.sendall(f'GET /favicon.svg HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nConnection: close\r\n\r\n'.encode())
            direct.shutdown(socket.SHUT_WR)
            upstream_response = b''
            while chunk := direct.recv(65536):
                upstream_response += chunk
        assert response == upstream_response, (response[:500], upstream_response[:500])
    results.append('Real Kit SSR, assets, HEAD, 404, POST/PATCH with 256 KiB binary bodies, encoded target/query, headers, cookie, chunked response passed; early TCP half-close matches direct Vite behavior')
    occupied = launch('occupied-port', port=port, ready=False)
    assert 'AddressInUse' in (HERE / 'occupied-port.log').read_text()
    results.append('Occupied public port fails without announcing readiness')
    process.send_signal(signal.SIGTERM)
    stopped(process, port, path, child, 0)
    results.append('SIGTERM releases listener, active session, Vite child and socket directory')
    process, port, path, child = launch('restart', port=port)
    process.send_signal(signal.SIGINT)
    stopped(process, port, path, child, 0)
    results.append('Same public port restarts; SIGINT performs complete cleanup')
    process, port, path, child = launch('vite-crash', port=port)
    os.kill(child, signal.SIGKILL)
    stopped(process, port, path, child, 1)
    assert 'ViteExited' in (HERE / 'vite-crash.log').read_text()
    results.append('Unexpected Vite exit is reported and releases listener/socket')
    launch('bad-application', app='ephemeral/proof/dev-server/nonexistent-app', ready=False)
    results.append('Invalid application startup fails without announcing readiness')
    launch('startup-timeout', app='ephemeral/proof/dev-server/hanging-app', ready=False)
    assert 'StartupTimeout' in (HERE / 'startup-timeout.log').read_text()
    results.append('Unready Vite/application reaches the 30-second deadline without announcing readiness')
    (HERE / 'lifecycle.json').write_text(json.dumps({'results': results, 'passed': True}, indent=2) + '\n')
    print('\n'.join(results), flush=True)
finally:
    for process in sessions:
        if process.poll() is None:
            process.send_signal(signal.SIGTERM)
            process.wait(timeout=5)
