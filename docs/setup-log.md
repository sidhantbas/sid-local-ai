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

## 9. Colima raised to 4 GB

Open WebUI alone used ~1.1 of the 2 GB, too little for Hermes. Charles agreed to more
("Yes you can - later the LLM memory is more important"), so 4 GB:

```sh
colima stop && colima start --memory 4    # start-colima.sh now uses --memory 4
```

## 10. Hermes Agent (Docker)

```sh
docker pull nousresearch/hermes-agent:latest
docker volume create sid-local-ai_hermes-data
H() { docker run --rm -v sid-local-ai_hermes-data:/opt/data nousresearch/hermes-agent:latest "$@"; }
H config set model.provider custom
H config set model.base_url http://host.docker.internal:8890/v1
H config set model.default unsloth/Qwen3.8-27B-GGUF
H config set model.api_key "$UNSLOTH_API_KEY"
H config set model.context_length 65536
```

The first test failed: Hermes needs at least a 64K context, so Unsloth now runs with
`--max-seq-length 65536` (~23.7 GB, up from 22.1 GB at 32K).

```sh
H chat -q "Reply with exactly: hermes is using local qwen" --oneshot -Q
# -> hermes is using local qwen   (~2.5 min)
```

Dashboard password generated into `.env` (`HERMES_DASHBOARD_USER`, `HERMES_DASHBOARD_PASSWORD`).

```sh
./scripts/start-hermes.sh   # compose up -d hermes, waits for http://localhost:9119
./scripts/stop-hermes.sh
docker exec hermes hermes <command>   # e.g. hermes config get model
```

## 11. sid CLI + double-clap launcher

Python 3.14 package in `cli/` (rich, sounddevice, numpy, pyobjc-framework-Cocoa),
terminal: Ghostty 1.3.1 with the Matrix theme. Details in [cli/README.md](../cli/README.md).

```sh
./scripts/install-cli.sh --no-clap   # uv tool install --force --editable ./cli
sid status                           # checks all services in ~2 s
sid launch                           # full-screen hacker window
sid clap test                        # tuned in the room: double claps detected, normal noise ignored
./scripts/install-cli.sh             # + LaunchAgent com.sidlocalai.clapd
launchctl print gui/$(id -u)/com.sidlocalai.clapd | grep state   # -> running
cat ~/Library/Logs/sid-clapd.log     # -> "listening 60s (login)", no mic warning
```

## 12. CLI tools: gh, hf, cf

```sh
gh auth status                          # already logged in as sidhantbas (keyring)
gh repo view sidhantbas/sid-local-ai

uv tool install huggingface_hub         # hf 2.2.0 in ~/.local/bin, ahead of /opt/anaconda3/bin/hf
hf auth login                           # paste a read token from huggingface.co/settings/tokens
hf auth whoami

brew install node@24                    # cf needs Node >= 22.18; /usr/local/bin/node was 22.17
# ~/.zshrc: export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
npm install --global cf                 # Cloudflare CLI (open beta), into ~/.npm-global
cf --version                            # 1.0.0-beta.20
cf auth login                           # opens the browser
```

`npm` skipped the `workerd` postinstall script (npm's install-script allowlist); it is
only needed for local Workers development.

## 13. Benchmark: llama-benchy

```sh
uv tool install llama-benchy            # 0.4.0
./scripts/bench-unsloth.sh --engine ctx64k   # straight to Unsloth's llama-server
./scripts/bench-unsloth.sh ctx64k            # through Unsloth's API on :8890
```

Results, settings and logs per run in `benchmarks/<date>-<target>-<label>/`; summary in
[benchmarks/README.md](../benchmarks/README.md). Notes from the first runs:

- Through Unsloth's API the stream opens before the prompt is processed, so llama-benchy's
  `pp t/s` and `ttfr` are not meaningful there (pp512 showed 1770 t/s, ttfr 9 ms); the
  engine target gives the real prompt-processing speed.
- With thinking on, Unsloth ends the turn inside the reasoning and llama-benchy records no
  prompt-processing row, so the script sends `enable_thinking: false`.
- Tokenizer: `Qwen/Qwen3.8-27B` (the GGUF repo has no tokenizer files).
