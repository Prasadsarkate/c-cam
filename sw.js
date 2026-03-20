// C-CAM v3.0 - Service Worker for PWA compliance
self.addEventListener('install', function(event) {
    event.waitUntil(
        caches.open('ccam-pwa').then(function(cache) {
            return cache.addAll([
                './',
                './manifest.json',
                './verify_icon.png'
            ]);
        })
    );
});

self.addEventListener('fetch', function(event) {
    event.respondWith(
        caches.match(event.request).then(function(response) {
            return response || fetch(event.request);
        })
    );
});
