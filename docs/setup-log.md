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

## 14. Qwen3.6-35B-A3B as the default model (2026-10-22/23)

```sh
HF_HUB_DISABLE_XET=1 hf download unsloth/Qwen3.6-35B-A3B-MTP-GGUF \
  Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf mmproj-F16.gguf
shasum -a 256 <snapshot>/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
# 55983c5a75a1ab969824077b3bb3de4146e82a9234072b48ad4e8f92ad3fe9f1 (matches Hugging Face)
./scripts/stop-unsloth.sh && ./scripts/start-unsloth.sh 35b-a3b
./scripts/bench-unsloth.sh --engine 35b-a3b-ctx64k
docker exec hermes hermes config set model.default unsloth/Qwen3.6-35B-A3B-MTP-GGUF
docker exec hermes hermes chat -q "What is the capital of Nepal?" --oneshot -Q   # 31 s, then 4 s
```

Chosen over Strata (Niko1221/Strata, sent by Charles): its Mac engine does not run
Qwen3.6-35B-A3B, and on 48 GB it can only run the Gyro-S pack of Qwen3.8-Flash-Next
(~38 GB resident). `start-unsloth.sh` defaults to `35b-a3b` since 2026-10-23; `27b` still works.

## 15. 256K context and Hermes's Google skill (2026-10-23)

```sh
UNSLOTH_CONTEXT=262144 ./scripts/start-unsloth.sh    # 35B-A3B, ~30 GB; also sets Hermes
./scripts/bench-unsloth.sh --engine 35b-a3b-ctx256k --pp 2048 --tg 128 --depth 0 32768 131072
```

Hermes's built-in `google-workspace` skill (chosen over a read-only bridge to the host's
`gws`; it gives Hermes full access to one account). Run as the container's `hermes` user so
the files stay readable by the gateway:

```sh
G="/opt/hermes/.venv/bin/python /opt/data/skills/productivity/google-workspace/scripts/setup.py"
docker exec -i -u hermes hermes sh -c 'umask 077; cat > /opt/data/tmp_client_secret.json' \
  < ~/.config/gws/profiles/sidhantbastola7/client_secret.json
docker exec -u hermes hermes sh -c "$G --client-secret /opt/data/tmp_client_secret.json; rm /opt/data/tmp_client_secret.json"
docker exec -u hermes hermes sh -c "$G --auth-url"        # open, approve, copy the localhost:1 URL
docker exec -u hermes hermes sh -c "$G --auth-code '<the localhost:1 URL>'"
docker exec -u hermes hermes sh -c "chmod 600 /opt/data/google_*.json; $G --check"   # AUTHENTICATED
docker exec hermes hermes chat -q "...unread emails..." \
  -s google-workspace -t terminal --reasoning low --oneshot -Q        # 51 s
```

Without `-s google-workspace -t terminal` the same question ran for more than 10 minutes
(24 model calls, 74K tokens of context): in `-q` mode Hermes blocks `execute_code` and
`python -c`, and the agent kept trying other ways. Revoke with `$G --revoke`.

## 16. Strata trial (2026-10-23)

```sh
curl -fsSL https://github.com/Niko1221/Strata/releases/download/v0.2.2/install.sh -o install.sh
# read install.sh: writes only ~/.local/share/strata and ~/.local/bin/strata, checks SHA-256 + signature
STRATA_FEED=https://github.com/Niko1221/Strata/releases/download/v0.2.2 sh install.sh
strata update --feed https://github.com/Niko1221/Strata/releases/download/v0.2.2 --no-control  # Metal engine 0.1.47
STRATA_FEED=https://github.com/Niko1221/Strata/releases/download/v0.2.2 \
  strata install -- --family gyro --model Gyro-S --context 65536 --vision no --no-start --yes  # 54 GB
./scripts/stop-unsloth.sh
STRATA_ALLOWED_HOSTS=host.docker.internal,host.docker.internal:8080 \
  strata launch --model gyro-s --family gyro --context 64k --vision off --access local --port 8080 \
  --set STRATA_METAL_STREAM=1 --no-tui --yes --feed https://github.com/Niko1221/Strata/releases/download/v0.2.2
./scripts/bench-unsloth.sh --strata gyro-s-ctx64k
docker exec hermes hermes config set model.base_url http://host.docker.internal:8080/v1   # test only
docker exec hermes hermes config set model.default qwen3.8-flash-next-gyro-gyro-s
strata launch --stop --preset "Gyro-S 64K"
docker exec hermes hermes config set model.base_url http://host.docker.internal:8890/v1
./scripts/start-unsloth.sh   # back to the 35B-A3B; also resets Hermes's model and context
```

