self.addEventListener('install', (event) => {
  // Activate immediately
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  // Unregister this service worker
  self.registration.unregister()
    .then(() => {
      return self.clients.matchAll({ type: 'window' });
    })
    .then((clients) => {
      // Force reload all open tabs
      for (const client of clients) {
        client.navigate(client.url);
      }
    });
});
