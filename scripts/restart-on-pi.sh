#!/usr/bin/env bash
set -euo pipefail

# Restart the remote transcription service and print compose status.
#
# Usage:
#   ./scripts/restart-on-pi.sh [ssh-alias] [remote-dir]
#
# Defaults:
#   ssh-alias  = video-server
#   remote-dir = /home/mmounier/services/transcription-server

SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"

ssh -o BatchMode=yes "$SSH_ALIAS" "cd '$REMOTE_DIR' && docker compose restart whisper && docker compose ps"
