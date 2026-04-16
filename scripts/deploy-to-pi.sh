#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"
LEGACY_DIR="/home/mmounier/services/whisper"

"$SCRIPT_DIR/sync-to-pi.sh" "$SSH_ALIAS" "$REMOTE_DIR"

ssh -o BatchMode=yes "$SSH_ALIAS" bash <<EOF
set -euo pipefail
REMOTE_DIR=${REMOTE_DIR@Q}
LEGACY_DIR=${LEGACY_DIR@Q}
mkdir -p "$REMOTE_DIR"

if [ ! -f "$REMOTE_DIR/whisper.env" ]; then
  if [ -f "$LEGACY_DIR/whisper.env" ]; then
    cp "$LEGACY_DIR/whisper.env" "$REMOTE_DIR/whisper.env"
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

if [ -f "$LEGACY_DIR/docker-compose.yml" ]; then
  (cd "$LEGACY_DIR" && docker compose down) || true
fi

cd "$REMOTE_DIR"
docker compose pull
docker compose up -d
docker compose ps
EOF
