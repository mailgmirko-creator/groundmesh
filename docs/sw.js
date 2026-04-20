// docs/sw.js — prefer fresh network content, fall back to cache when offline
const CACHE = "gm-v9";
const ASSETS = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./resource.html",
  "./assets/gm-app-icon.svg",
  "./assets/pwa-init.js",
  "./assets/style.css",
  "./atlas/index.html",
  "./compute.html",
  "./contact.html",
  "./contribute.html",
  "./data/public-node-inbox.json",
  "./data/public-node-outbox.json",
  "./data/public-node-claims.json",
  "./data/public-node-acks.json",
  "./donate-cycles.html",
  "./get-started.html",
  "./get-started/index.html",
  "./landscape.html",
  "./ledger/index.html",
  "./map.html",
  "./privacy.html",
  "./register-pilot.html",
  "./register.html"
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.map((k) => (k !== CACHE ? caches.delete(k) : null)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const sameOrigin = new URL(req.url).origin === self.location.origin;
  if (!sameOrigin) return;

  e.respondWith(
    fetch(req)
      .then((res) => {
        const clone = res.clone();
        caches.open(CACHE).then((c) => c.put(req, clone));
        return res;
      })
      .catch(async () => {
        const cached = await caches.match(req);
        if (cached) {
          return cached;
        }

        if (req.mode === "navigate") {
          return caches.match("./index.html");
        }

        return Response.error();
      })
  );
});
