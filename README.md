# sid-local-ai

Local AI stack on macOS (Apple Silicon, 48 GB RAM): a local Qwen model served by
Unsloth Studio, Open WebUI and Hermes Agent in Docker (via Colima), plus developer
tooling (uv, bun, gws CLI, HyperFrames skills).

Every command used to set this machine up is recorded in
[docs/setup-log.md](docs/setup-log.md). How the pieces fit together is in
[docs/architecture.md](docs/architecture.md).

## Quick start

```sh
./scripts/start-strata.sh       # start Strata + Qwen3.8-Flash-Next Gyro-S -> :8080 (the main model; close Chrome first)
./scripts/start-unsloth.sh      # or: Unsloth Studio + Qwen3.6-35B-A3B -> :8890, faster (add 27b for Qwen3.8-27B)
./scripts/bench-unsloth.sh --engine <label>   # llama-benchy benchmark -> benchmarks/
./scripts/start-colima.sh       # start the Docker runtime (4 GB VM)
./scripts/start-open-webui.sh   # start Open WebUI -> http://localhost:3000
./scripts/start-hermes.sh       # start Hermes Agent -> dashboard http://localhost:9119
./scripts/install-hermes-skills.sh   # copy hermes/skills/ (google-accounts, humanloop) into Hermes
./scripts/humanloop-init.sh    # create HumanLoop's life model in ~/humanloop (never overwrites)
./scripts/status.sh             # show what's running
./scripts/stop-hermes.sh        # stop Hermes Agent (data is kept)
./scripts/stop-open-webui.sh    # stop Open WebUI (data is kept)
./scripts/stop-colima.sh        # stop the Docker runtime
./scripts/stop-strata.sh        # stop Strata (frees the model's memory)
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
hermes/     Hermes skills kept in the repo (google-accounts, humanloop); scripts/install-hermes-skills.sh copies them in
config/     non-secret configuration notes
cli/        sid CLI (hacker launcher + double-clap listener)
```

## Progress

- [x] Colima Docker runtime, 4 GB RAM (raised from 2 GB for Hermes, OK from Charles)
- [x] Open WebUI in Docker
- [x] Unsloth Studio + `qwen3.8-27b-q4-k-xl` (default since 2026-10-23: Qwen3.6-35B-A3B, see [benchmarks](benchmarks/README.md))
- [x] Strata + Qwen3.8-Flash-Next Gyro-S, the main model since 2026-10-24 (Charles)
- [x] Open WebUI connected to the local models (Strata port 8080, Unsloth port 8890)
- [x] Hermes Agent (docker compose, local Qwen)
- [x] uv + bun installed locally
- [x] gws CLI: 3 profiles (one per Gmail account), tested with Gmail / Calendar / Tasks
- [x] HyperFrames skills installed via bun
- [ ] AGENTS.md copied from the original
- [x] Start/stop scripts for every component (Colima, Open WebUI, Strata, Unsloth, Hermes)
- [x] `sid` CLI with double-clap launcher (LaunchAgent)
