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
