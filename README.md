# bluefox.cafe

Hugo static site for bluefox.cafe, migrated from the hand-written HTML that
previously lived in `caddy/` (homepage, DnD hub, preview/sign-in pages, error
pages).

## Structure

- `layouts/_default/baseof.html` - shared `<head>`: builds one fingerprinted,
  minified CSS bundle (Tailwind + theme + Font Awesome). All pages extend this;
  per-page scripts go in the `scripts` block. No JS asset pipeline.
- `layouts/partials/seo.html` - description / Open Graph / Twitter meta,
  driven by the `description` and `og` front matter.
- `layouts/partials/resolve-url.html` - maps a production URL to its local
  dev-server path under `hugo server` (via `params.devUrls` in `hugo.toml`);
  passes through untouched on a production build.
- `layouts/partials/link-rows.html` - reusable tool/operation link rows.
- `layouts/index.html` - homepage; Hugo-rendered, with an inline vanilla
  rotator script (no framework).
- `layouts/dnd/single.html` - the `/dnd/` hub, Hugo-rendered; driven by the
  `content/dnd.md` leaf page (`type: dnd`).
- `layouts/previews/single.html` - the per-service "sign in with Discord"
  pages. One template, content driven by front matter.
- `layouts/errors/single.html` - 403 / 404 / 5xx, one template driven by
  front matter (icon, accent colour, body, buttons).

Content lives in `content/`. Pipeline-built assets live in `assets/`;
fonts and OG images in `static/`.

## Build (no host toolchain — runs in a container)

Hugo extended, the Tailwind v4 standalone binary, and `fonttools` all live in
the project Docker image; nothing is installed on the host.

```sh
docker compose build tool          # build the toolchain image (once)
docker compose run --rm build      # build the site -> public/
docker compose up serve            # local preview on http://localhost:1313
```

The image is pinned by digest (`hugomods/hugo:exts-0.154.5`) and the Tailwind
release is pinned to a tagged version, so a rebuild can't silently change the
toolchain or the rendered output; bump these deliberately in the `Dockerfile`.
The container runs as the host user (`user:` in `docker-compose.yml`, default
`1000:1000`) so `public/`, `resources/` and `.hugo_build.lock` come back
host-owned. If your host UID/GID isn't 1000, run with
`UID=$(id -u) GID=$(id -g) docker compose ...`.

### Asset pipeline (Hugo Pipes — no runtime CDNs)

- **Tailwind**: `assets/css/main.css` (`@import "tailwindcss"` + `@theme`
  design tokens). Hugo's `build.buildStats` writes `hugo_stats.json`; Tailwind
  scans it so only used classes ship (`@source "hugo_stats.json"`), plus an
  inline safelist for the error pages' dynamically composed colours.
- **Theme CSS**: `assets/css/theme.css` (hand-written; body gradient,
  `hero-card`, `orb-*`, `glow-*`, self-hosted Cinzel Decorative `@font-face`).
- **Font Awesome**: `assets/css/fontawesome.css` — only the 7 icons used; the
  webfont in `static/fonts/fa-solid-900.woff2` is subset to those glyphs
  (~1.5 KB, was ~156 KB).
- The three are concatenated → minified → fingerprinted into one stylesheet.
- **JS**: none in the asset pipeline. Dev-URL rewriting is done at build time
  by the `resolve-url.html` partial (driven by `params.devUrls` in
  `hugo.toml`), not client-side JS. No runtime framework; the homepage rotator
  is an inline script in `layouts/index.html`.

To re-vendor a dependency (Font Awesome / Cinzel) or re-subset the FA font,
run the fetch/`pyftsubset` commands inside `docker compose run --rm tool`.

## Output paths

| Source                       | Built path              |
|------------------------------|-------------------------|
| `content/_index.md`          | `/`                     |
| `content/dnd.md`             | `/dnd/`                 |
| `content/previews/*.md`      | `/previews/<name>/`     |
| `content/errors/*.md`        | `/errors/<code>/`       |

