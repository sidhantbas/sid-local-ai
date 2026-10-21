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

## 4. Unsloth Studio (native macOS)

Runs natively, not in Docker: containers on macOS can't use the Apple GPU, and
Colima only has 2 GB. Installed with the official script (reviewed before running;
sha256 `b076f3d859dd44f1...`). It installs to `~/.unsloth/studio` (2.2 GB), adds
`~/.local/bin/unsloth` and `~/Applications/Unsloth Studio.app`, and also installs
`uv` into `~/.local/bin`. It did not modify `~/.zshrc`.

```sh
curl -fsSL https://unsloth.ai/install.sh -o install.sh   # review first
UNSLOTH_SKIP_AUTOSTART=1 sh install.sh
```

Port: Unsloth defaults to 8888, but 8888 is taken by a JupyterLab server
(`~/work/mission-p`), so Studio will run on **8890**:

```sh
unsloth studio -p 8890      # not yet started
```

### Model download: Qwen3.8-27B UD-Q4_K_XL (17.56 GB)

Downloaded into the standard Hugging Face cache (`~/.cache/huggingface/hub`),
which Unsloth Studio reads. The default Xet transfer failed mid-download
(`CAS Client Error ... error decoding response body`), so plain HTTP is used
instead; it resumes from an `.incomplete` file if interrupted.

```sh
HF_HUB_DISABLE_XET=1 hf download unsloth/Qwen3.8-27B-GGUF Qwen3.8-27B-UD-Q4_K_XL.gguf
```

## 5. uv and bun

```sh
# uv: installed by the Unsloth installer -> ~/.local/bin/uv
brew install bun            # bun 1.4.3 -> /opt/homebrew/bin/bun
```

## 6. HyperFrames skills (via bun)

Requires Node.js 22+ (v22.17.0 installed) and FFmpeg (installed via Homebrew).
Installed globally for Claude Code into `~/.claude/skills/`, so they work in
every project.

```sh
bunx skills@latest add heygen-com/hyperframes -l                          # list
bunx skills@latest add heygen-com/hyperframes -g -a claude-code -s '*' -y # install
```

Installed (7): `hyperframes`, `hyperframes-cli`, `hyperframes-registry`,
`media-use` (core), plus `figma`, `remotion-to-hyperframes`, `slideshow`.

Update later with: `bunx skills@latest update -g`

## 7. gws CLI (Google Workspace), 3 profiles

```sh
brew install googleworkspace-cli     # gws 0.22.5 (NOT `brew install gws`, an unrelated tool)
```

gws 0.22.5 has no `--account` flag, so each account gets its own config dir via
`GOOGLE_WORKSPACE_CLI_CONFIG_DIR`, wrapped by `scripts/gws.sh`:

| Profile           | Account                    | Config dir                              |
|-------------------|----------------------------|-----------------------------------------|
| `sidhantbastola7` | sidhantbastola7@gmail.com  | `~/.config/gws/profiles/sidhantbastola7` |
| `sibastola6ucl`   | sibastola6ucl@gmail.com    | `~/.config/gws/profiles/sibastola6ucl`   |
| `disisidstudio`   | disisidstudio@gmail.com    | `~/.config/gws/profiles/disisidstudio`   |

### Google Cloud setup (manual, in the console, as sidhantbastola7)

1. Project `sid-local-ai`; enable Gmail API, Google Calendar API, Google Tasks API.
2. OAuth consent screen: External, Testing mode, all 3 accounts added as **test users**
   (without this, sign-in fails with `Error 403: access_denied`).
3. OAuth client: type **Desktop app**; JSON downloaded and copied to each profile:
   ```sh
   install -m 600 ~/Downloads/client_secret_*.json ~/.config/gws/profiles/<profile>/client_secret.json
   ```
4. IAM: grant **Service Usage Consumer** on `sid-local-ai` to sibastola6ucl and
   disisidstudio. Without it, Tasks calls from non-owner accounts fail
   intermittently with 403 "Caller does not have required permission to use project".

Testing-mode sign-ins expire after 7 days; publishing the app (after completing the
Branding page) avoids that.

### Sign in and test

```sh
./scripts/gws.sh <profile> auth login -s gmail,calendar,tasks   # opens Google sign-in
./scripts/gws.sh <profile> auth status                          # shows linked account
./scripts/test-gws.sh                  # Gmail +triage, Calendar +agenda, Tasks tasklists list
```

Result: all 3 profiles pass Gmail, Calendar and Tasks.

## 8. Unsloth Studio running + Open WebUI connected

```sh
./scripts/start-unsloth.sh       # unsloth studio run --model unsloth/Qwen3.8-27B-GGUF
                                 #   --gguf-variant UD-Q4_K_XL --max-seq-length 32768
                                 #   -p 8890 --api-key-name open-webui ...
# Prints the API key once; saved (not committed) to .env:
#   UNSLOTH_PORT=8890
#   UNSLOTH_API_KEY=sk-unsloth-...

curl http://127.0.0.1:8890/v1/models -H "Authorization: Bearer $UNSLOTH_API_KEY"
```

Open WebUI's saved connection still pointed at api.openai.com, so with the container
stopped and its data dir backed up (`docker cp open-webui:/app/backend/data/. <backup>`,
including `webui.db-wal`), the `openai.api_base_urls` / `openai.api_keys` rows in
`webui.db` were set to `http://host.docker.internal:8890/v1` and the Unsloth key.
On a new machine the compose env vars do this instead. Alternatively, set it in the UI:
Admin Panel → Settings → Connections → OpenAI API.

Verified from inside the container with the saved settings: Qwen listed, and
a chat returned "open webui can reach qwen". `start-unsloth.sh` / `stop-unsloth.sh`
tested; the API key stays the same across restarts.
