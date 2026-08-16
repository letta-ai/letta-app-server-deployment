#!/bin/sh
set -eu

port="${PORT:-4500}"
backend="${LETTA_BACKEND:-local}"
token_file="${LETTA_APP_SERVER_TOKEN_FILE:-/run/secrets/app-server-token}"

case "$backend" in
  local|cloud) ;;
  *)
    echo "LETTA_BACKEND must be 'local' or 'cloud'." >&2
    exit 1
    ;;
esac

if [ -n "${LETTA_APP_SERVER_TOKEN:-}" ]; then
  token_file="/tmp/letta-app-server-token"
  umask 077
  printf '%s' "$LETTA_APP_SERVER_TOKEN" > "$token_file"
fi

if [ ! -s "$token_file" ]; then
  echo "Set LETTA_APP_SERVER_TOKEN or mount a token at $token_file." >&2
  exit 1
fi

exec letta server \
  --backend "$backend" \
  --listen "ws://0.0.0.0:$port" \
  --ws-auth capability-token \
  --ws-token-file "$token_file"
