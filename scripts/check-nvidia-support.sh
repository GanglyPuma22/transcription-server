#!/usr/bin/env bash
set -euo pipefail

# Quick host-side check for the optional NVIDIA GPU path.
#
# Usage:
#   ./scripts/check-nvidia-support.sh
#
# This checks:
# - nvidia-smi exists on the host
# - Docker is reachable
# - Docker can see the GPU through a tiny CUDA container

require_binary() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $name" >&2
    exit 1
  fi
}

require_binary docker
require_binary nvidia-smi

echo "== Host GPU =="
nvidia-smi

echo
echo "== Docker GPU smoke test =="
docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi

echo
echo "NVIDIA Docker GPU path looks available."
