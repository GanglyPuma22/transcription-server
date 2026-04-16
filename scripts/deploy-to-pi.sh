#!/usr/bin/env bash
set -euo pipefail

# Deploy the transcription server to a remote Raspberry Pi or Linux host.
#
# Purpose:
# - sync tracked repo files to the remote host
# - ensure remote runtime config exists
# - preserve host-specific overrides and secrets
# - create the model cache volume if needed
# - pull and restart the Docker Compose service
#
# Usage:
#   ./scripts/deploy-to-pi.sh [ssh-alias] [remote-dir]
#
# Defaults:
#   ssh-alias  = video-server
#   remote-dir = /home/mmounier/services/transcription-server
#
# Notes:
# - If a legacy install exists at /home/mmounier/services/whisper, this script
#   will reuse its whisper.env when possible and shut the legacy stack down.
# - Remote .env and whisper.env files are treated as machine-local state and are
#   intentionally not overwritten by rsync.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"
LEGACY_DIR="/home/mmounier/services/whisper"

"$SCRIPT_DIR/sync-to-pi.sh" "$SSH_ALIAS" "$REMOTE_DIR"

ssh -o BatchMode=yes "$SSH_ALIAS" bash <<EOF
set -euo pipefail
REMOTE_DIR=${REMOTE_DIR@Q}
LEGACY_DIR=${LEGACY_DIR@Q}
mkdir -p "\$REMOTE_DIR"

# Ensure the runtime env exists before compose starts.
if [ ! -f "\$REMOTE_DIR/whisper.env" ]; then
  if [ -f "\$LEGACY_DIR/whisper.env" ]; then
    cp "\$LEGACY_DIR/whisper.env" "\$REMOTE_DIR/whisper.env"
    echo "Copied existing whisper.env from legacy service dir"
  else
    python3 - <<'PY'
from pathlib import Path
import secrets
remote_dir = Path(${REMOTE_DIR@Q})
example = (remote_dir / 'whisper.env.example').read_text()
example = example.replace('CHANGE_ME_GENERATE_ON_DEPLOY', secrets.token_urlsafe(32))
(remote_dir / 'whisper.env').write_text(example)
print('Generated new whisper.env with random API key')
PY
  fi
fi

cd "\$REMOTE_DIR"

# Load optional host-specific compose overrides if present.
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

# Reuse the existing named model cache when possible so redeploys stay fast.
docker volume create "\${WHISPER_MODEL_CACHE_VOLUME_NAME:-transcription-server-whisper-data}" >/dev/null

# Retire the legacy stack if it is still around.
if [ -f "\$LEGACY_DIR/docker-compose.yml" ]; then
  (cd "\$LEGACY_DIR" && docker compose down) || true
fi

docker compose pull
docker compose up -d
docker compose ps
EOF
