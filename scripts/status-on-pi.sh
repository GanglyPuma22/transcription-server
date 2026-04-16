#!/usr/bin/env bash
set -euo pipefail

SSH_ALIAS="${1:-video-server}"
REMOTE_DIR="${2:-/home/mmounier/services/transcription-server}"

ssh -o BatchMode=yes "$SSH_ALIAS" bash <<EOF
set -euo pipefail
cd ${REMOTE_DIR@Q}
docker compose ps
container_id="\$(docker compose ps -q whisper)"
echo
printf 'restart-policy=%s\n' "\$(docker inspect -f '{{ .HostConfig.RestartPolicy.Name }}' "\$container_id")"
EOF
