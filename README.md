# bluefox.cafe

Hugo static site for bluefox.cafe, migrated from the hand-written HTML that
previously lived in `caddy/` (homepage, DnD hub, preview/sign-in pages, error
pages).

## Structure

- `layouts/_default/baseof.html` - shared `<head>`: builds one fingerprinted,
  minified CSS bundle (Tailwind + theme + Font Awesome) and the piped
  `theme.js`. All pages extend this.
- `layouts/partials/seo.html` - description / Open Graph / Twitter meta,
  driven by the `description` and `og` front matter.
- `layouts/partials/vue.html` - self-hosted Vue 3, included by the two Vue pages.
- `layouts/index.html` - homepage (Vue app).
- `layouts/dnd/single.html` - the `/dnd/` hub (Vue app); driven by the
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
- **JS**: `assets/js/theme.js` only (dev-URL rewrite map + `data-resolve`
  handler), piped through `js.Build` and fingerprinted. No runtime framework;
  the homepage rotator is an inline script in `layouts/index.html`.

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

- `assets/js/theme.js` contains the dev-URL rewrite map (`/preview/...`,
  `/dnd`). That map targets the old Caddy dev layout; adjust it if the dev
  routing changes. It is inert in production (only active off
  `*.bluefox.cafe`).
- Some `og:image` references (`dnd.png`, `files.png`, `beastworld.png`) were
  carried over verbatim from the original HTML; those image files were not
  present in the source and are not included here.
- Error pages are emitted under `/errors/`, mirroring the old `caddy/errors/`
  layout, so the deploy script can wire them into Caddy as before.
