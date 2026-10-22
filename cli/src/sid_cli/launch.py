"""Open a full-screen Ghostty window in the hacker theme, running the boot sequence."""

import shutil
import subprocess
from pathlib import Path

from .paths import ASSETS


def launch_terminal() -> None:
    sid = shutil.which("sid") or str(Path.home() / ".local" / "bin" / "sid")
    subprocess.run(
        [
            "open", "-na", "Ghostty.app", "--args",
            f"--config-file={ASSETS / 'ghostty-hacker.conf'}",
            # after the CLI exits, stay in a login shell in the same styled window
            f"--command=/bin/zsh -lc '{sid}; exec /bin/zsh -l'",
        ],
        check=False,
    )
