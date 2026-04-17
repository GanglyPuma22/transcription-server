#!/usr/bin/env bash
set -euo pipefail

# Transcribe a local audio file by posting it to the self-hosted transcription
# server.
#
# Usage:
#   ./scripts/transcribe-file-via-server.sh <audio-file>
#
# This script is safe to use as the default client helper for both short and
# long files. The default timeout behavior is duration-aware:
# - if STT_PI_TIMEOUT is set, that exact timeout is used
# - otherwise timeout = ceil(audio_duration_seconds) + STT_PI_TIMEOUT_PAD
# - and the result is clamped to at least STT_PI_TIMEOUT_MIN
#
# Resolution order:
# 1. Use STT_PI_URL / STT_PI_API_KEY when explicitly provided.
# 2. Otherwise, if this repo has a local whisper.env, use the local deployment.
# 3. Otherwise, fall back to SSH-based discovery for the remote video-server path.
#
# Env vars:
#   STT_PI_SSH_ALIAS       SSH host alias to inspect for auto-discovery (default: video-server)
#   STT_PI_URL             Override full base URL, e.g. http://10.0.0.45:9000
#   STT_PI_API_KEY         Override bearer token instead of fetching from the Pi over SSH
#   STT_PI_LANGUAGE        Default: en
#   STT_PI_MODEL           Default: whisper-1
#   STT_PI_TIMEOUT         Exact curl timeout seconds override
#   STT_PI_TIMEOUT_PAD     Added padding above audio duration when timeout is auto-derived (default: 420)
#   STT_PI_TIMEOUT_MIN     Minimum timeout for auto-derived mode (default: 1200)
#   STT_PI_READY_WAIT      Seconds to wait for /health before uploading when using a local URL (default: 120)
#   STT_PI_DEBUG           1 to print endpoint / temp path / duration / timeout / timing to stderr

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <audio-file>" >&2
  exit 1
fi

AUDIO_FILE="$1"
if [[ ! -f "$AUDIO_FILE" ]]; then
  echo "ERROR: file not found: $AUDIO_FILE" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_COMPOSE_ENV="$APP_DIR/.env"
LOCAL_WHISPER_ENV="$APP_DIR/whisper.env"

SSH_ALIAS="${STT_PI_SSH_ALIAS:-video-server}"
LANGUAGE="${STT_PI_LANGUAGE:-en}"
MODEL="${STT_PI_MODEL:-whisper-1}"
TIMEOUT_OVERRIDE="${STT_PI_TIMEOUT:-}"
TIMEOUT_PAD="${STT_PI_TIMEOUT_PAD:-420}"
TIMEOUT_MIN="${STT_PI_TIMEOUT_MIN:-1200}"
DEBUG="${STT_PI_DEBUG:-0}"
READY_WAIT="${STT_PI_READY_WAIT:-120}"

require_binary() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $name" >&2
    exit 10
  fi
}

check_dependencies() {
  require_binary curl
  require_binary ffmpeg
  require_binary ffprobe
  require_binary python3

  if [[ -z "${STT_PI_URL:-}" || -z "${STT_PI_API_KEY:-}" ]]; then
    if ! has_local_runtime_config; then
      require_binary ssh
    fi
  fi
}

read_env_value() {
  local file="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$file" 2>/dev/null | tail -n 1
}

has_local_runtime_config() {
  [[ -f "$LOCAL_WHISPER_ENV" ]]
}

local_base_url() {
  local bind_addr host_port client_host
  bind_addr="$(read_env_value "$LOCAL_COMPOSE_ENV" WHISPER_BIND_ADDR)"
  host_port="$(read_env_value "$LOCAL_COMPOSE_ENV" WHISPER_HOST_PORT)"

  [[ -z "$bind_addr" ]] && bind_addr="127.0.0.1"
  [[ -z "$host_port" ]] && host_port="9000"

  case "$bind_addr" in
    0.0.0.0|::|"") client_host="127.0.0.1" ;;
    *) client_host="$bind_addr" ;;
  esac

  printf 'http://%s:%s\n' "$client_host" "$host_port"
}

resolve_url() {
  if [[ -n "${STT_PI_URL:-}" ]]; then
    printf '%s\n' "$STT_PI_URL"
    return
  fi

  if has_local_runtime_config; then
    local_base_url
    return
  fi

  local host
  if ! host="$(ssh -G "$SSH_ALIAS" 2>/dev/null | awk '/^hostname /{print $2; exit}')"; then
    echo "ERROR: failed to inspect SSH config for alias: $SSH_ALIAS (set STT_PI_URL or fix SSH access/config)" >&2
    exit 3
  fi
  if [[ -z "$host" ]]; then
    echo "ERROR: could not resolve SSH host for alias: $SSH_ALIAS (set STT_PI_URL or define the SSH alias)" >&2
    exit 3
  fi
  printf 'http://%s:9000\n' "$host"
}

