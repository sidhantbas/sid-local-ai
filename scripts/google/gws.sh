#!/usr/bin/env bash
# Run the Google Workspace CLI (gws) as one of the configured Google accounts.
# Each profile is named after the Gmail username and has its own config dir.
#
#   ./scripts/google/gws.sh <profile> <gws args...>
#   ./scripts/google/gws.sh sidhantbastola7 gmail +triage
set -euo pipefail

PROFILES=(sidhantbastola7 sibastola6ucl disisidstudio)
PROFILE_ROOT="${HOME}/.config/gws/profiles"

usage() {
  echo "usage: $0 <profile> <gws args...>" >&2
  echo "profiles: ${PROFILES[*]}" >&2
  exit 2
}

[ $# -ge 2 ] || usage
profile="$1"; shift
[[ " ${PROFILES[*]} " == *" ${profile} "* ]] || { echo "unknown profile: ${profile}" >&2; usage; }

export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="${PROFILE_ROOT}/${profile}"
mkdir -p "${GOOGLE_WORKSPACE_CLI_CONFIG_DIR}"
exec gws "$@"
