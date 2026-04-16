#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"

rsync -az --delete \
  --exclude '.git/' \
  --exclude 'whisper.env' \
  --exclude '.DS_Store' \
  "$APP_DIR/" "$SSH_ALIAS:$REMOTE_DIR/"

echo "Synced $APP_DIR -> $SSH_ALIAS:$REMOTE_DIR"
