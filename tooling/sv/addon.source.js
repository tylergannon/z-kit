// Adapted from SKGo internal/sv/sv-addon.source.js (MIT; see LICENSE).
import fs from 'node:fs';
import path from 'node:path';
import { defineAddon, defineAddonOptions } from 'sv';
import { pnpm, transforms } from '@sveltejs/sv-utils';
import examplesPage from '../../example/src/routes/+page.svelte';

const options = defineAddonOptions()
 .add('starter', { type: 'select', question: 'Starting point', default: 'minimal', options: [{value:'minimal',label:'minimal'}, {value:'examples',label:'examples'}] })
 .add('name', { type: 'string', question: 'Application name', default: 'zkit-app' })
 .build();

const propertyName = (property) => {
	if (property.type !== 'Property' || property.computed) return undefined;
	if (property.key.type === 'Identifier') return property.key.name;
	if (property.key.type === 'Literal' || property.key.type === 'StringLiteral') return property.key.value;
	return undefined;
};

const getProperty = (object, name) =>
	object?.type === 'ObjectExpression'
		? object.properties.find((property) => propertyName(property) === name)
		: undefined;

const hasSpread = (object) =>
	object?.type === 'ObjectExpression' &&
	object.properties.some((property) => property.type === 'SpreadElement');

const hasComputedProperty = (object) =>
	object?.type === 'ObjectExpression' &&
	object.properties.some((property) => property.type === 'Property' && property.computed);

const hasDuplicateProperties = (object, names) =>
	object?.type === 'ObjectExpression' &&
	names.some((name) => object.properties.filter((property) => propertyName(property) === name).length > 1);

const setProperty = (object, name, value, js) => {
	const property = getProperty(object, name);
	if (property) {
		property.value = js.common.parseExpression(JSON.stringify(value));
		return;
	}
	js.object.overrideProperties(object, { [name]: value });
};

const setExpressionProperty = (object, name, expression, js) => {
	const property = getProperty(object, name);
	if (property) {
		property.value = js.common.parseExpression(expression);
		return;
	}
	const added = js.common.parseExpression(`({ ${name}: ${expression} })`).properties[0];
	object.properties.push(added);
};


const findDefaultConfig = (ast) => {
	const value = ast.body.find((node) => node.type === 'ExportDefaultDeclaration')?.declaration;
	if (value?.type === 'ObjectExpression') return value;
	if (
		value?.type === 'CallExpression' &&
		value.arguments.length === 1 &&
		value.arguments[0]?.type === 'ObjectExpression'
	) {
		const callee = value.callee;
		if (callee?.type !== 'Identifier') return null;
		const fromPlaywright = ast.body.some((node) =>
			node.type === 'ImportDeclaration' &&
			node.source.value === '@playwright/test' &&
			node.specifiers.some((specifier) =>
				specifier.type === 'ImportSpecifier' &&
				(specifier.imported?.name ?? specifier.imported?.value) === 'defineConfig' &&
				specifier.local?.name === callee.name
			)
		);
		if (fromPlaywright) return value.arguments[0];
	}
	return null;
};

const repairPlaywright = (sv, cwd, language, origin) => {
	const file = `playwright.config.${language}`;
	if (!fs.existsSync(path.resolve(cwd, file))) return;
	sv.file(file, transforms.script(({ ast, js, content }) => {
		const config = findDefaultConfig(ast);
		if (!config) {
			if (content.includes('npm run build && npm run preview')) {
				throw new Error(`zkit cannot repair ${file}: the upstream Playwright launcher is present, but its default export is not a direct object or a single-argument imported defineConfig(object); rewrite the export before adding zkit`);
			}
			return false;
		}
		const webServer = getProperty(config, 'webServer')?.value;
		const command = getProperty(webServer, 'command')?.value;
		const port = getProperty(webServer, 'port')?.value;
		if (command?.type !== 'Literal' && command?.type !== 'StringLiteral') {
			if (content.includes('npm run build && npm run preview')) {
				throw new Error(`zkit cannot repair ${file}: the upstream Playwright launcher is present outside a literal webServer object; rewrite that configuration before adding zkit`);
			}
			return false;
		}
		if (command.value !== 'npm run build && npm run preview') return false;
		const usePropertyCount = config.properties.filter((property) => propertyName(property) === 'use').length;
		if (
			hasSpread(config) ||
			hasComputedProperty(config) ||
			hasDuplicateProperties(config, ['webServer', 'use']) ||
			hasSpread(webServer) ||
			hasComputedProperty(webServer) ||
			hasDuplicateProperties(webServer, ['command', 'port', 'url']) ||
			usePropertyCount > 1
		) {
			throw new Error(`zkit cannot repair ${file}: the upstream Playwright launcher has a spread, computed, or duplicate launcher property, so its effective server settings are ambiguous; simplify that configuration before adding zkit`);
		}
		if (webServer?.type !== 'ObjectExpression' || port?.value !== 4173) {
			throw new Error(`zkit cannot repair ${file}: the upstream Playwright launcher command is present, but its server configuration is not the stock npm/4173 shape`);
		}

		setProperty(webServer, 'command', 'cd .. && zig build dev', js);
		webServer.properties = webServer.properties.filter((property) => propertyName(property) !== 'port');
		const selectedOrigin = JSON.stringify(origin);
		setExpressionProperty(webServer, 'url', selectedOrigin, js);
		let use = getProperty(config, 'use')?.value;
		if (!use) {
			use = js.common.parseExpression('defineConfig({})').arguments[0];
			js.object.overrideProperties(config, { use });
		}
		if (
			use.type !== 'ObjectExpression' ||
			hasSpread(use) ||
			hasComputedProperty(use) ||
			hasDuplicateProperties(use, ['baseURL'])
		) {
			throw new Error(`zkit cannot repair ${file}: its "use" configuration is not a plain object or has a spread/computed/duplicate baseURL; simplify it before adding zkit`);
		}
		setExpressionProperty(use, 'baseURL', selectedOrigin, js);
	}));
};

