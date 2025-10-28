{{flutter_js}}
{{flutter_build_config}}

const loaderContainer = document.getElementById("loader");

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();

    await timeout(1000);

    // Fade out the loading screen
    if (document.body.contains(loaderContainer)) {
      loaderContainer.style.transition = "opacity 0.4s ease-out";
      loaderContainer.style.opacity = "0";

      await timeout(401);

      if (document.body.contains(loaderContainer)) {
        document.body.removeChild(loaderContainer);
      }
    }

    await timeout(300);

    await appRunner.runApp();
  },
});

function timeout(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
