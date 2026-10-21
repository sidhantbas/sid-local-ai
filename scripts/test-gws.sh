#!/usr/bin/env bash
# Read-only smoke test of Gmail, Calendar and Tasks for every gws profile
# (or only the profiles given as arguments).
set -uo pipefail
cd "$(dirname "$0")/.."

profiles=("$@")
[ ${#profiles[@]} -gt 0 ] || profiles=(sidhantbastola7 sibastola6ucl disisidstudio)

failed=0
for p in "${profiles[@]}"; do
  echo "== ${p} =="
  for check in "gmail +triage" "calendar +agenda" "tasks tasklists list"; do
    # shellcheck disable=SC2086
    if ./scripts/gws.sh "${p}" ${check} >/dev/null 2>&1; then
      echo "  ok    ${check}"
    else
      echo "  FAIL  ${check}"
      failed=1
    fi
  done
done
exit "${failed}"
