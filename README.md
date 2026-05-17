# bluefox.cafe

Hugo static site for bluefox.cafe, migrated from the hand-written HTML that
previously lived in `caddy/` (homepage, DnD hub, preview/sign-in pages, error
pages).

## Structure

- `layouts/_default/baseof.html` - shared `<head>` (Tailwind CDN, theme.js,
  theme.css, Font Awesome, SEO meta, theme-color). All pages extend this.
- `layouts/partials/seo.html` - description / Open Graph / Twitter meta,
  driven by the `description` and `og` front matter.
- `layouts/index.html` - homepage (Vue app).
- `layouts/dnd/list.html` - the `/dnd/` hub (Vue app).
- `layouts/previews/single.html` - the per-service "sign in with Discord"
  pages. One template, content driven by front matter.
- `layouts/errors/single.html` - 403 / 404 / 5xx, one template driven by
  front matter (icon, accent colour, body, buttons).

Content lives in `content/`, shared assets in `static/shared/`.

## Output paths

| Source                       | Built path              |
|------------------------------|-------------------------|
| `content/_index.md`          | `/`                     |
| `content/dnd/_index.md`      | `/dnd/`                 |
| `content/previews/*.md`      | `/previews/<name>/`     |
| `content/errors/*.md`        | `/errors/<code>/`       |

## Notes

- `static/shared/theme.js` still contains the original dev-URL rewrite map
  (`/preview/...`, `/dnd`). That map targets the old Caddy dev layout; adjust
  it if the dev routing changes. It is inert in production (only active off
  `*.bluefox.cafe`).
- Some `og:image` references (`dnd.png`, `files.png`, `beastworld.png`) were
  carried over verbatim from the original HTML; those image files were not
  present in the source and are not included here.
- Error pages are emitted under `/errors/`, mirroring the old `caddy/errors/`
  layout, so the deploy script can wire them into Caddy as before.
