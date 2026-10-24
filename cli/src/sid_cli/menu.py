"""Main menu: one key per action, all backed by the repo's scripts."""

import subprocess

from rich.console import Console
from rich.text import Text

from .boot import DARK, DIM, GREEN, show_status
from .paths import SCRIPTS
from .status import run_all

# Hermes starts before the model so start-strata.sh can point it at Strata
START_ORDER = ["start-colima.sh", "start-open-webui.sh", "start-hermes.sh", "start-strata.sh"]
STOP_ORDER = ["stop-hermes.sh", "stop-open-webui.sh", "stop-strata.sh", "stop-unsloth.sh"]

# one-shot Hermes run: skill preloaded, terminal tool only, low reasoning (~50 s instead of
# 10+ min of the full toolset, where -q mode blocks execute_code and the agent wanders)
CHECK_MAIL = [
    "docker", "exec", "-it", "hermes", "hermes", "chat", "--oneshot",
    "-s", "google-accounts", "-t", "terminal", "--reasoning", "low",
    "-q", "Check unread email in all my Google accounts (gacct all gmail search is:unread --max 20). "
    "List each unread email as one line: account, sender, subject, and a few words on what it needs.",
]

# HumanLoop: interactive Hermes chat with the life-model skill and the Google accounts
HUMANLOOP = [
    "docker", "exec", "-it", "hermes", "hermes", "chat",
    "-s", "humanloop", "-s", "google-accounts", "-t", "terminal",
]

ITEMS = [
    ("1", "start stack", "colima -> open-webui -> hermes -> strata"),
    ("2", "talk to hermes", "agent chat on the local model"),
    ("3", "open webui", "http://localhost:3000"),
    ("4", "hermes dashboard", "http://localhost:9119"),
    ("5", "status", "re-run live checks"),
    ("6", "gws check", "gmail / calendar / tasks, 3 profiles"),
    ("7", "shut down stack", "hermes, open-webui, strata/unsloth (frees ~25-33 GB)"),
    ("8", "check mail", "hermes reads unread gmail, all accounts"),
    ("9", "humanloop", "life model + onboarding (say: start onboarding)"),
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
        elif choice == "8":
            subprocess.call(CHECK_MAIL)
        elif choice == "9":
            subprocess.call(HUMANLOOP)
        else:
            console.print(f"  ?? unknown command: {choice}", style="red")
        console.print()