const demoPaths = [
	'src/routes/sverdle',
	'src/routes/about',
	'src/routes/Header.svelte',
	'src/routes/Counter.svelte',
	'src/routes/+page.js',
	'src/routes/+page.ts',
	'src/lib/images'
];
const demoDependencies = ['@fontsource/fira-mono', '@neoconfetti/svelte'];

export default defineAddon({
 id: 'zkit',
 shortDescription: 'Zig development server integration',
 homepage: 'https://github.com/tylergannon/z-kit',
 options,
 setup: ({ isKit, unsupported, runsAfter }) => {
  if (!isKit) unsupported('Requires SvelteKit');
  runsAfter('vitest');
  runsAfter('playwright');
 },
 run: ({ sv, file, cwd, options, language }) => {
  const vitePlus = JSON.parse(fs.readFileSync(path.join(cwd, 'node_modules/vite-plus/package.json'), 'utf8'));
  if (vitePlus.version !== '1.4.0') throw new Error(`zkit requires VitePlus 1.4.0; found ${vitePlus.version}`);
  sv.file(file.package, transforms.json(({ data }) => {
   data.name = decodeURIComponent(options.name);
   data.scripts.dev = 'cd .. && zig build dev';
   data.scripts.preview = 'cd .. && zig build dev';
   data.scripts.test = 'vp run test:unit --run';
   // Match SKGo: the test runtime must agree with VitePlus's own Vitest.
   for (const key of Object.keys(data.devDependencies ?? {})) {
    if (key === 'vitest' || key.startsWith('@vitest/')) data.devDependencies[key] = vitePlus.dependencies.vitest;
    if (key === 'vitest-browser-svelte') data.devDependencies[key] = '3.1.0';
    if (options.starter === 'examples' && demoDependencies.includes(key)) delete data.devDependencies[key];
   }
   // Record the actual installed versions for the core frontend toolchain.
   for (const key of ['@sveltejs/kit', '@sveltejs/vite-plugin-svelte', 'svelte', 'svelte-check', 'typescript']) {
    const installed = path.join(cwd, 'node_modules', key, 'package.json');
    if (data.devDependencies[key] && fs.existsSync(installed)) data.devDependencies[key] = JSON.parse(fs.readFileSync(installed, 'utf8')).version;
   }
  }));
  if (language !== 'ts' && fs.existsSync(path.join(cwd, 'src/lib/vitest-examples/greet.js'))) {
   sv.file('src/lib/vitest-examples/greet.js', content => content.replace('export function greet(name) {', '/** @param {string} name */\nexport function greet(name) {'));
  }
  sv.file('pnpm-workspace.yaml', pnpm.allowBuilds({ cwd, packages: ['esbuild'] }));
  // Storybook 10.6.2's optional peer range predates VitePlus 1.x.
  // This precise pair is exercised by the fresh-app proof.
  sv.file('pnpm-workspace.yaml', transforms.yaml(({ data }) => {
   const rules = data.get('peerDependencyRules');
   const value = rules?.toJSON?.() ?? rules ?? {};
   value.allowedVersions ??= {};
   value.allowedVersions['storybook@10.6.2>vite-plus'] = '1.4.0';
   data.set('peerDependencyRules', value);
  }));
  if (options.starter === 'examples') {
   if (fs.existsSync(path.join(cwd, 'src/routes/Header.svelte'))) {
    let stylesheet = false;
    sv.file('src/routes/layout.css', content => {
     const kept = content.split('\n').filter(line => /^@(import|plugin)\s+['"](tailwindcss|@tailwindcss\/)/.test(line));
     stylesheet = kept.length > 0;
     return stylesheet ? kept.join('\n') + '\n' : false;
    });
    if (!stylesheet) fs.rmSync(path.join(cwd, 'src/routes/layout.css'), {force:true});
    sv.file('src/routes/+layout.svelte', () =>
     `<script${language === 'ts' ? ' lang="ts"' : ''}>\n` +
     (stylesheet ? " import './layout.css';\n" : '') +
     (language === 'ts' ? ' let { children } = $props();\n' : " /** @type {{children: import('svelte').Snippet}} */\n let { children } = $props();\n") +
     '</script>\n\n{@render children()}\n');
   }
   for (const entry of demoPaths) fs.rmSync(path.join(cwd, entry), {recursive:true, force:true});
   sv.file('src/routes/+page.svelte', () => examplesPage);
  }
  repairPlaywright(sv, cwd, language, 'http://127.0.0.1:5173');
 },
 nextSteps: () => []
});
