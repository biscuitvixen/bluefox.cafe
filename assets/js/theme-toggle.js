// Theme toggle button. External (not inline) so script-src can drop
// 'unsafe-inline'. Deferred, so the button markup already exists.
(function () {
    var btn = document.getElementById('theme-toggle');
    var moon = document.getElementById('theme-toggle-icon-moon');
    var sun = document.getElementById('theme-toggle-icon-sun');
    if (!btn || !moon || !sun) return;

    function sync(theme) {
        var isLight = theme === 'light';
        moon.classList.toggle('hidden', isLight);
        sun.classList.toggle('hidden', !isLight);
        btn.setAttribute('aria-label', isLight ? 'Switch to dark theme' : 'Switch to light theme');
    }

    sync(document.documentElement.dataset.theme || 'dark');

    // Share preference across *.bluefox.cafe subdomains. The domain attribute
    // is only valid on the public site; on localhost we omit it and the cookie
    // falls back to host-only.
    var prod = /(?:^|\.)bluefox\.cafe$/i.test(location.hostname);
    var domainAttr = prod ? ';domain=.bluefox.cafe' : '';
    var secureAttr = location.protocol === 'https:' ? ';secure' : '';

    btn.addEventListener('click', function () {
        var next = document.documentElement.dataset.theme === 'light' ? 'dark' : 'light';
        document.documentElement.dataset.theme = next;
        document.cookie = 'theme=' + next + ';path=/' + domainAttr + ';max-age=31536000;samesite=lax' + secureAttr;
        sync(next);
    });
})();
