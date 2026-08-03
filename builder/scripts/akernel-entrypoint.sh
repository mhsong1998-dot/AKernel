#!/bin/bash

# Copyright (c) 2026 Ant Group Corporation.
#
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

role="${AKERNEL_ROLE:-}"

if [ -z "${role}" ] && [ "$#" -gt 0 ]; then
    case "$1" in
        master|master-core|frontend|node|standalone|cluster-master|cluster-master-core|cluster-frontend|node-agent|node-standalone)
            role="$1"
            shift
            ;;
    esac
fi

if [ -z "${role}" ]; then
    if [ "${AKS_LOCAL_MODE:-}" = "true" ]; then
        role="node-standalone"
    else
        echo "AKERNEL_ROLE is required: cluster-master, cluster-master-core, cluster-frontend, node-agent, or node-standalone" >&2
        exit 1
    fi
fi

case "${role}" in
    master) role=cluster-master ;;
    master-core) role=cluster-master-core ;;
    frontend) role=cluster-frontend ;;
    node) role=node-agent ;;
    standalone) role=node-standalone ;;
    cluster-master|cluster-master-core|cluster-frontend|node-agent|node-standalone)
        ;;
    *)
        echo "unsupported AKERNEL_ROLE: ${role}; expected cluster-master, cluster-master-core, cluster-frontend, node-agent, or node-standalone" >&2
        exit 1
        ;;
esac
export AKERNEL_ROLE="$role"

case "$role" in
    cluster-master|cluster-master-core|cluster-frontend)
        /usr/local/bin/ensure-component-cert
        exec /bin/bash /home/yuanrong/entrypoint.sh "$@"
        ;;
    node-agent)
        /bin/bash /root/prepare_node.sh
        exec /usr/sbin/init "$@"
        ;;
    node-standalone)
        /usr/local/bin/ensure-component-cert
        exec /usr/sbin/init "$@"
        ;;
esac
