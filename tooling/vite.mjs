// The Zig host owns this process and its socket directory. stdout is the
// one-byte readiness channel; all Vite diagnostics go to stderr.
import { createServer as createHttpServer, get } from 'node:http';
import { once } from 'node:events';
import { resolve } from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';

console.log = console.error;
const [app, socketPath, origin] = process.argv.slice(2);
const root = resolve(app);
process.chdir(root);
// As in SKGo's dev-host: Vite belongs to the application, not this launcher.
const application = createRequire(resolve(root, 'package.json'));
const { createServer } = await import(pathToFileURL(application.resolve('vite')).href);
const address = new URL(origin);
const http = createHttpServer();
const vite = await createServer({
  root,
  clearScreen: false,
  server: {
    middlewareMode: { server: http },
    origin,
    hmr: { server: http, host: address.hostname, clientPort: Number(address.port) }
  }
});
http.on('request', (request, response) => vite.middlewares(request, response));
http.listen(socketPath);
await once(http, 'listening');

// Rendering the real application catches startup/configuration errors before
// the host announces an address. Merely binding the socket isn't readiness.
await new Promise((resolve, reject) => {
  const request = get({ socketPath, path: '/', headers: { host: address.host } }, (response) => {
    response.resume();
    response.on('end', () => {
      if (response.statusCode === 200) resolve();
      else reject(new Error(`Application startup returned HTTP ${response.statusCode}`));
    });
    response.on('error', reject);
  });
  request.on('error', reject);
});
process.stdout.write('R');

async function stop() {
  await vite.close();
  http.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 1000).unref();
}
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