The `previews` and `errors` sections set `build.render: never` /
`list: never` in their `_index.md`, so `/previews/` and `/errors/` have no
landing page and the child pages are reached only by direct URL.

## Public vs gated content (read before adding files)

Caddy's front-end design relies on a hard split between paths that are
served publicly from every subdomain and paths that are served only
behind a Discord-guild auth gate. The split is a property of the build
tree, not of any per-file config — so anything you add under the public
paths is publicly readable from the moment it deploys, including from
gated subdomains' URLs (e.g. `dnd.bluefox.cafe/css/secret.css`).

**Always public, from every subdomain, no auth:**

- `/css/*` — fingerprinted style bundles
- `/fonts/*` — webfonts (Cinzel, FA subset)
- `/shared/*` — OG cover images and any other cross-subdomain media

Caddy serves these via `handle_path` blocks that run *before* the auth
gate. Treat the entire output of these three trees as a public CDN.
Never put secrets, gated game data, draft writeups, anything member-only
in them — even if the only link to the file is in a private template.

**Public to known crawler bots (Discord, Telegram, Slack, etc.), no auth:**

- `/previews/<name>/` — the per-service sign-in / link-preview pages

These are served unauthenticated when the request `User-Agent` matches a
known bot. The User-Agent check is trivially spoofable, so functionally
this tree is "public to anyone who sets a Discord-bot UA." Keep these
pages limited to title, blurb, OG image — never real game content.

**Gated (auth required):**

- `/<game>/` (`/dnd/`, `/beastworld/`, ...) — served only at that game's
  subdomain, only to users in the gating Discord guild.
- `/errors/<code>/` — public output, but only ever served as a rendered
  error response by Caddy, never linked directly.

If a new section needs to be gated, it must live at its own top-level
path (`/<name>/`) and Caddy must add a matching `gated_static_site` or
`gated_proxy_site` block — public paths above are not a place to put
"semi-private" content.

## Notes

- The dev-URL rewrite map lives in `[params.devUrls]` in `hugo.toml`
  (production subdomains -> local Hugo paths, e.g. `/previews/...`, `/dnd/`),
  applied by the `resolve-url.html` partial. Keep it in sync with Hugo's
  output paths if content sections move. It is applied only under
  `hugo server`; a production build emits the real URLs untouched.
- Some `og:image` references (`dnd.png`, `files.png`, `beastworld.png`) were
  carried over verbatim from the original HTML; those image files were not
  present in the source and are not included here.
- Error pages are emitted under `/errors/`, mirroring the old `caddy/errors/`
  layout, so the deploy script can wire them into Caddy as before.

## Deploy

`make deploy` invokes `deploy.sh`. Configure via `.env` (copied from
`.env.example`); environment variables override it.

```sh
cp .env.example .env       # then edit HOST / PATH
make deploy                # uses .env
DEPLOY_HOST= make deploy   # one-off: publish locally
```

Mode is derived from `DEPLOY_HOST`: set means remote (ssh + rsync over
Tailscale), unset means local (publish to `$DEPLOY_PATH` on this host).

Config (`.env` keys, also accepted as environment):

- `DEPLOY_HOST` — tailnet hostname of the VPS; unset for local mode
- `DEPLOY_PATH` — base dir Caddy serves from (default `/srv/bluefox`)

Layout under `$DEPLOY_PATH`:

```
current -> releases/<timestamp>/   # symlink served by Caddy
releases/<timestamp>/              # last 5 retained
```

Each run builds in the pinned container toolchain, rsyncs `public/` to
a new `releases/<timestamp>/`, then flips `current` with a single
`ln -sfn`. The flip is atomic and Caddy is not restarted. In remote
mode the transport is SSH over Tailscale; port 22 on the VPS is not
exposed to the internet.
