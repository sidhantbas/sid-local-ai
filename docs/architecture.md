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
| Open WebUI    | Docker (Colima)  | TBD  | not started |
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
