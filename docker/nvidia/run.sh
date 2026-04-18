#!/bin/bash
#
# Optional NVIDIA GPU-capable run script derived from hwdsl2/docker-whisper.
# Keeps the same basic server behavior, but allows WHISPER_DEVICE=cuda when this
# image is used on a host with Docker GPU support.

export PATH="/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }

check_port() {
  printf '%s' "$1" | tr -d '\n' | grep -Eq '^[0-9]+$' \
  && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

if [ -f /whisper.env ]; then
  # shellcheck disable=SC1091
  . /whisper.env
else
  echo "WARNING: /whisper.env was not mounted; falling back to defaults." >&2
  echo "WARNING: For the GPU path, copy whisper.nvidia.env.example to whisper.env before starting compose." >&2
fi

if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
  && [ -z "$KUBERNETES_SERVICE_HOST" ] \
  && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
  exiterr "This script ONLY runs in a container (e.g. Docker, Podman)."
fi

WHISPER_MODEL=$(nospaces "$WHISPER_MODEL")
WHISPER_MODEL=$(noquotes "$WHISPER_MODEL")
WHISPER_LANGUAGE=$(nospaces "$WHISPER_LANGUAGE")
WHISPER_LANGUAGE=$(noquotes "$WHISPER_LANGUAGE")
WHISPER_PORT=$(nospaces "$WHISPER_PORT")
WHISPER_PORT=$(noquotes "$WHISPER_PORT")
WHISPER_DEVICE=$(nospaces "$WHISPER_DEVICE")
WHISPER_DEVICE=$(noquotes "$WHISPER_DEVICE")
WHISPER_COMPUTE_TYPE=$(nospaces "$WHISPER_COMPUTE_TYPE")
WHISPER_COMPUTE_TYPE=$(noquotes "$WHISPER_COMPUTE_TYPE")
WHISPER_THREADS=$(nospaces "$WHISPER_THREADS")
WHISPER_THREADS=$(noquotes "$WHISPER_THREADS")
WHISPER_API_KEY=$(nospaces "$WHISPER_API_KEY")
WHISPER_API_KEY=$(noquotes "$WHISPER_API_KEY")
WHISPER_LOG_LEVEL=$(nospaces "$WHISPER_LOG_LEVEL")
WHISPER_LOG_LEVEL=$(noquotes "$WHISPER_LOG_LEVEL")
WHISPER_BEAM=$(nospaces "$WHISPER_BEAM")
WHISPER_BEAM=$(noquotes "$WHISPER_BEAM")
WHISPER_LOCAL_ONLY=$(nospaces "$WHISPER_LOCAL_ONLY")
WHISPER_LOCAL_ONLY=$(noquotes "$WHISPER_LOCAL_ONLY")

[ -z "$WHISPER_MODEL" ] && WHISPER_MODEL=base
[ -z "$WHISPER_LANGUAGE" ] && WHISPER_LANGUAGE=auto
[ -z "$WHISPER_PORT" ] && WHISPER_PORT=9000
[ -z "$WHISPER_DEVICE" ] && WHISPER_DEVICE=cpu
[ -z "$WHISPER_THREADS" ] && WHISPER_THREADS=2
[ -z "$WHISPER_LOG_LEVEL" ] && WHISPER_LOG_LEVEL=INFO
[ -z "$WHISPER_BEAM" ] && WHISPER_BEAM=5

if [ -z "$WHISPER_COMPUTE_TYPE" ]; then
  case "$WHISPER_DEVICE" in
    cuda) WHISPER_COMPUTE_TYPE=float16 ;;
    *) WHISPER_COMPUTE_TYPE=int8 ;;
  esac
fi

if ! check_port "$WHISPER_PORT"; then
  exiterr "WHISPER_PORT must be an integer between 1 and 65535."
fi

