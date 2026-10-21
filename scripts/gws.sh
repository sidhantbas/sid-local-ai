#!/usr/bin/env bash
# Run the Google Workspace CLI (gws) as one of the configured Google accounts.
# Each profile is named after the Gmail username and has its own config dir.
#
#   ./scripts/gws.sh <profile> <gws args...>
#   ./scripts/gws.sh sidhantbastola7 gmail +triage
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
# Don't bill requests to the sid-local-ai Cloud project: only the project owner
# has serviceusage permission on it, so other accounts get 403 on Tasks otherwise.
export GOOGLE_WORKSPACE_PROJECT_ID=""
mkdir -p "${GOOGLE_WORKSPACE_CLI_CONFIG_DIR}"
exec gws "$@"
