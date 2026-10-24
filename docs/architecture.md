# Architecture

## Overview

```
macOS host (Apple Silicon, 48 GB)
├── Strata (native, main)    ── serves Qwen3.8-Flash-Next Gyro-S on 127.0.0.1:8080/v1
├── Unsloth Studio (native)  ── or Qwen3.6-35B-A3B UD-Q4_K_XL on 127.0.0.1:8890/v1
├── sid CLI (native)         ── launcher/menu over scripts/; clap listener via launchd
└── Colima VM (VZ, 4 CPU, 4 GB RAM, Docker runtime)
    ├── Open WebUI     ── both servers via host.docker.internal:8080/v1 and :8890/v1
    └── Hermes Agent   ── dashboard :9119; model via whichever server started last
```

Only one model server runs at a time (both together do not fit in 48 GB):
`start-strata.sh` stops Unsloth, `start-unsloth.sh` stops Strata, and each points Hermes at
itself.

The model runs natively on the host so it can use the Mac's unified memory
directly; Colima only needs enough RAM for the lightweight containers.

## Components

| Component     | Runs where       | Port | Status      |
|---------------|------------------|------|-------------|
| Colima        | macOS (VZ VM)    | -    | running     |
| Open WebUI    | Docker (Colima)  | 3000 | running     |
| Strata        | macOS native     | 8080 | running (main) |
| Unsloth Studio| macOS native     | 8890 | stopped (alternative) |
| Hermes Agent  | Docker (Colima)  | 9119 | running     |
| sid CLI       | macOS (launchd)  | -    | installed   |

## Colima

- Profile: `default`, VM type `vz` with Rosetta (amd64 images run via Rosetta)
- Resources: 4 CPU, 4 GB RAM (raised from 2 GB to fit Hermes), 100 GB disk (sparse)
- Docker socket: `unix:///Users/sid/.colima/default/docker.sock`
- Docker context: `colima` (Docker Desktop's `desktop-linux` context is still
  installed; switch back with `docker context use desktop-linux`)
- From containers, the Mac host is reachable as `host.docker.internal`
  (also `host.lima.internal`)

## Open WebUI

- Defined in `docker/docker-compose.yml` (service `open-webui`, image
  `ghcr.io/open-webui/open-webui:main`, v0.12.3 at install time, ~5.8 GB image)
- URL: http://localhost:3000 (container port 8080). The first account created
  becomes the admin.
- Data (users, chats, settings) lives in the Docker volume `sid-local-ai_open-webui`,
  so stopping or recreating the container keeps it
- Ollama integration is disabled (`ENABLE_OLLAMA_API=false`); the model is
  an OpenAI-compatible connection to Unsloth Studio on the host (see below)
- Host access from the container verified: `host.docker.internal` -> 192.168.5.2
- Memory: ~1.0 GB idle out of Colima's 4 GB

## Strata (main model since 2026-10-24)

- Strata v0.2.2 (Terminal and Metal engine 0.1.47) in `~/.local/share/strata`, CLI
  `~/.local/bin/strata`; install steps in [setup-log.md](setup-log.md) section 16
- Model: Qwen3.8-Flash-Next Gyro-S (125B mixture of experts, 58.5 GB file), id
  `qwen3.8-flash-next-gyro-gyro-s`; Charles's choice for the main model (smarter than the
  35B-A3B and the 27B)
- Started by `scripts/start-strata.sh`: 64K context, one slot, vision off, streaming mode
  (`STRATA_METAL_STREAM=1`: the most-used experts in an in-memory arena, the rest read from
  the SSD), `STRATA_ALLOWED_HOSTS=host.docker.internal,...` so the containers are not refused
- Speed: ~280 t/s prompt and ~29 t/s generation with Chrome closed (22.7 GB arena); slower
  with less free memory at start. Figures: [benchmarks/README.md](../benchmarks/README.md)
- API: OpenAI-compatible at `http://127.0.0.1:8080/v1`, no key (local access only)
- Memory: ~25-33 GB, depending on the arena
- One cached prompt: a request that does not start with the cached prompt replaces it, so
  Hermes's session-title request is turned off (see Hermes below)

## Unsloth Studio (the fast alternative)

- Native macOS install in `~/.unsloth/studio`; CLI `~/.local/bin/unsloth`
- Started by `scripts/start-unsloth.sh` (`unsloth studio run`), logs in `logs/unsloth.log`
- Models (one loaded at a time, both `UD-Q4_K_XL` from the Hugging Face cache):
  - default since 2026-10-23: `unsloth/Qwen3.6-35B-A3B-MTP-GGUF` (mixture of experts,
    3B active, 22.85 GB): ~813 t/s prompt, ~58 t/s generation
  - `unsloth/Qwen3.8-27B-GGUF` (dense, 17.56 GB): ~118 t/s prompt, ~19 t/s generation
  - figures and method: [benchmarks/README.md](../benchmarks/README.md)
