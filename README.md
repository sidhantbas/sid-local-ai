# sid-local-ai

Local AI stack on macOS (Apple Silicon, 48 GB RAM): a local Qwen model served by
Unsloth Studio, Open WebUI and Hermes Agent in Docker (via Colima), plus developer
tooling (uv, bun, gws CLI, HyperFrames skills).

Every command used to set this machine up is recorded in
[docs/setup-log.md](docs/setup-log.md). How the pieces fit together is in
[docs/architecture.md](docs/architecture.md).

## Quick start

```sh
./scripts/start-unsloth.sh      # start Unsloth Studio + Qwen3.8-27B -> :8890 (~24 GB RAM)
./scripts/start-colima.sh       # start the Docker runtime (4 GB VM)
./scripts/start-open-webui.sh   # start Open WebUI -> http://localhost:3000
./scripts/start-hermes.sh       # start Hermes Agent -> dashboard http://localhost:9119
./scripts/status.sh             # show what's running
./scripts/stop-hermes.sh        # stop Hermes Agent (data is kept)
./scripts/stop-open-webui.sh    # stop Open WebUI (data is kept)
./scripts/stop-colima.sh        # stop the Docker runtime
./scripts/stop-unsloth.sh       # stop Unsloth Studio (frees the model's memory)
```

Or use the launcher: `sid` (boot screen + menu), `sid launch` (full-screen hacker
window), or double clap within 60 s of unlocking the Mac. See [cli/README.md](cli/README.md).

Google Workspace (one profile per Gmail account):

```sh
./scripts/gws.sh <profile> <gws args...>   # e.g. ./scripts/gws.sh sidhantbastola7 gmail +triage
./scripts/test-gws.sh                      # Gmail / Calendar / Tasks check for all profiles
```

## Layout

```
docs/       architecture + setup log
scripts/    start / stop / status scripts
docker/     docker-compose files (Open WebUI, Hermes Agent)
config/     non-secret configuration notes
cli/        sid CLI (hacker launcher + double-clap listener)
```

## Progress

- [x] Colima Docker runtime, 4 GB RAM (raised from 2 GB for Hermes, OK from Charles)
- [x] Open WebUI in Docker
- [x] Unsloth Studio + `qwen3.8-27b-q4-k-xl`
- [x] Open WebUI connected to the local model (Unsloth port 8890)
- [x] Hermes Agent (docker compose, local Qwen)
- [x] uv + bun installed locally
- [x] gws CLI: 3 profiles (one per Gmail account), tested with Gmail / Calendar / Tasks
- [x] HyperFrames skills installed via bun
- [ ] AGENTS.md copied from the original
- [x] Start/stop scripts for every component (Colima, Open WebUI, Unsloth, Hermes)
- [x] `sid` CLI with double-clap launcher (LaunchAgent)