resolve_key() {
  if [[ -n "${STT_PI_API_KEY:-}" ]]; then
    printf '%s\n' "$STT_PI_API_KEY"
    return
  fi

  local key
  if has_local_runtime_config; then
    key="$(read_env_value "$LOCAL_WHISPER_ENV" WHISPER_API_KEY)"
    if [[ -z "$key" ]]; then
      echo "ERROR: local whisper.env exists but WHISPER_API_KEY is missing (set STT_PI_API_KEY or update $LOCAL_WHISPER_ENV)" >&2
      exit 4
    fi
    printf '%s\n' "$key"
    return
  fi

  if ! key="$(ssh -o BatchMode=yes "$SSH_ALIAS" "sed -n 's/^WHISPER_API_KEY=//p' /home/mmounier/services/transcription-server/whisper.env 2>/dev/null || sed -n 's/^WHISPER_API_KEY=//p' /home/mmounier/services/whisper/whisper.env 2>/dev/null")"; then
    echo "ERROR: failed to fetch STT Pi API key over SSH (set STT_PI_API_KEY or fix SSH access to $SSH_ALIAS)" >&2
    exit 4
  fi
  if [[ -z "$key" ]]; then
    echo "ERROR: could not resolve STT Pi API key (set STT_PI_API_KEY or fix SSH access to $SSH_ALIAS)" >&2
    exit 4
  fi
  printf '%s\n' "$key"
}

audio_duration_seconds() {
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_FILE" 2>/dev/null || true
}

compute_timeout() {
  if [[ -n "$TIMEOUT_OVERRIDE" ]]; then
    printf '%s\n' "$TIMEOUT_OVERRIDE"
    return
  fi

  local duration_raw
  duration_raw="$(audio_duration_seconds)"

  python3 - <<PY
import math

duration_raw = ${duration_raw@Q}
pad = int(${TIMEOUT_PAD@Q})
minimum = int(${TIMEOUT_MIN@Q})

try:
    duration = math.ceil(float(duration_raw))
except Exception:
    duration = 0

print(max(minimum, duration + pad))
PY
}

is_local_base_url() {
  case "$1" in
    http://127.0.0.1:*|http://localhost:*|http://[::1]:*) return 0 ;;
    *) return 1 ;;
  esac
}

wait_for_local_server() {
  local base_url="$1"
  local deadline health_url
  health_url="$base_url/health"
  deadline=$((SECONDS + READY_WAIT))

  while (( SECONDS < deadline )); do
    if curl -fsS --max-time 2 "$health_url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "ERROR: local transcription server did not become ready at $health_url within ${READY_WAIT}s" >&2
  exit 11
}

check_dependencies

BASE_URL="$(resolve_url)"
if is_local_base_url "$BASE_URL"; then
  wait_for_local_server "$BASE_URL"
fi
API_KEY="$(resolve_key)"
TIMEOUT="$(compute_timeout)"
AUDIO_DURATION_RAW="$(audio_duration_seconds)"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
PAYLOAD="$WORK_DIR/payload.wav"
CURL_CONFIG="$WORK_DIR/curl.conf"
ffmpeg -hide_banner -loglevel error -y -i "$AUDIO_FILE" -ac 1 -ar 16000 "$PAYLOAD"

START_TS="$(python3 - <<'PY'
import time
print(time.time())
PY
)"

RESPONSE_FILE="$WORK_DIR/response.txt"
printf 'header = "Authorization: Bearer %s"\n' "$API_KEY" > "$CURL_CONFIG"
chmod 600 "$CURL_CONFIG"
curl -sS --fail-with-body -m "$TIMEOUT" --config "$CURL_CONFIG" \
  -F file=@"$PAYLOAD" \
  -F model="$MODEL" \
  -F language="$LANGUAGE" \
  -F response_format=text \
  "$BASE_URL/v1/audio/transcriptions" > "$RESPONSE_FILE"

END_TS="$(python3 - <<'PY'
import time
print(time.time())
PY
)"

if [[ "$DEBUG" == "1" ]]; then
  python3 - <<PY >&2
start = float(${START_TS@Q})
end = float(${END_TS@Q})
print(f"[transcribe-file-via-server] endpoint={${BASE_URL@Q}} elapsed_sec={end-start:.2f}")
print(f"[transcribe-file-via-server] audio_duration_sec={${AUDIO_DURATION_RAW@Q}} timeout_sec={${TIMEOUT@Q}}")
print(f"[transcribe-file-via-server] payload={${PAYLOAD@Q}}")
PY
fi

cat "$RESPONSE_FILE"
