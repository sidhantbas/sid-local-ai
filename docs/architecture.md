# Architecture

## Overview

```
macOS host (Apple Silicon, 48 GB)
├── Unsloth Studio (native)  ── serves Qwen3.8-27B UD-Q4_K_XL on 127.0.0.1:8890/v1
└── Colima VM (VZ, 4 CPU, 2 GB RAM, Docker runtime)
    ├── Open WebUI     ── talks to Unsloth via host.docker.internal:8890/v1
    └── Hermes Agent   ── docker compose
```

The model runs natively on the host so it can use the Mac's unified memory
directly; Colima only needs enough RAM for the lightweight containers.

## Components

| Component     | Runs where       | Port | Status      |
|---------------|------------------|------|-------------|
| Colima        | macOS (VZ VM)    | -    | running     |
| Open WebUI    | Docker (Colima)  | 3000 | running     |
| Unsloth Studio| macOS native     | 8890 | running     |
| Hermes Agent  | Docker (Colima)  | TBD  | not started |

## Colima

- Profile: `default`, VM type `vz` with Rosetta (amd64 images run via Rosetta)
- Resources: 4 CPU, 2 GB RAM, 100 GB disk (sparse)
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
- Memory: ~1.1 GB idle out of Colima's 2 GB, which leaves little headroom for
  Hermes Agent

## Unsloth Studio

- Native macOS install in `~/.unsloth/studio`; CLI `~/.local/bin/unsloth`
- Started by `scripts/start-unsloth.sh` (`unsloth studio run`), logs in `logs/unsloth.log`
- Model: `unsloth/Qwen3.8-27B-GGUF`, variant `UD-Q4_K_XL` (17.56 GB file, from the
  Hugging Face cache), context capped at 32K tokens; sampling temp 1.0 / top-p 0.95 /
  top-k 20 / min-p 0
- API: OpenAI-compatible at `http://127.0.0.1:8890/v1` (also Anthropic `/v1/messages`),
  Bearer key labelled `open-webui`, stored in `.env` as `UNSLOTH_API_KEY` (git-ignored).
  The key is reused across restarts.
- Port 8890 because 8888 (Unsloth's default) is used by a JupyterLab server
- Memory: ~22 GB while the model is loaded
- Unsloth listens on 127.0.0.1 only, but Colima still forwards
  `host.docker.internal:8890` from containers to it, so it isn't exposed to the LAN

## Open WebUI ↔ Unsloth connection

- Fresh installs: `OPENAI_API_BASE_URL` / `OPENAI_API_KEY` in `docker-compose.yml`,
  filled from `.env` (`--env-file .env` in the scripts)
- Existing install: Open WebUI keeps its own saved settings and ignores those env vars
  after first start, so the saved connection (`openai.api_base_urls`,
  `openai.api_keys` in `webui.db`) was updated to point at Unsloth
- Verified: using the saved URL and key from inside the container, `/v1/models`
  lists Qwen and a chat completion returns a reply