- Context 64K tokens (Hermes requires at least 64K); sampling temp 1.0 / top-p 0.95 /
  top-k 20 / min-p 0; Unsloth runs llama-server with 4 slots sharing one KV cache and
  MTP + n-gram speculative decoding
- API: OpenAI-compatible at `http://127.0.0.1:8890/v1` (also Anthropic `/v1/messages`),
  Bearer key labelled `open-webui`, stored in `.env` as `UNSLOTH_API_KEY` (git-ignored).
  The key is reused across restarts.
- Port 8890 because 8888 (Unsloth's default) is used by a JupyterLab server
- Memory: ~23.7 GB with the model loaded at 64K context (22.1 GB at 32K)
- Unsloth listens on 127.0.0.1 only, but Colima still forwards
  `host.docker.internal:8890` from containers to it, so it isn't exposed to the LAN

## Open WebUI connections

- Fresh installs: `OPENAI_API_BASE_URL` / `OPENAI_API_KEY` in `docker-compose.yml`,
  filled from `.env` (`--env-file .env` in the scripts)
- Existing install: Open WebUI keeps its own saved settings and ignores those env vars
  after first start, so the saved connection (`openai.api_base_urls`,
  `openai.api_keys` in `webui.db`) was updated to point at Unsloth
- Verified: using the saved URL and key from inside the container, `/v1/models`
  lists Qwen and a chat completion returns a reply
- 2026-10-24: Strata added the same way as a second connection
  (`http://host.docker.internal:8080/v1`, key `none`); the compose file now lists both
  (`OPENAI_API_BASE_URLS` / `OPENAI_API_KEYS`). Open WebUI shows the models of whichever
  server is running.

## Hermes Agent

- Image `nousresearch/hermes-agent:latest` (digest at install:
  `sha256:7a69201726bc64db2072a1371557137c23312d29705cda2b8ea2a0214a50a4cf`), service
  `hermes` in `docker/docker-compose.yml`, command `gateway run`
- Data: Docker named volume `sid-local-ai_hermes-data` (config, sessions, skills,
  memories). Not a `~/.hermes` bind mount, because Hermes warns SQLite on virtiofs
  bind mounts can corrupt. The older native install in `~/.hermes` (June) is untouched.
- Model: `model.provider=custom`, `model.base_url=http://host.docker.internal:8080/v1`,
  `model.default=qwen3.8-flash-next-gyro-gyro-s` (Strata), `model.context_length=65536`.
  `start-unsloth.sh` sets `:8890/v1` and `unsloth/Qwen3.6-35B-A3B-MTP-GGUF` instead.
  Hermes refuses models with less than 64K context.
- `auxiliary.title_generation.model_upgrade_enabled=false`: Hermes keeps its instant session
  title instead of asking the model, because that request evicts Strata's cached prompt
- Google: Hermes's built-in `google-workspace` skill, logged in as sidhantbastola7 only
  (token `/opt/data/google_token.json` in the volume, mode 600; full Gmail / Calendar / Drive /
  Docs / Sheets scopes, read-only contacts). Separate from the host's `gws` profiles, whose
  credentials stay in the macOS keychain. One-shot runs need `-s google-workspace -t terminal`:
  in `-q` mode Hermes blocks `execute_code`, and with the full toolset it wanders (10+ min).
  `sid` menu item 8 runs the mail check this way (~50 s).
- Dashboard: http://localhost:9119 (published on 127.0.0.1 only), login form with
  `HERMES_DASHBOARD_USER` / `HERMES_DASHBOARD_PASSWORD` from `.env`
- Memory: ~430 MB idle, capped at 2 GB (`mem_limit`). Browser tools would need more.
- Speed: Hermes sends a ~14K-token system prompt (tools, skills). "What is the capital of
  Nepal?": 132 s on the 27B, 31 s on the 35B-A3B, 58-90 s on Strata; 9 s / 4 s / 5-6 s once
  the prompt is cached

## sid CLI

- `uv tool` install (editable) of `cli/`; binary `~/.local/bin/sid`
- Menu actions call the scripts in `scripts/`, so the CLI adds no separate logic
  for starting or stopping services
- LaunchAgent `com.sidlocalai.clapd` runs `sid clap daemon`: it listens to the mic
  for 60 s after login and each screen unlock; a double clap runs `sid launch`,
  which opens Ghostty full screen with `cli/assets/ghostty-hacker.conf`
- No audio is stored; detection uses per-block peak/RMS against a noise floor
- Details: [cli/README.md](../cli/README.md)