Results and setup problems: [benchmarks/README.md](../benchmarks/README.md). Strata stays
installed (models in `~/.local/share/strata/Strata-data`, 54 GB); remove that folder,
`~/.local/share/strata` and `~/.local/bin/strata` to uninstall.

## 17. Strata as the main model (2026-10-24)

Charles: "Strata qwen3.8-flash-next should be your main drive". Hermes's 55 s second
question came from its session-title request evicting Strata's single cached prompt
(details: [benchmarks/README.md](../benchmarks/README.md)).

```sh
docker exec hermes hermes config set auxiliary.title_generation.model_upgrade_enabled false
./scripts/start-strata.sh     # new: stops Unsloth, starts Gyro-S, points Hermes at :8080
./scripts/start-unsloth.sh    # now also stops Strata and sets Hermes's base_url back to :8890
```

Open WebUI's saved connection got Strata as a second entry, as in section 8: container
stopped, data backed up with `docker cp`, then `openai.api_base_urls` +=
`http://host.docker.internal:8080/v1` and `openai.api_keys` += `none` in `webui.db` (run with
the open-webui image and the volume mounted). Verified from inside the container: the model
is listed and a chat returned "open webui can reach strata". `sid` menu item 1 now starts
Colima, Open WebUI, Hermes, then Strata; item 7 stops both model servers.

## 18. One Hermes, three Google accounts (2026-10-24)

Hermes's `google-workspace` skill keeps one login per Hermes home. Instead of three Hermes
profiles (hard to follow), each account gets a login folder and the skill is run with
`HERMES_HOME` pointing at it. All three `gws` profiles use the same OAuth client, so the
same client secret is copied into each folder.

```sh
# in the container, as the hermes user, umask 077
mkdir -p /opt/data/google-accounts/{sidhantbastola7,sibastola6ucl,disisidstudio}
cp /opt/data/google_client_secret.json /opt/data/google-accounts/<each>/
mv /opt/data/google_token.json /opt/data/google-accounts/sidhantbastola7/
ln -s /opt/data/google-accounts/sidhantbastola7/google_token.json /opt/data/google_token.json
./scripts/install-hermes-skills.sh      # on the Mac: copies hermes/skills/google-accounts in
# sign in another account (Sid opens the link, picks the account, pastes the redirect URL back):
HERMES_HOME=/opt/data/google-accounts/<account> /opt/hermes/.venv/bin/python \
  /opt/data/skills/productivity/google-workspace/scripts/setup.py --auth-url
HERMES_HOME=/opt/data/google-accounts/<account> ... setup.py --auth-code '<redirect URL>'
```

Verified: sidhantbastola7 works from its folder (20 unread found), `gacct list` shows the
other two as not signed in, and Hermes answered "check unread email in all my accounts" with
4 tool calls in 117 s on Strata.

Then Sid signed in sibastola6ucl and disisidstudio. `gacct list`: all 3 signed in; each
reads Gmail and Calendar. "Check unread email in all my Google accounts": 2 tool calls,
165 s on Strata, 20 unread per account listed under one heading per account.

## 19. HumanLoop phase 1 (2026-10-24)

Sid's idea: HumanLoop, a local-first personal intelligence agent, with the local AI as the
orchestrator. Phase 1 is the life model and the onboarding interview.

```sh
mkdir -p ~/humanloop        # Colima mounts the home folder (virtiofs), so containers can write here
# docker-compose.yml, hermes: - ${HOME}/humanloop:/opt/data/humanloop
docker compose --env-file .env -f docker/docker-compose.yml up -d hermes   # recreate; data volume kept
./scripts/humanloop-init.sh          # empty model files, never overwrites
./scripts/install-hermes-skills.sh   # humanloop + google-accounts
```

Checked: Hermes (uid 10000) can append to files the Mac created, and its config and Google
logins survived the recreate. "What do you know about me so far?" read all files, reported
an empty model and offered the interview (2 tool calls, 60 s on Strata).
