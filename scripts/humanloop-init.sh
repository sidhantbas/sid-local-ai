#!/usr/bin/env bash
# Create HumanLoop's life model in ~/humanloop (mounted into Hermes as /opt/data/humanloop).
# Only creates files that do not exist yet, so it is safe to run again; Sid's data is never
# overwritten. The data stays outside the repo. Format and rules: hermes/skills/humanloop/.
#
#   ./scripts/humanloop-init.sh
set -euo pipefail

DIR="${HUMANLOOP_DIR:-${HOME}/humanloop}"
TODAY="$(date +%F)"
mkdir -p "${DIR}/model"
chmod 700 "${DIR}"

new() {  # new <path> <content>: write only if missing
  if [ -e "${DIR}/$1" ]; then
    echo "  kept     $1"
  else
    printf '%s\n' "$2" >"${DIR}/$1"
    echo "  created  $1"
  fi
}

model() {  # model <file> <title> <what it holds> <sections...>
  local file="$1" title="$2" what="$3"; shift 3
  local body="# ${title}"$'\n\n'"${what}"$'\n'
  for section in "$@"; do body+=$'\n'"## ${section}"$'\n'; done
  body+=$'\n'"## Retired"
  new "model/${file}" "${body}"
}

echo "HumanLoop life model in ${DIR}"
new README.md "# HumanLoop data

Sid's life model, kept by HumanLoop (Hermes + the \`humanloop\` skill). Edit freely.
One fact per line: \`- [verified|declared|inferred] text · src: where · id: x-001\`.
Created ${TODAY}. Not in git."
model goals.md "Goals" "Long-term ambitions, months to years." "This year" "Longer term"
model projects.md "Projects" "Active projects, the goal each serves, status and next step." "Active" "Paused"
model commitments.md "Commitments" "Deadlines, classes, meetings and recurring obligations." "Upcoming" "Recurring"
model routines.md "Routines" "Sleep, focus hours, energy over the day, fixed weekly blocks." "Daily" "Weekly"
model preferences.md "Preferences" "Who Sid is now, and how HumanLoop should behave." "Basics" "Accounts" "How HumanLoop works"
new model/proposed.md "# Proposed

Changes waiting for Sid's approval, newest first."
new onboarding.md "# Onboarding

- [ ] 1 Basics
- [ ] 2 Goals
- [ ] 3 Projects
- [ ] 4 Commitments
- [ ] 5 Routines
- [ ] 6 How HumanLoop should work"
new inbox.md "# Inbox

Quick captures from the phone, newest day last; sorted items get a ✓."
new decisions.md "# Decisions

Important decisions and why, newest first."
