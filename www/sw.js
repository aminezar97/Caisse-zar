const CACHE_NAME = "zarouali-caisse-v3";
const CORE_FILES = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./html5-qrcode.min.js",
  "./data/products.csv",
  "./data/catalog.js",
  "./icons/icon-192.png",
  "./icons/icon-512.png"
];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(CORE_FILES)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  if (url.pathname.includes("/images/") || url.pathname.endsWith("/products.csv") || url.pathname.endsWith("/catalog.js")) {
    event.respondWith(caches.match(event.request).then(cached => cached || fetch(event.request).then(response => {
      if (response && response.ok) caches.open(CACHE_NAME).then(c => c.put(event.request, response.clone()));
      return response;
    }).catch(() => cached || Response.error())));
    return;
  }
  event.respondWith(caches.match(event.request).then(cached => cached || fetch(event.request).then(response => {
    if (response && response.ok && response.type === "basic") caches.open(CACHE_NAME).then(c => c.put(event.request, response.clone()));
    return response;
  }).catch(() => caches.match("./index.html"))));
});
