# Setup log

Every command run to set up this machine, in order.

## 1. Colima (Docker runtime)

Colima 0.10.3 was already installed via Homebrew (`brew install colima`).
The Docker CLI (28.3.2) comes from Docker Desktop.

```sh
# First start: creates the VM and the "colima" docker context
colima start --cpu 4 --memory 8 --vm-type vz --vz-rosetta

# Resize to the 2 GB spec (CPU / VM type / Rosetta settings are remembered)
colima stop
colima start --memory 2

# Verify
colima list                 # default  Running  aarch64  4  2GiB  100GiB  docker
docker context show         # colima
docker pull alpine          # confirms Docker can pull images through Colima
```

## 2. Repository

Created `sidhantbas/sid-local-ai` (private, empty) manually at github.com/new.

```sh
mkdir -p ~/sid-local-ai && cd ~/sid-local-ai
git init -b main
# ... add files ...
git add -A && git commit -m "Initial skeleton"
git remote add origin https://github.com/sidhantbas/sid-local-ai.git
git push -u origin main
```

## 3. Open WebUI

Compose file: `docker/docker-compose.yml`.

```sh
docker compose -f docker/docker-compose.yml config -q   # validate
docker compose -f docker/docker-compose.yml pull        # ~5.8 GB, ~2 min
./scripts/start-open-webui.sh                           # up -d + wait for /health

# Verify
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/   # 200
docker exec open-webui getent hosts host.docker.internal          # 192.168.5.2
docker stats --no-stream                                          # ~1.1 GiB / 1.9 GiB
```
