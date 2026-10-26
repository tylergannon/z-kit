# sv

Everything you need to build a Svelte project, powered by [`sv`](https://github.com/sveltejs/cli).

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```sh
# create a new project
npx sv create my-app
```

To recreate this project with the same configuration:

```sh
# recreate this project
npx sv@1.1.1 create --template minimal --no-types --no-install /Users/tyler/.codex/worktrees/a096/z-kit/ephemeral/generator-probe/final-empty
```

## Adding features

Add features to your project with `sv add`:

```sh
npx sv add
```

For example, to add Tailwind CSS:

```sh
npx sv add tailwindcss
```

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```sh
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Building

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.

## z-kit development

This application was created with sv 1.1.1 and the z-kit empty starter.
Its build.zig.zon declares the local framework source dependency used during development.

```sh
pnpm install --frozen-lockfile
zig build
zig build dev
```

Open http://127.0.0.1:5173. Stop with Ctrl-C. Choose a port with
`zig build dev -- --port 5180`. The Zig listener proxies to Vite over a Unix socket.
The upstream `pnpm build` remains a SvelteKit frontend build; native production packaging is a later z-kit feature.
