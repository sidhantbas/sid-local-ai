# Architecture

## Overview

```
macOS host (Apple Silicon, 48 GB)
├── Unsloth Studio (native app)  ── serves qwen3.8-27b-q4-k-xl on port TBD
└── Colima VM (VZ, 4 CPU, 2 GB RAM, Docker runtime)
    ├── Open WebUI     ── talks to Unsloth via host.docker.internal:<port>
    └── Hermes Agent   ── docker compose
```

The model runs natively on the host so it can use the Mac's unified memory
directly; Colima only needs enough RAM for the lightweight containers.

## Components

| Component     | Runs where       | Port | Status      |
|---------------|------------------|------|-------------|
| Colima        | macOS (VZ VM)    | -    | running     |
| Open WebUI    | Docker (Colima)  | 3000 | running     |
| Unsloth Studio| macOS native     | TBD  | not started |
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
- Ollama integration is disabled (`ENABLE_OLLAMA_API=false`); the model will be
  added as an OpenAI-compatible connection pointing at Unsloth Studio on the host
- Host access from the container verified: `host.docker.internal` -> 192.168.5.2
- Memory: ~1.1 GB idle out of Colima's 2 GB, which leaves little headroom for
  Hermes Agent
