// Upstream owns SvelteKit scaffolding. This script adds only z-kit's build/dev
// setup and its optional shared example page.
import { spawnSync } from 'node:child_process';
import { readFile, writeFile, readdir, realpath, copyFile, appendFile, lstat } from 'node:fs/promises';
import { resolve, join, relative } from 'node:path';
import { createInterface } from 'node:readline/promises';

const svVersion = '1.1.1';
const [sourceRoot, fingerprint, examplePage, ...args] = process.argv.slice(2);
const separator = args.indexOf('--');
const own = separator < 0 ? args : args.slice(0, separator);
const upstream = separator < 0 ? [] : args.slice(separator + 1);

function usage() {
  console.log('Usage: zkit new DIRECTORY [--template empty|examples] [--zkit-path PATH] [-- SV_OPTIONS]');
  console.log('Frontend options after -- go to sv create, e.g. --types jsdoc --add tailwindcss=plugins:none.');
  console.log('Without a terminal the defaults are empty, TypeScript and no add-ons. Requires Node, pnpm and Zig.');
  console.log('During framework development the generated manifest declares a local z-kit dependency.');
}

function run(step, command, argv, cwd) {
  console.log(`\nzkit: ${step}`);
  const result = spawnSync(command, argv, { cwd, stdio: 'inherit' });
  if (result.error) throw new Error(`${step}: ${result.error.message}`);
  if (result.status !== 0) throw new Error(`${step} failed (${result.signal ?? result.status}); inspect the output above`);
}

async function create() {
  if (own.includes('--help') || own.includes('-h')) return usage();
  let destination;
  let template;
  let framework = sourceRoot;
  for (let i = 0; i < own.length; i++) {
    const arg = own[i];
    if (arg === '--template') template = own[++i];
    else if (arg === '--zkit-path') framework = own[++i];
    else if (arg.startsWith('-') || destination) throw new Error(`Unknown argument: ${arg}; use -- before sv options`);
    else destination = arg;
    if ((arg === '--template' || arg === '--zkit-path') && !own[i]) throw new Error(`${arg} needs a value`);
  }
  if (!destination) throw new Error('A destination is required; run zkit new --help');
  if (!template && process.stdin.isTTY) {
    const prompt = createInterface({ input: process.stdin, output: process.stdout });
    try { template = (await prompt.question('Starter (empty/examples) [empty]: ')).trim() || 'empty'; }
    finally { prompt.close(); }
  }
  template ??= 'empty';
  if (!['empty', 'examples'].includes(template)) throw new Error('Choose --template empty or --template examples');
  for (const arg of upstream) {
    const option = arg.split('=')[0];
    if (['--template', '--install', '--no-install', '--no-dir-check', '--from-playground', '--addon-name'].includes(option)) {
      throw new Error(`${option} is owned by zkit new; use its empty/examples choice and pnpm installation`);
    }
  }
  let root = resolve(destination);
  // Refuse any existing destination, including an empty one or a symlink. The
  // wrapper never asks upstream to overwrite a developer's files.
  try { await lstat(root); throw new Error(`Destination already exists: ${root}`); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  framework = await realpath(framework);
  const frameworkPackage = await readFile(join(framework, 'build.zig.zon'), 'utf8');
  if (!frameworkPackage.includes('.name = .z_kit')) throw new Error('--zkit-path must point to the z-kit source package');
  const frontend = [...upstream];
  const has = (names) => frontend.some((arg) => names.includes(arg.split('=')[0]));
  if (!process.stdin.isTTY) {
    if (!has(['--types', '--no-types'])) frontend.push('--types', 'ts');
    if (!has(['--add', '--no-add-ons'])) frontend.push('--no-add-ons');
  }
  run(`create the SvelteKit application with sv ${svVersion}`, 'pnpm', [
    'dlx', `sv@${svVersion}`, 'create', root, '--template', 'minimal', '--no-install', ...frontend
  ]);
  root = await realpath(root);

  console.log('\nzkit: add Zig build/dev integration');
  const packagePath = join(root, 'package.json');
  const pkg = JSON.parse(await readFile(packagePath, 'utf8'));
  pkg.scripts.dev = 'zig build dev';
  pkg.zkit = { starter: template, upstream: { package: 'sv', version: svVersion } };
  await writeFile(packagePath, JSON.stringify(pkg, null, 2) + '\n');
  await writeFile(join(root, 'build.zig'), `const std = @import("std");

pub fn build(b: *std.Build) void {
    const zkit = b.dependency("zkit", .{ .target = b.graph.host });
    const host = zkit.artifact("z-kit-dev");
    b.installArtifact(host);
    const run = b.addRunArtifact(host);
    run.addArgs(&.{ "--app", "." });
    run.addPassthruArgs();
    b.step("dev", "Run this application through z-kit").dependOn(&run.step);
}
`);
  if (template === 'examples') await copyFile(examplePage, join(root, 'src/routes/+page.svelte'));
  await appendFile(join(root, '.gitignore'), '\n# Zig\n/.zig-cache/\n/zig-out/\n');
  await appendFile(join(root, 'README.md'), `
## z-kit development

This application was created with sv ${svVersion} and the z-kit ${template} starter.
Its build.zig.zon declares the local framework source dependency used during development.

\`\`\`sh
pnpm install --frozen-lockfile
${pkg.scripts.check ? 'pnpm check\n' : ''}zig build
zig build dev
\`\`\`

Open http://127.0.0.1:5173. Stop with Ctrl-C. Choose a port with
\`zig build dev -- --port 5180\`. The Zig listener proxies to Vite over a Unix socket.
The upstream \`pnpm build\` remains a SvelteKit frontend build; native production packaging is a later z-kit feature.
`);
  const paths = (await readdir(root)).filter((name) => !['node_modules', '.git', '.svelte-kit', '.zig-cache', 'zig-out'].includes(name));
  paths.push('build.zig.zon', 'pnpm-lock.yaml');
  await writeFile(join(root, 'build.zig.zon'), `.{
    .name = .zkit_app,
    .fingerprint = ${fingerprint},
    .version = "0.0.0",
    .minimum_zig_version = "0.18.0-dev.543+fa4f5b262",
    .dependencies = .{ .zkit = .{ .path = ${JSON.stringify(relative(root, framework) || '.')} } },
    .paths = .{ ${[...new Set(paths)].sort().map((name) => JSON.stringify(name)).join(', ')} },
}
`);
  run('install application dependencies', 'pnpm', ['install'], root);
  if (pkg.scripts.check) run('check the application', 'pnpm', ['check'], root);
  run('build the Zig development host', 'zig', ['build'], root);
  const quotedRoot = "'" + root.replaceAll("'", "'\\''") + "'";
  console.log(`\nzkit: created the ${template} application at ${root}\n\n  cd ${quotedRoot}\n  zig build dev\n\nOpen http://127.0.0.1:5173 after the server announces readiness.`);
}

try { await create(); }
catch (error) { console.error(`\nzkit: ${error.message}`); process.exitCode = 1; }
