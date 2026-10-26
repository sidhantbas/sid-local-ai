#!/usr/bin/env bash
# Copy this repo's Hermes skills (hermes/skills/<name>/) into the running Hermes container,
# under /opt/data/skills/productivity/. Run again after editing a skill.
#
#   ./scripts/setup/install-hermes-skills.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

# -u hermes keeps the files owned by Hermes; COPYFILE_DISABLE / --no-mac-metadata stop macOS tar
# adding ._* resource files and xattr headers
COPYFILE_DISABLE=1 tar --no-mac-metadata --no-xattrs -C hermes/skills -cf - . | docker exec -i -u hermes hermes tar -C /opt/data/skills/productivity -xf -
for skill in hermes/skills/*/; do
  echo "Installed Hermes skill: $(basename "${skill}")"
done
