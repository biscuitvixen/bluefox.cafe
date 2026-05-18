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
