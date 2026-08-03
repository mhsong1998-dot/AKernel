#!/bin/bash
set -euo pipefail

ulimit -n 32768

YR_CONFIG_TEMPLATE=/etc/yuanrong/config.toml.jinja
YR_CONFIG_PATH="${YR_RENDERED_CONFIG_PATH:-/run/yuanrong/config.toml}"
export YR_RUNTIME_BACKEND=sandboxd

role="${AKERNEL_ROLE:-}"
if [[ -z "$role" ]]; then
    if [[ "${AKS_LOCAL_MODE:-false}" == "true" ]]; then
        role=node-standalone
    else
        role=node-agent
    fi
    export AKERNEL_ROLE="$role"
fi

case "${role}" in
    node-agent)
        ;;
    node-standalone)
        export LITEBUS_DATA_KEY="${LITEBUS_DATA_KEY:-616B65726E656C732D6F70656E7975616E726F6E672D736B}"
        ;;
    *)
        echo "AKERNEL_ROLE must be node-agent or node-standalone" >&2
        exit 1
        ;;
esac

if [ ! -f "$YR_CONFIG_TEMPLATE" ]; then
    echo "YuanRong CLI config template does not exist under: ${YR_CONFIG_TEMPLATE}" >&2
    exit 1
fi

if [[ -n "${ENABLE_TRACE:-}" ]]; then
    export YR_TRACE_CONFIG_CONTENT="$(<"${TRACE_CONFIG_FILE:-/home/yuanrong/trace/trace_config.json}")"
fi

mkdir -p "$(dirname "$YR_CONFIG_PATH")"
yr config render \
    -t "$YR_CONFIG_TEMPLATE" \
    -o "$YR_CONFIG_PATH"

YR_CLI_ARGS=(
    yr --config "$YR_CONFIG_PATH" start
)
if [[ "$role" == "node-standalone" ]]; then
    YR_CLI_ARGS+=(--master)
fi
YR_CLI_ARGS+=(
    --block true
    --port-policy FIX
    --function-proxy-merge-process-enable
)

if [[ "${YR_CLI_DRY_RUN:-false}" == "true" ]]; then
    : "${YR_CLI_CAPTURE_FILE:?YR_CLI_CAPTURE_FILE is required when YR_CLI_DRY_RUN=true}"
    mkdir -p "$(dirname "$YR_CLI_CAPTURE_FILE")"
    printf '%s\0' "${YR_CLI_ARGS[@]}" > "$YR_CLI_CAPTURE_FILE"
    exit 0
fi

mkdir -p "${YR_LOG_PATH:-/home/yuanrong/logs}"
exec "${YR_CLI_ARGS[@]}"
