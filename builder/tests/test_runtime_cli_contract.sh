#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOTSTRAP="${ROOT}/builder/scripts/yr_node_bootstrap.sh"
TEMPLATE="${ROOT}/builder/config/yr/config.toml.jinja"
DOCKERFILE="${ROOT}/builder/node.Dockerfile"

grep -Fq 'yr config render' "${BOOTSTRAP}"
grep -Fq '    yr --config "$YR_CONFIG_PATH" start' "${BOOTSTRAP}"
! grep -Fq '/opt/openyuanrong/bin/yr' "${BOOTSTRAP}"
grep -Fq 'openyuanrong_core-0.7.0%2B12194b7d189e-py3-none-manylinux_2_31_x86_64.whl' "${DOCKERFILE}"
grep -Fq 'YR_CORE_WHEEL_SHA256=65f1968b2dc04a200d93d6cfa2bca5601723d1197ac204edc540cafcbb784a30' "${DOCKERFILE}"
grep -Fq 'pip3 install' "${DOCKERFILE}"
grep -Fq -- '--break-system-packages' "${DOCKERFILE}"
! grep -Fq 'python3 -m venv /opt/openyuanrong' "${DOCKERFILE}"
! grep -Fq 'ENV PATH=/opt/openyuanrong/bin:' "${DOCKERFILE}"

awk '
    /^\[values\.meta_service\]$/ { in_meta = 1 }
    in_meta && /^ip = "\{\{ ip \}\}"$/ { found = 1 }
    in_meta && /^\[/ && $0 != "[values.meta_service]" { exit }
    END { exit(found ? 0 : 1) }
' "${TEMPLATE}"

echo "runtime CLI contract checks passed"
