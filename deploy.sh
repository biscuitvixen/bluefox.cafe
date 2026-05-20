#!/usr/bin/env sh
# Build the site and publish a release.
#
# Config is read from ./.env if present (see .env.example) and may be
# overridden by environment variables.
#
# Mode is derived from DEPLOY_HOST:
#   set    -> remote: ssh + rsync to $DEPLOY_HOST over Tailscale
#   unset  -> local:  publish to $DEPLOY_PATH on the current host
#
# Server contract: a directory of files. Caddy serves
# $DEPLOY_PATH/current, a symlink. Each run writes a timestamped
# release dir and flips the symlink with one `ln -sfn` — atomic,
# zero-downtime, Caddy is not restarted.
#
# Env (also settable in .env):
#   DEPLOY_HOST   tailnet hostname of the VPS   (unset = local mode)
#   DEPLOY_PATH   base dir Caddy serves from    (default: /srv/bluefox)
set -eu

repo="$(cd "$(dirname "$0")" && pwd)"
cd "$repo"

# shellcheck disable=SC1091
[ -f .env ] && . ./.env

host="${DEPLOY_HOST:-}"
base="${DEPLOY_PATH:-/srv/bluefox}"
rel="$(date -u +%Y%m%d-%H%M%S)"

echo "==> building site in the pinned container toolchain"
docker compose run --rm build

# Mode-specific bindings. `run` executes a shell command on the target
# (local sh or remote ssh); `dest` is the rsync destination prefix;
# `where` is a human label for logs. The publish sequence below is
# identical for both modes.
if [ -z "$host" ]; then
    run() { sh -c "$1"; }
    dest="$base/releases/$rel/"
    where="$base"
else
    run() { ssh "$host" "$1"; }
    dest="$host:$base/releases/$rel/"
    where="$host:$base"
fi

echo "==> publishing release $rel to $where"
run "mkdir -p '$base/releases/$rel'"
rsync -a --delete public/ "$dest"
run "ln -sfn '$base/releases/$rel' '$base/current' \
  && ls -1dt '$base'/releases/*/ | tail -n +6 | xargs -r rm -rf"
echo "==> live: $where/current -> releases/$rel"
