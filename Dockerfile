# Build toolchain for bluefox.cafe — everything runs in here, nothing on the host.
# Hugo extended (asset pipeline) + Tailwind v4 standalone (css.Tailwind shells
# out to it) + fonttools (Font Awesome woff2 subsetting).
# Pinned by digest for reproducible builds; bump deliberately, not implicitly.
# exts-0.154.5 is the latest version-pinned `exts` tag on Docker Hub.
FROM hugomods/hugo:exts-0.154.5@sha256:618b1a416bd37d7d4c63dbb779ac5ebf19bef8f47db50f048dd36b1df505c3de

# Tailwind v4 standalone CLI. hugomods images are Alpine/musl, so use the musl
# build. Hugo's css.Tailwind looks for `tailwindcss` on PATH. Pinned, not
# `latest/download`, so the CSS output can't shift under a rebuild.
ADD https://github.com/tailwindlabs/tailwindcss/releases/download/v4.3.0/tailwindcss-linux-x64-musl \
    /usr/local/bin/tailwindcss
RUN chmod +x /usr/local/bin/tailwindcss

# fonttools provides pyftsubset for trimming the Font Awesome font.
RUN apk add --no-cache python3 py3-pip \
    && pip install --no-cache-dir --break-system-packages fonttools brotli

WORKDIR /src
