// Status Gallery — Service Worker
// Naikkan CACHE_VERSION setiap kali index.html/CSS/JS berubah agar user dapat versi baru.
const CACHE_VERSION = "v1";
const SHELL_CACHE = "sg-shell-" + CACHE_VERSION;
const IMAGE_CACHE = "sg-images-" + CACHE_VERSION;
const FONT_CACHE = "sg-fonts-" + CACHE_VERSION;

const APP_SHELL = [
  "./index.html",
  "./manifest.json",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-192.png",
  "./icons/icon-maskable-512.png",
  "./icons/apple-touch-icon.png"
];

const OFFLINE_URL = "./index.html";

self.addEventListener("message", function (event) {
  if (event.data && event.data.type === "SKIP_WAITING") {
    self.skipWaiting();
  }
});

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(SHELL_CACHE)
      .then(function (cache) { return cache.addAll(APP_SHELL); })
      .then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener("activate", function (event) {
  var keepCaches = [SHELL_CACHE, IMAGE_CACHE, FONT_CACHE];
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.filter(function (k) { return keepCaches.indexOf(k) === -1; })
            .map(function (k) { return caches.delete(k); })
      );
    }).then(function () { return self.clients.claim(); })
  );
});

function isImageRequest(url) {
  return url.hostname === "picsum.photos" || url.hostname.indexOf("supabase.co") > -1 && url.pathname.indexOf("/storage/") > -1;
}
function isFontRequest(url) {
  return url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com";
}

self.addEventListener("fetch", function (event) {
  var req = event.request;
  if (req.method !== "GET") return;
  var url = new URL(req.url);

  // 1) Navigasi halaman: network-first, fallback ke shell cache saat offline
  if (req.mode === "navigate") {
    event.respondWith(
      fetch(req).then(function (res) {
        var copy = res.clone();
        caches.open(SHELL_CACHE).then(function (cache) { cache.put("./index.html", copy); });
        return res;
      }).catch(function () {
        return caches.match(OFFLINE_URL);
      })
    );
    return;
  }

  // 2) Gambar (picsum / supabase storage): stale-while-revalidate
  if (isImageRequest(url)) {
    event.respondWith(
      caches.open(IMAGE_CACHE).then(function (cache) {
        return cache.match(req).then(function (cached) {
          var networkFetch = fetch(req).then(function (res) {
            if (res && res.status === 200) cache.put(req, res.clone());
            return res;
          }).catch(function () { return cached; });
          return cached || networkFetch;
        });
      })
    );
    return;
  }

  // 3) Font Google: cache-first (jarang berubah)
  if (isFontRequest(url)) {
    event.respondWith(
      caches.open(FONT_CACHE).then(function (cache) {
        return cache.match(req).then(function (cached) {
          return cached || fetch(req).then(function (res) {
            if (res && res.status === 200) cache.put(req, res.clone());
            return res;
          });
        });
      })
    );
    return;
  }

  // 4) App shell (manifest, icon, dsb): cache-first + update di background
  if (APP_SHELL.some(function (p) { return url.pathname.endsWith(p.replace("./", "")); })) {
    event.respondWith(
      caches.match(req).then(function (cached) {
        var networkFetch = fetch(req).then(function (res) {
          if (res && res.status === 200) {
            caches.open(SHELL_CACHE).then(function (cache) { cache.put(req, res.clone()); });
          }
          return res;
        }).catch(function () { return cached; });
        return cached || networkFetch;
      })
    );
    return;
  }

  // 5) Lainnya: coba jaringan, fallback ke cache kalau ada
  event.respondWith(
    fetch(req).catch(function () { return caches.match(req); })
  );
});
