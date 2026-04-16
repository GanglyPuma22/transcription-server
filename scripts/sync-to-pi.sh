#!/usr/bin/env bash
set -euo pipefail

# Sync the tracked repo contents to a remote host.
#
# Purpose:
# - copy the app directory to the remote machine
# - preserve remote-only secrets and host overrides
# - keep the remote deployment directory in sync with git-tracked files
#
# Usage:
#   ./scripts/sync-to-pi.sh [ssh-alias] [remote-dir]
#
# Defaults:
#   ssh-alias  = video-server
#   remote-dir = /home/mmounier/services/transcription-server

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"

# Keep remote machine-specific config and secrets in place.
rsync -az --delete \
  --exclude '.git/' \
  --exclude '.env' \
  --exclude 'whisper.env' \
  --exclude '.DS_Store' \
  "$APP_DIR/" "$SSH_ALIAS:$REMOTE_DIR/"

echo "Synced $APP_DIR -> $SSH_ALIAS:$REMOTE_DIR"
