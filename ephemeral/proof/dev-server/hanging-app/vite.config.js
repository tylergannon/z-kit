// Deliberately unready application for the startup deadline demonstration.
export default {
  plugins: [{
    name: 'startup-never-ready',
    configureServer() {
      setInterval(() => {}, 1000);
      return new Promise(() => {});
    }
  }]
};
