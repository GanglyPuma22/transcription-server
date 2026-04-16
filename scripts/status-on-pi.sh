#!/usr/bin/env bash
set -euo pipefail

# Show remote compose status plus the container restart policy.
#
# Usage:
#   ./scripts/status-on-pi.sh [ssh-alias] [remote-dir]
#
# Defaults:
#   ssh-alias  = video-server
#   remote-dir = /home/mmounier/services/transcription-server

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
