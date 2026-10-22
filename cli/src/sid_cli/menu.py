"""Main menu: one key per action, all backed by the repo's scripts."""

import subprocess

from rich.console import Console
from rich.text import Text

from .boot import DARK, DIM, GREEN, show_status
from .paths import SCRIPTS
from .status import run_all

START_ORDER = ["start-unsloth.sh", "start-colima.sh", "start-open-webui.sh", "start-hermes.sh"]
STOP_ORDER = ["stop-hermes.sh", "stop-open-webui.sh", "stop-unsloth.sh"]

ITEMS = [
    ("1", "start stack", "unsloth -> colima -> open-webui -> hermes"),
    ("2", "talk to hermes", "agent chat on local qwen"),
    ("3", "open webui", "http://localhost:3000"),
    ("4", "hermes dashboard", "http://localhost:9119"),
    ("5", "status", "re-run live checks"),
    ("6", "gws check", "gmail / calendar / tasks, 3 profiles"),
    ("7", "shut down stack", "hermes, open-webui, unsloth (frees ~24 GB)"),
    ("q", "exit to shell", ""),
]


def run_scripts(console: Console, names: list[str]) -> None:
    for name in names:
        console.print(f"  >> {name}", style=f"bold {GREEN}")
        proc = subprocess.Popen([str(SCRIPTS / name)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in proc.stdout or []:
            console.print(f"     {line.rstrip()}", style=DIM, highlight=False, markup=False)
        if proc.wait() != 0:
            console.print(f"  !! {name} failed (exit {proc.returncode})", style="bold red")
            return


def show_menu(console: Console) -> None:
    console.print(Text("  ── commands " + "─" * 46, style=DARK))
    for key, label, hint in ITEMS:
        line = Text("   ")
        line.append(f"[{key}]", style=f"bold {GREEN}")
        line.append(f" {label:<18}", style=GREEN)
        line.append(hint, style=DIM)
        console.print(line)
    console.print(Text("  " + "─" * 58, style=DARK))


def loop(console: Console) -> None:
    while True:
        show_menu(console)
        choice = console.input(Text("  sid@local-ai:~$ ", style=f"bold {GREEN}")).strip().lower()
        console.print()
        if choice in ("q", "quit", "exit"):
            console.print("  > link closed.", style=DIM)
            return
        if choice == "1":
            run_scripts(console, START_ORDER)
        elif choice == "2":
            subprocess.call(["docker", "exec", "-it", "hermes", "hermes", "chat"])
        elif choice == "3":
            subprocess.call(["open", "http://localhost:3000"])
        elif choice == "4":
            subprocess.call(["open", "http://localhost:9119"])
        elif choice == "5":
            show_status(console, run_all())
        elif choice == "6":
            run_scripts(console, ["test-gws.sh"])
        elif choice == "7":
            run_scripts(console, STOP_ORDER)
        else:
            console.print(f"  ?? unknown command: {choice}", style="red")
        console.print()
