#!/usr/bin/env bash
set -euo pipefail

SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"

ssh -o BatchMode=yes "$SSH_ALIAS" "cd '$REMOTE_DIR' && docker compose restart whisper && docker compose ps"
