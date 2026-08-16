#!/bin/sh
set -eu

exec letta server --env-name "${ENV_NAME:-cloud}" --debug
