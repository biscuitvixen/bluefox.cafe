---
title: "bluefox.cafe"
description: "Sandy's corner of the internet. Tabletop nights and far too many half-built projects."
og:
  url: "https://bluefox.cafe"
  title: "bluefox.cafe"
  description: "Sandy's corner of the internet. Tabletop nights and far too many half-built projects."
  image: "https://assets.bluefox.cafe/shared/og/sandy.webp"
  # Processed to a 1200x630 webp by seo.html; falls back to `image` above.
  imageAsset: "images/biscuit-lofi.webp"

# Rotating status line (cycled client-side by a tiny vanilla script).
roles:
  - "probably soldering something"
  - "rolling dice somewhere"
  - "making LEDs blink"
  - "sewing electronics into fur"
  - "up to no good"
  - "wishing they had more time for projects"
  - "definitely not napping"
  - "thinking about making a blog"
  - "wondering if they should make a blog"

# Main links. Prod URLs; auto-mapped to dev paths under `hugo server`.
# The '#' ones are placeholders for pages I haven't built yet.
links:
  - label: "Roll Initiative"
    href: "https://dnd.bluefox.cafe"
    sub: "Foundry VTT"
    primary: true
    faIcon: "fa-solid fa-dice-d20"
  - label: "Art"
    href: "#"
    sub: "soon"
    icon: "🎨"

# Small utility buttons beneath the main links.
quicklinks:
  - label: "Files"
    href: "https://files.bluefox.cafe"
    icon: "📁"
  - label: "GitHub"
    href: "https://github.com/biscuitvixen"
    icon: "🐙"

# Contact / socials - small buttons in their own section above Ops.
contact:
  - label: "Telegram"
    href: "https://t.me/biscuit_fox"
    svg: "icons/telegram.svg"
  - label: "Discord"
    href: "https://discord.com/users/228574936157913088"
    svg: "icons/discord.svg"

# Admin tools - linked directly (no dev-URL rewrite).
ops:
  - name: "Uptime Kuma"
    icon: "💓"
    desc: "Service health"
    href: "https://kuma.bluefox.cafe"
  - name: "Dozzle"
    icon: "📜"
    desc: "Container logs"
    href: "https://logs.bluefox.cafe"
---
