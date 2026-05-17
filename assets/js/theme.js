// Dev URL rewriting - maps production URLs to local dev-server paths.
// Only active when the page is not served from bluefox.cafe.
//
// (The Tailwind theme config that used to live here moved into the build:
//  assets/css/main.css @theme — it is no longer needed at runtime.)
window.devUrls = {
    _map: {
        'https://bluefox.cafe':              '/',
        'https://dnd.bluefox.cafe':          '/dnd',
        'https://demiplane.bluefox.cafe':    '/preview/demiplane/',
        'https://beastworld.bluefox.cafe':   '/preview/beastworld/',
        'https://files.bluefox.cafe':        '/preview/files/',
    },
    _isDev: !window.location.hostname.endsWith('bluefox.cafe'),
    resolve(url) { return this._isDev ? (this._map[url] ?? url) : url; },
};

// Rewrite any <a data-resolve> href through the dev-URL map. Hugo renders
// the production URL; this adjusts it client-side only when off-domain.
// (Replaces the per-link resolveUrl() calls the old Vue app did.)
document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('a[data-resolve]').forEach(function (a) {
        a.href = window.devUrls.resolve(a.getAttribute('href'));
    });
});
