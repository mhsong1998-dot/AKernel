#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="${ROOT}/deploy/akernel/charts/core"
MANIFEST="$(mktemp)"
trap 'rm -f "${MANIFEST}"' EXIT

helm template akernel-core "${CHART}" -n akernel-test \
    --set image.repository=swr.cn-north-4.myhuaweicloud.com/openyuanrong/cluster-all-in-one \
    --set image.tag=c01eb8f-system-pip-20260803155000 \
    --set node.image.repository=swr.cn-north-4.myhuaweicloud.com/openyuanrong/node-all-in-one \
    --set node.image.tag=c01eb8f-system-pip-20260803155000 \
    > "${MANIFEST}"

python3 - "${MANIFEST}" <<'PY'
import sys
from pathlib import Path

import yaml

documents = yaml.safe_load_all(Path(sys.argv[1]).read_text())
targets = {
    ("StatefulSet", "akernel-master"): ("tcpSocket", 22770),
    ("Deployment", "akernel-frontend"): ("httpGet", 8888),
}

for document in documents:
    if not document:
        continue
    key = (document.get("kind"), document.get("metadata", {}).get("name"))
    if key not in targets:
        continue
    expected_type, expected_port = targets[key]
    containers = document.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    assert containers, f"{key} has no containers"
    probe = containers[0].get("startupProbe")
    assert probe, f"{key} is missing startupProbe"
    assert probe.get(expected_type), f"{key} startupProbe must use {expected_type}"
    if expected_type == "tcpSocket":
        assert probe[expected_type]["port"] == expected_port, key
    else:
        assert probe[expected_type]["port"] == expected_port, key
        assert probe[expected_type]["path"] == "/healthz", key
        assert probe[expected_type]["scheme"] == "HTTPS", key
    assert probe.get("periodSeconds") == 10, key
    assert probe.get("failureThreshold", 0) * probe["periodSeconds"] >= 120, key

print("startup probe contract passed")
PY
