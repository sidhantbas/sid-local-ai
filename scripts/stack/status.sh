#!/usr/bin/env bash
# Show the state of each part of the local AI stack.
set -uo pipefail

echo "== Colima =="
colima list

echo
echo "== Docker context: $(docker context show) =="
if colima status >/dev/null 2>&1; then
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
fi

echo
echo "== Unsloth Studio (port ${UNSLOTH_PORT:-8890}) =="
if curl -fsS "http://127.0.0.1:${UNSLOTH_PORT:-8890}/api/health" >/dev/null 2>&1; then
  echo "running"
else
  echo "not running"
fi

echo
echo "== Strata (port ${STRATA_PORT:-8080}) =="
if curl -fsS "http://127.0.0.1:${STRATA_PORT:-8080}/v1/models" >/dev/null 2>&1; then
  echo "running"
else
  echo "not running"
fi
