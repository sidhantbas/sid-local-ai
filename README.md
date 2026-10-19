# sid-local-ai

Local AI stack on macOS (Apple Silicon, 48 GB RAM): a local Qwen model served by
Unsloth Studio, Open WebUI and Hermes Agent in Docker (via Colima), plus developer
tooling (uv, bun, gws CLI, HyperFrames skills).

Every command used to set this machine up is recorded in
[docs/setup-log.md](docs/setup-log.md). How the pieces fit together is in
[docs/architecture.md](docs/architecture.md).

## Quick start

```sh
./scripts/start-colima.sh       # start the Docker runtime (2 GB VM)
./scripts/start-open-webui.sh   # start Open WebUI -> http://localhost:3000
./scripts/status.sh             # show what's running
./scripts/stop-open-webui.sh    # stop Open WebUI (data is kept)
./scripts/stop-colima.sh        # stop the Docker runtime
```

## Layout

```
docs/       architecture + setup log
scripts/    start / stop / status scripts
docker/     docker-compose files (Open WebUI, Hermes Agent)
config/     non-secret configuration notes
```

## Progress

- [x] Colima Docker runtime, 2 GB RAM
- [x] Open WebUI in Docker
- [ ] Unsloth Studio + `qwen3.8-27b-q4-k-xl`
- [ ] Open WebUI connected to the local model (Unsloth port)
- [ ] Hermes Agent (docker compose)
- [ ] uv + bun installed locally
- [ ] gws CLI: 3 profiles (one per Gmail account), tested with Gmail / Calendar / Tasks
- [ ] HyperFrames skills installed via bun
- [ ] AGENTS.md copied from the original
- [ ] Start/stop scripts for every component
