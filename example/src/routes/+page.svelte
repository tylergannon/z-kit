<script>
  let count = $state(0);
</script>

<svelte:head>
  <title>z-kit · First application</title>
</svelte:head>

<main>
  <p class="eyebrow">z-kit / first application</p>
  <h1>A little Zig.<br />A little Svelte.</h1>
  <p class="intro">One running application. Room to grow.</p>
  <button onclick={() => count++}>Clicks: {count}</button>
  <p class="hint">Edit this page and watch it update.</p>
</main>

<style>
  :global(body) { margin: 0; background: #f7f5ed; color: #20372e; font-family: system-ui, sans-serif; }
  main { max-width: 48rem; margin: 0 auto; padding: 15vh 2rem 4rem; }
  .eyebrow { text-transform: uppercase; letter-spacing: .15em; font-size: .75rem; font-weight: 700; }
  h1 { font-size: clamp(3rem, 8vw, 5.5rem); line-height: 1.05; letter-spacing: -.055em; margin: 2rem 0; }
  .intro { font-size: 1.25rem; color: #53665c; }
  button { margin-top: 2rem; border: 0; border-radius: .6rem; padding: 1rem 1.5rem; background: #20372e; color: #fff; font: inherit; cursor: pointer; }
  button:hover { background: #385a49; }
  button:focus-visible { outline: 3px solid #b87920; outline-offset: 4px; }
  .hint { margin-top: 2rem; font-size: .875rem; color: #53665c; }
</style>
