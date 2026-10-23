# sid CLI

Hacker-style launcher for the local AI stack: a Matrix boot sequence with live
status checks, then a one-key menu backed by the scripts in `../scripts/`.
A background listener opens it full screen when you double clap after unlocking.

## Install

```sh
./scripts/install-cli.sh             # CLI + clap listener (LaunchAgent)
./scripts/install-cli.sh --no-clap   # CLI only
./scripts/install-cli.sh --uninstall # remove both
```

The CLI is installed editable with `uv tool`, so changes in `cli/src` apply
immediately (re-run the script after changing dependencies).

## Commands

```sh
sid                 # boot sequence + menu
sid status          # live checks only
sid launch          # open the full-screen Ghostty window running `sid`
sid clap test       # live meter: shows level, noise floor, each clap, ">>> DOUBLE CLAP"
sid clap tune --min-peak 0.3 --ratio 10 --listen-seconds 90   # save thresholds
sid clap daemon     # the listener itself (run by launchd)
```

Menu: `1` start stack, `2` talk to Hermes, `3` Open WebUI, `4` Hermes dashboard,
`5` status, `6` gws check, `7` shut down stack, `8` check mail (Hermes, unread Gmail), `q` exit to shell.
`SID_NO_ANIM=1 sid` skips the animations.

## Double clap

- LaunchAgent `com.sidlocalai.clapd` (`~/Library/LaunchAgents/com.sidlocalai.clapd.plist`)
  runs `sid clap daemon` at login and restarts it if it crashes.
- The microphone is only open for 60 s after login and after each unlock
  (`com.apple.screenIsUnlocked`). Two claps 0.15–0.7 s apart launch the window.
- Audio is never recorded: each ~12 ms block is reduced to a peak and RMS value and discarded.
- Settings: `~/.config/sid-cli/clap.json`. Log: `~/Library/Logs/sid-clapd.log`.
- If the log says "only silence from the mic", allow the microphone for Python in
  System Settings > Privacy & Security > Microphone.

Restart the listener after tuning:

```sh
launchctl kickstart -k gui/$(id -u)/com.sidlocalai.clapd
```

## Look

`assets/ghostty-hacker.conf`: Ghostty with the Matrix theme, full screen, no
title bar, slight transparency and blur. Colours in `boot.py`: `#00ff41`,
`#008f11`, `#003b00`.

## Layout

```
src/sid_cli/
  main.py     argument parsing
  boot.py     matrix rain, glitch banner, status lines
  menu.py     menu loop, runs ../scripts/*
  status.py   parallel checks (Colima, Unsloth, Open WebUI, Hermes, gws, memory)
  clap.py     double-clap detector, test meter, launchd daemon
  launch.py   opens the styled Ghostty window
  paths.py    repo / config paths, .env loading
assets/ghostty-hacker.conf
```
