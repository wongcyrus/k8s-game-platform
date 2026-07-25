#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_SAMCONFIG="${SCRIPT_DIR}/samconfig.toml"
ROOT_ENV_FILE="${SCRIPT_DIR}/.env"
TARGET_SAMCONFIG="${SCRIPT_DIR}/k8s-grader/k8s-grader-api/samconfig.toml"
GRADER_UNDEPLOY_SCRIPT="${SCRIPT_DIR}/k8s-grader/k8s-grader-api/undeploy.sh"

if [ ! -f "$GRADER_UNDEPLOY_SCRIPT" ]; then
    echo "Undeploy script not found: $GRADER_UNDEPLOY_SCRIPT" >&2
    exit 1
fi

if [ -f "$ROOT_ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ROOT_ENV_FILE"
    set +a
fi

if [ -f "$ROOT_SAMCONFIG" ]; then
    cp "$ROOT_SAMCONFIG" "$TARGET_SAMCONFIG"
fi

cd "${SCRIPT_DIR}/k8s-grader/k8s-grader-api"
exec bash "$GRADER_UNDEPLOY_SCRIPT" "$@"
