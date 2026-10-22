"""Locations of the repo, its scripts and its .env."""

import os
from pathlib import Path

REPO = Path(os.environ.get("SID_LOCAL_AI_HOME", Path.home() / "sid-local-ai")).expanduser()
SCRIPTS = REPO / "scripts"
ASSETS = REPO / "cli" / "assets"
CONFIG_DIR = Path.home() / ".config" / "sid-cli"


def load_env() -> dict[str, str]:
    """Read KEY=VALUE lines from the repo's .env (never printed anywhere)."""
    env: dict[str, str] = {}
    path = REPO / ".env"
    if not path.exists():
        return env
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, value = line.partition("=")
            env[key.strip()] = value.strip()
    return env
