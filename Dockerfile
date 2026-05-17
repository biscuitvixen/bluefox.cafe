# Build toolchain for bluefox.cafe — everything runs in here, nothing on the host.
# Hugo extended (asset pipeline) + Tailwind v4 standalone (css.Tailwind shells
# out to it) + fonttools (Font Awesome woff2 subsetting).
FROM hugomods/hugo:exts

# Tailwind v4 standalone CLI. hugomods images are Alpine/musl, so use the musl
# build. Hugo's css.Tailwind looks for `tailwindcss` on PATH.
ADD https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64-musl \
    /usr/local/bin/tailwindcss
RUN chmod +x /usr/local/bin/tailwindcss

# fonttools provides pyftsubset for trimming the Font Awesome font.
RUN apk add --no-cache python3 py3-pip \
    && pip install --no-cache-dir --break-system-packages fonttools brotli

WORKDIR /src
