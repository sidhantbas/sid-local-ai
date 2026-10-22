"""`sid` command line.

  sid               boot sequence + menu
  sid status        live checks only
  sid launch        open the full-screen hacker terminal running `sid`
  sid clap test     live meter to tune clap detection
  sid clap tune     save new clap thresholds
  sid clap daemon   background listener (run by launchd)
"""

import argparse

from rich.console import Console

from . import boot, clap, menu
from .launch import launch_terminal
from .status import run_all


def main() -> None:
    parser = argparse.ArgumentParser(prog="sid", description="SID // LOCAL-AI launcher")
    sub = parser.add_subparsers(dest="cmd")
    sub.add_parser("status", help="live checks only")
    sub.add_parser("launch", help="open the full-screen hacker terminal")
    clap_p = sub.add_parser("clap", help="clap detection")
    clap_sub = clap_p.add_subparsers(dest="clap_cmd", required=True)
    clap_sub.add_parser("test", help="live meter for tuning")
    clap_sub.add_parser("daemon", help="background listener (launchd)")
    tune = clap_sub.add_parser("tune", help="save new thresholds")
    tune.add_argument("--min-peak", type=float)
    tune.add_argument("--ratio", type=float)
    tune.add_argument("--listen-seconds", type=float)
    args = parser.parse_args()

    console = Console(highlight=False)
    if args.cmd == "status":
        boot.show_status(console, run_all())
    elif args.cmd == "launch":
        launch_terminal()
    elif args.cmd == "clap":
        if args.clap_cmd == "test":
            clap.test()
        elif args.clap_cmd == "daemon":
            clap.daemon()
        elif args.clap_cmd == "tune":
            cfg = clap.ClapConfig.load()
            for field in ("min_peak", "ratio", "listen_seconds"):
                if (value := getattr(args, field)) is not None:
                    setattr(cfg, field, value)
            cfg.save()
            print(f"saved {clap.CONFIG_FILE}: {cfg}")
    else:
        try:
            boot.boot(console)
            menu.loop(console)
        except (KeyboardInterrupt, EOFError):
            console.print("\n  > link closed.", style=boot.DIM)