case "$WHISPER_MODEL" in
  tiny|tiny.en|base|base.en|small|small.en|medium|medium.en|\
  large-v1|large-v2|large-v3|large-v3-turbo|turbo) ;;
  *) exiterr "WHISPER_MODEL '$WHISPER_MODEL' is not recognized." ;;
esac

case "$WHISPER_DEVICE" in
  cpu|cuda) ;;
  *) exiterr "WHISPER_DEVICE must be one of: cpu, cuda." ;;
esac

case "$WHISPER_COMPUTE_TYPE" in
  int8|int8_float16|int8_float32|int16|float16|float32|bfloat16) ;;
  *) exiterr "WHISPER_COMPUTE_TYPE '$WHISPER_COMPUTE_TYPE' is not valid." ;;
esac

case "$WHISPER_LOG_LEVEL" in
  DEBUG|INFO|WARNING|ERROR|CRITICAL) ;;
  *) exiterr "WHISPER_LOG_LEVEL must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL." ;;
esac

if ! printf '%s' "$WHISPER_THREADS" | grep -Eq '^[1-9][0-9]*$'; then
  exiterr "WHISPER_THREADS must be a positive integer."
fi

if ! printf '%s' "$WHISPER_BEAM" | grep -Eq '^[1-9][0-9]*$'; then
  exiterr "WHISPER_BEAM must be a positive integer (e.g. 1, 5)."
fi

mkdir -p /var/lib/whisper /run/whisper-temp

public_ip=$(curl -s --max-time 10 http://ipv4.icanhazip.com 2>/dev/null || true)
check_ip "$public_ip" || public_ip=$(curl -s --max-time 10 http://ip1.dynupdate.no-ip.com 2>/dev/null || true)
if check_ip "$public_ip"; then
  server_addr="$public_ip"
else
  server_addr="<server ip>"
fi

export WHISPER_MODEL
export WHISPER_LANGUAGE
export WHISPER_PORT
export WHISPER_DEVICE
export WHISPER_COMPUTE_TYPE
export WHISPER_THREADS
export WHISPER_API_KEY
export WHISPER_LOG_LEVEL
export WHISPER_BEAM
export WHISPER_LOCAL_ONLY
export HF_HOME=/var/lib/whisper

printf '%s' "$WHISPER_PORT"  > /var/lib/whisper/.port
printf '%s' "$WHISPER_MODEL" > /var/lib/whisper/.model
printf '%s' "$server_addr"   > /var/lib/whisper/.server_addr

echo
echo "Optional Whisper GPU image"
echo "  Model:    $WHISPER_MODEL"
echo "  Device:   $WHISPER_DEVICE ($WHISPER_COMPUTE_TYPE)"
echo "  Language: $WHISPER_LANGUAGE"
echo "  Port:     $WHISPER_PORT"
echo "  Beam:     $WHISPER_BEAM"
if [ "$WHISPER_DEVICE" != "cuda" ]; then
  echo "WARNING: GPU mode is not active (WHISPER_DEVICE=$WHISPER_DEVICE)." >&2
  echo "WARNING: Check whisper.env and use whisper.nvidia.env.example for the optional GPU path." >&2
fi
echo

cleanup() {
  echo
  echo "Stopping Whisper server..."
  kill "${WHISPER_PID:-}" 2>/dev/null
  wait "${WHISPER_PID:-}" 2>/dev/null
  exit 0
}
trap cleanup INT TERM

cd /opt/src && python3 /opt/src/api_server.py &
WHISPER_PID=$!

wait_for_server() {
  local i=0
  while [ "$i" -lt 300 ]; do
    if ! kill -0 "$WHISPER_PID" 2>/dev/null; then
      return 1
    fi
    if curl -sf "http://127.0.0.1:${WHISPER_PORT}/health" >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  return 1
}

if ! wait_for_server; then
  echo
  echo "Whisper server failed to start. Recent logs:" >&2
  wait "$WHISPER_PID"
  exit 1
fi

echo "Whisper speech-to-text server is ready"
wait "$WHISPER_PID"
