#!/usr/bin/env bash
set -euo pipefail

# Canonical local client entrypoint for sending an audio file to the
# transcription server.
#
# Usage:
#   ./scripts/transcribe-file.sh <audio-file>
#
# This delegates to the duration-aware implementation so short and long files
# share the same default behavior. Use STT_PI_TIMEOUT only when you explicitly
# want a fixed timeout instead of the duration-based default.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/transcribe-file-via-server.sh" "$@"
