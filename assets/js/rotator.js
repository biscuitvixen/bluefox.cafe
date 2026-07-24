// Homepage status-line rotator. External (not inline) so script-src can drop
// 'unsafe-inline'. Roles come from the #role element's data-roles attribute
// (JSON), set by the template, so this file stays static and cacheable.
(function () {
    var el = document.getElementById('role');
    if (!el) return;
    var roles;
    try { roles = JSON.parse(el.dataset.roles || '[]'); } catch (e) { return; }
    if (roles.length < 2) return;
    var i = 0;
    setInterval(function () {
        el.classList.add('role-leave');
        setTimeout(function () {
            i = (i + 1) % roles.length;
            el.textContent = roles[i];
            el.classList.remove('role-leave');
            el.classList.add('role-enter');
            requestAnimationFrame(function () {
                requestAnimationFrame(function () {
                    el.classList.remove('role-enter');
                });
            });
        }, 450);
    }, 3200);
})();
