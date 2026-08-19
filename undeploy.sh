#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_ENV_FILE="${SCRIPT_DIR}/.env"
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

DEPLOY_ENV="${ENV:-${DEPLOY_ENV:-dev}}"
case "$DEPLOY_ENV" in
    dev|default)
        export SAM_CONFIG_FILE="${SAM_CONFIG_FILE:-${SCRIPT_DIR}/k8s-grader/k8s-grader-api/samconfig.dev.toml}"
        ;;
    prod)
        export SAM_CONFIG_FILE="${SAM_CONFIG_FILE:-${SCRIPT_DIR}/k8s-grader/k8s-grader-api/samconfig.prod.toml}"
        ;;
    *)
        echo "Unsupported deploy environment: ${DEPLOY_ENV}. Use dev or prod." >&2
        exit 1
        ;;
esac
export SAM_CONFIG_ENV="${SAM_CONFIG_ENV:-default}"

cd "${SCRIPT_DIR}/k8s-grader/k8s-grader-api"
exec bash "$GRADER_UNDEPLOY_SCRIPT" "$@"
