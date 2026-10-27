import { build } from 'esbuild';
await build({
  entryPoints: ['tooling/sv/addon.source.js'],
  outfile: 'tooling/sv/addon.js',
  bundle: true,
  minify: true,
  platform: 'node',
  format: 'esm',
  target: 'node24',
  external: ['sv'],
  loader: { '.svelte': 'text' }
});
