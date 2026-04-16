#!/usr/bin/env bash
set -euo pipefail

SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"
TAIL_LINES="${TAIL_LINES:-200}"

ssh -o BatchMode=yes "$SSH_ALIAS" "cd '$REMOTE_DIR' && docker compose logs --tail=$TAIL_LINES whisper"
