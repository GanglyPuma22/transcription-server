#!/usr/bin/env bash
set -euo pipefail

# Tail recent logs from the remote transcription service.
#
# Usage:
#   TAIL_LINES=200 ./scripts/logs-on-pi.sh [ssh-alias] [remote-dir]
#
# Defaults:
#   ssh-alias  = video-server
#   remote-dir = /home/mmounier/services/transcription-server
#   TAIL_LINES = 200

SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"
TAIL_LINES="${TAIL_LINES:-200}"

ssh -o BatchMode=yes "$SSH_ALIAS" "cd '$REMOTE_DIR' && docker compose logs --tail=$TAIL_LINES whisper"
