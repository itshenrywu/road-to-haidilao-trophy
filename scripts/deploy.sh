#!/usr/bin/env bash
# Build the site and deploy it to Cloudflare Pages (replaces the GitHub Pages workflow).
#
# Usage:
#   scripts/deploy.sh              # production deploy (main branch)
#   scripts/deploy.sh --preview    # preview deploy (branch: preview)
#   scripts/deploy.sh --build-only # only build ./deploy, don't upload
#
# Auth (one of):
#   - run `npx wrangler login` once locally, or
#   - set CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID (for CI / cron)
#
# Env overrides: CF_PAGES_PROJECT (default: haidilao-50)
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="${CF_PAGES_PROJECT:-haidilao-50}"
OUT_DIR="deploy"
BRANCH="main"
BUILD_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --preview)    BRANCH="preview" ;;
    --build-only) BUILD_ONLY=1 ;;
    -h|--help)    sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

echo "==> Installing dependencies"
if [ -f package-lock.json ]; then npm ci; else npm install; fi

echo "==> Generating index.html"
npm run gen

echo "==> Preparing ./$OUT_DIR"
rm -rf "$OUT_DIR"
mkdir "$OUT_DIR"
cp index.html tocas.min.css "$OUT_DIR"/

if [ "$BUILD_ONLY" = 1 ]; then
  echo "==> Build only, skipping upload"
  exit 0
fi

echo "==> Deploying to Cloudflare Pages (project: $PROJECT, branch: $BRANCH)"
npx --yes wrangler@latest pages deploy "$OUT_DIR" \
  --project-name "$PROJECT" \
  --branch "$BRANCH" \
  --commit-dirty=true
