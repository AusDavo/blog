#!/bin/bash
# Deploy blog to server
# Usage: ./deploy.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="stacker@192.168.1.103"
REMOTE_PATH="/srv/docker/caddy/repos/blog"

echo "Syncing blog to server..."
rsync -av --delete --exclude='public/' --exclude='.hugo_build.lock' "$SCRIPT_DIR/" "$SERVER:$REMOTE_PATH/"

echo "Building on server..."
ssh "$SERVER" "/srv/docker/caddy/deploy-blog.sh"

echo "Done! Visit https://blog.dpinkerton.com"
