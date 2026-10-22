"""Boot sequence: matrix rain, glitch banner, then the live status typed out line by line."""

import os
import random
import sys
import time
from concurrent.futures import Future, ThreadPoolExecutor

from rich.console import Console
from rich.live import Live
from rich.text import Text

from .status import Check, run_all

GREEN = "#00ff41"
DIM = "#008f11"
DARK = "#003b00"

BANNER = r"""
 ███████╗██╗██████╗     ██╗██╗    ██╗      ██████╗  ██████╗ █████╗ ██╗          █████╗ ██╗
 ██╔════╝██║██╔══██╗   ██╔╝██╔╝   ██║     ██╔═══██╗██╔════╝██╔══██╗██║         ██╔══██╗██║
 ███████╗██║██║  ██║  ██╔╝██╔╝    ██║     ██║   ██║██║     ███████║██║   █████╗███████║██║
 ╚════██║██║██║  ██║ ██╔╝██╔╝     ██║     ██║   ██║██║     ██╔══██║██║   ╚════╝██╔══██║██║
 ███████║██║██████╔╝██╔╝██╔╝      ███████╗╚██████╔╝╚██████╗██║  ██║███████╗    ██║  ██║██║
 ╚══════╝╚═╝╚═════╝ ╚═╝ ╚═╝       ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝
"""
SMALL_BANNER = "SID // LOCAL-AI"

GLYPHS = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789"
NOISE = "!<>-_\\/[]{}—=+*^?#░▒▓"


def animations_enabled() -> bool:
    return sys.stdout.isatty() and not os.environ.get("SID_NO_ANIM")


def matrix_rain(console: Console, seconds: float = 1.8, until: Future | None = None) -> None:
    """Falling green glyphs; runs at least `seconds`, and keeps going while `until` is pending."""
    width, height = console.size.width, console.size.height - 1
    drops = [random.randint(-height, 0) for _ in range(width)]
    start = time.monotonic()
    with Live(console=console, refresh_per_second=24, transient=True) as live:
        while time.monotonic() - start < seconds or (until is not None and not until.done()):
            grid = [[" "] * width for _ in range(height)]
            styles = [[""] * width for _ in range(height)]
            for x in range(0, width, 2):
                head = drops[x]
                for trail in range(12):
                    y = head - trail
                    if 0 <= y < height:
                        grid[y][x] = random.choice(GLYPHS)
                        styles[y][x] = "bold #d0ffd0" if trail == 0 else (GREEN if trail < 4 else DIM if trail < 8 else DARK)
                drops[x] = head + 1 if head - 12 < height else random.randint(-height // 2, 0)
            frame = Text()
            for y in range(height):
                for x in range(width):
                    frame.append(grid[y][x], style=styles[y][x] or None)
                frame.append("\n")
            live.update(frame)
            time.sleep(1 / 24)
            if time.monotonic() - start > 12:  # never hang the boot on a slow check
                break


def glitch_banner(console: Console) -> None:
    art = BANNER if console.size.width >= 92 else f"\n  {SMALL_BANNER}\n"
    if not animations_enabled():
        console.print(art, style=f"bold {GREEN}", highlight=False)
        return
    with Live(console=console, refresh_per_second=30) as live:
        for step in range(14):
            corrupt = max(0.0, 0.35 - step * 0.03)
            glitched = "".join(
                random.choice(NOISE) if ch not in " \n" and random.random() < corrupt else ch for ch in art
            )
            live.update(Text(glitched, style=f"bold {GREEN}"))
            time.sleep(0.04)
        live.update(Text(art, style=f"bold {GREEN}"))


def type_line(console: Console, text: Text, delay: float = 0.004) -> None:
    if not animations_enabled():
        console.print(text)
        return
    with Live(console=console, refresh_per_second=120) as live:
        for i in range(1, len(text) + 1):
            live.update(text[:i])
            time.sleep(delay)


def status_line(check: Check) -> Text:
    line = Text("  ")
    line.append("[ OK ]" if check.ok else "[FAIL]", style=f"bold {GREEN}" if check.ok else "bold red")
    line.append(f" {check.name} ", style=GREEN)
    line.append("." * max(2, 14 - len(check.name)), style=DARK)
    line.append(f" {check.detail}", style=GREEN if check.ok else "red")
    return line


def show_status(console: Console, checks: list[Check]) -> None:
    for check in checks:
        type_line(console, status_line(check))


def boot(console: Console) -> list[Check]:
    """Full boot: rain while the checks run, banner, then typed status. Returns the checks."""
    console.clear()
    with ThreadPoolExecutor(max_workers=1) as pool:
        pending = pool.submit(run_all)
        if animations_enabled():
            matrix_rain(console, until=pending)
        checks = pending.result()
    glitch_banner(console)
    type_line(console, Text(f"  > establishing link to local stack ... {time.strftime('%H:%M:%S')}", style=DIM))
    console.print()
    show_status(console, checks)
    console.print()
    return checks
