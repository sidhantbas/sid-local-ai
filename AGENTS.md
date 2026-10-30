---
title: sid-local-ai agent and project rules
description: Canonical instructions for people and coding agents working on sid-local-ai (the local AI stack and HumanLoop). CLAUDE.md is a symbolic link to this file.
date: 2026-10-29
creator: sidhantbas
source: Structure from the AGENTS.md of sidhantbas/mission-p (itself merged with Charles Cai's AGENTS.md); rules gathered from this repository's README.md, TODO.md and docs/
---

# sid-local-ai — Local AI stack and HumanLoop

> `AGENTS.md` is the canonical instruction file; `CLAUDE.md` is a relative symbolic link to it (Charles's convention, TODO W5).
> Edit this file only. Rules marked *(from Charles)* come from his `AGENTS.md` by way of Mission P; the rest are this project's.

## Goal

A private AI stack that runs entirely on Sid's MacBook (Apple M4 Pro, 48 GB): local language models served natively, Open WebUI
and the Hermes agent in Docker, and the `sid` launcher. On top runs **HumanLoop**, a personal agent that learns Sid's goals,
projects and routines and checks in on Telegram. Every model call stays on the laptop.

## Hard rules

### Privacy and locality

- **Inference stays on this Mac.** Strata and Unsloth listen on `127.0.0.1` only; the Hermes dashboard is published on
  `127.0.0.1` only. Never point Hermes or Open WebUI at a cloud model API, and never expose a port to the LAN or the internet
  without Sid's say-so.
- **Personal data never enters the repo or an outside service.** `~/humanloop` (the life model) and `~/brain/study` (lecture
  material) are mounted into Hermes and stay outside git. Do not read them for repository work unless Sid asks, and never copy
  their contents into commits, issues, docs or examples.
- **Secrets stay out of git.** API keys and passwords live in `.env` (git-ignored; `.env.example` holds placeholders only), the
  Telegram token in Hermes's own `.env` inside its data volume (mode 600), Google tokens in the Hermes volume and the macOS
  keychain (`gws`). Never print, echo or log a token; scripts read them from the clipboard or stdin (see
  `scripts/setup/hermes-telegram.sh`). Do not weaken the credential patterns in `.gitignore`.
- **Telegram is the one exception:** phone messages pass through Telegram's servers. The planned web app over Tailscale removes
  it (TODO W8, mobile B).
- **Never contact anyone on Sid's behalf** (mail, Telegram, GitHub mentions, issues) unless Sid asks. Questions for Charles go into
  `TODO.md` as items for Sid to send.

### The agent obeys only its owner

- The Telegram bot answers one user id (`TELEGRAM_ALLOWED_USERS`); never add another.
- HumanLoop proposes, Sid approves: `[inferred]` facts enter the life model only after a yes, and sending mail or changing a
  calendar needs an explicit yes. Keep these rules in `hermes/skills/humanloop/SKILL.md` intact when editing the skill.

### Memory and live state

- **One model server at a time** (both do not fit in 48 GB). Switch only with `scripts/stack/start-strata.sh` or
  `scripts/stack/start-unsloth.sh`: each stops the other and points Hermes at itself.
- **Close Chrome** before starting Strata or benchmarking: Strata sizes its expert arena from the memory free at start, and
  swapping makes benchmark numbers meaningless.
- Treat running services as live user state: the model server, Colima, the `open-webui` and `hermes` containers and the
  LaunchAgents `com.sidlocalai.clapd` and `com.sidlocalai.keepawake`. Stopping them takes HumanLoop offline on Sid's phone. Ask
  before stopping, restarting or recreating them. *(from Charles, adapted)*
- Hermes data lives in the named volume `sid-local-ai_hermes-data`, Open WebUI's in `sid-local-ai_open-webui`. Never delete them
  and never replace the Hermes volume with a bind mount (SQLite on virtiofs can corrupt). The life model stays plain Markdown,
  not SQLite, for the same reason.

### Supply chain

- Pin versions: images by digest (the Hermes base in `hermes/Dockerfile`), packages by exact version, releases by tag (Strata
  `v0.2.2` feed in `start-strata.sh`). Open WebUI still uses `:main`; pin it the next time it is touched.
- Read downloaded install scripts before running them, and check published checksums or signatures.

## Git and GitHub

- One remote: `origin` = `https://github.com/sidhantbas/sid-local-ai.git`, **private**. Never make it public without Sid's
  say-so. Create GitHub repositories with `gh` as private unless Sid explicitly asks otherwise. *(from Charles)*
- Collaborator: Charles Cai (`charles-cai`), write access since 2026-10-26. Remove with
  `gh api -X DELETE repos/sidhantbas/sid-local-ai/collaborators/charles-cai`.
- Work on `main` (all history so far). Create a branch only when Sid asks; do not create a worktree. *(from Charles)*
- Commit only when Sid asks. Commit in batches: one commit per unit of work (a script, a skill, a doc, a setting); never mix units
  in one commit or spread one unit over many. *(Charles, 2026-10-13)*
- Push only when Sid asks; rehearse with `git push --dry-run` first. Never force-push. No tags unless Sid asks for a release.
  *(from Charles)*
- Before committing, review every tracked change and untracked path (`git status`, `git diff --stat`). "Commit all" never covers
  `.env`, tokens, `logs/`, `cli/.venv/`, model files or personal data. *(from Charles)*
- Commit messages: a plain-words subject saying what changed, and a body saying why and what was checked (see `git log`).
- **AI attribution:** AI-assisted commits end with a `Co-Authored-By` line (this repo's convention, README "Working on this
  repo"). Mission P and Charles's repos forbid AI attribution in commits; changing this here is Sid's decision.

## Runtime and tools

| Part | Rule |
|---|---|
| Scripts | Bash with `set -euo pipefail`; run from the repo root as `./scripts/<group>/<name>.sh` (each one `cd`s to the root itself) |
| Docker | Colima (`colima` context, VZ VM, 4 CPU, 4 GB); `docker compose --env-file .env -f docker/docker-compose.yml ...` |
| Hermes config | `docker exec hermes hermes config set <key> <value>`; the model keys belong to the start scripts |
| Hermes skills | Edit `hermes/skills/<name>/`, then `./scripts/setup/install-hermes-skills.sh` |
| Hermes image | Edit `hermes/Dockerfile`, then rebuild (VS Code task "hermes: rebuild image") |
| Hermes one-shot runs | `-s <skills> -t terminal`: with the full toolset it wanders (10+ min), and `-q` blocks `execute_code` |
| `sid` CLI | Python 3.14 with `uv` (`cli/pyproject.toml`, `cli/uv.lock`), installed editable by `scripts/setup/install-cli.sh`; menu actions call `scripts/`, so keep logic in the scripts |
| Benchmarks | `./scripts/bench/llama-benchy.sh --engine <label>` or `--strata <label>` |
| Caches | User-level caches (`~/.cache`, the Hugging Face cache); session scratch files in the scratchpad, not `/tmp` *(from Charles)* |

Ports: Strata `8080`, Unsloth `8890` (8888 belongs to JupyterLab), Open WebUI `3000`, Hermes dashboard `9119`.

## Layout

```text
sid-local-ai/
├── AGENTS.md                this file; CLAUDE.md links here
├── README.md                front door: components, quick start, sid menu, privacy
├── TODO.md                  the single task ledger (workstreams W0–W8)
├── .env.example             settings to copy into .env (git-ignored)
├── scripts/
│   ├── stack/               start / stop / status, model switch, keep-awake
│   ├── setup/               one-time installs: CLI, skills, Telegram, HumanLoop, study brief
│   ├── bench/               llama-benchy runner
│   └── google/              gws per-account wrapper and check
├── docker/docker-compose.yml   Open WebUI + Hermes
├── hermes/
│   ├── Dockerfile           pinned Hermes image + faster-whisper
│   └── skills/              humanloop, google-accounts, study-coach (instructions for Hermes)
├── cli/                     the sid CLI (Python, uv); own README
├── benchmarks/              one immutable folder per run + README summary
├── docs/
│   ├── architecture.md      every component, port, setting and why
│   ├── humanloop.md         HumanLoop design, channels, study coach
│   └── setup-log.md         every command run on this machine, in order
├── logs/                    runtime logs (git-ignored)
└── .vscode/                 tasks, settings, recommended extensions
```

Outside the repo: `~/humanloop` (life model), `~/brain/study` (lectures), `~/.local/share/strata` and `~/.unsloth/studio` (model
servers), `~/.config/sid-cli/clap.json`, `~/Library/LaunchAgents/com.sidlocalai.*.plist`, `~/Library/Logs/sid-*.log`.

## Current stack (decisions)

- **Main model since 2026-10-24:** Strata, Qwen3.8-Flash-Next Gyro-S (125B MoE), 64K context, streaming mode (Charles: the
  bigger model is smarter). Started by `scripts/stack/start-strata.sh`.
- **Fast alternative:** Unsloth Studio, Qwen3.6-35B-A3B UD-Q4_K_XL, 64K (the default 2026-10-23 to 2026-10-24). The Qwen3.8-27B is
  kept for comparison (`start-unsloth.sh 27b`).
- **Context:** 64K, the minimum Hermes accepts. 256K was measured (TODO W2) but is not the default.
- **Hermes title generation off** (`auxiliary.title_generation.model_upgrade_enabled=false`): Strata keeps one cached prompt, and
  the title request evicted it (55 s instead of 6 s for the next question).
- **Google:** one Hermes, three accounts through `gacct` (2026-10-24; separate Hermes profiles rejected as hard to follow).
- **Phone:** Telegram first, then a web app over Tailscale (2026-10-24). Voice notes transcribed locally by faster-whisper `base`.
- **Keep-awake:** no idle sleep while a model serves; closing the lid still sleeps the Mac (2026-10-24).
- Change the default model only after a benchmark and with Sid's say-so; then update the README, `docs/architecture.md`,
  `benchmarks/README.md` and this section.

## Working rules

- **Session start:** `./scripts/stack/status.sh` (or `sid status`), then read the **Next:** line in `TODO.md`.
- **Every command run on the machine** goes into `docs/setup-log.md` as a new numbered section with the date in its heading.
  Never rewrite old sections: they keep paths as they were run (the note at the top maps old paths to new).
- **Every setting and the reason for it** goes into `docs/architecture.md`; HumanLoop and study-coach changes into
  `docs/humanloop.md`.
- **Benchmarks:** same method every time (llama-benchy, 2,048-token prompt + 128 generated tokens, depths 0 / 8K / 32K, thinking
  off, Chrome closed). One folder per run, `benchmarks/<YYYYMMDD-HHMM>-<target>-<label>/` with `environment.txt`, `results.md`
  and `run.log`; never edit a run folder. Keep invalid runs and mark them `-INVALID-<reason>`. Summarise in
  `benchmarks/README.md`.
- **Moving a script:** update the `sid` menu (`cli/src/sid_cli/menu.py`), `.vscode/tasks.json`, compose, the docs and `TODO.md`
  (as in setup-log section 23).
- **Before calling something done,** check what applies: `bash -n` on changed scripts, `status.sh` and `sid status` run, skills
  reinstalled, the Hermes image builds. Say what was and was not checked.
- **Session end:** update `TODO.md` (the Next line and states) and the docs above; commit when Sid asks.

## Documentation

Project conventions:

- `README.md` is the front door; keep it short and current, and link the deeper docs instead of repeating them.
- Ask before creating a new documentation file unless Sid asked for it; prefer updating the existing canonical document.
  *(from Charles)*
- `hermes/skills/*/SKILL.md` are product code (instructions Hermes reads at run time), not docs for coding agents.

Style rules condensed from Charles's `AGENTS.md` (the full version, including mathematics and SVG rules, is in Mission P):

### Markdown metadata

- Use YAML front matter when metadata adds useful, non-obvious context, with fields from Dublin Core and DCMI Metadata Terms
  (`title`, `description`, `creator`, `date`, `created`, `modified`, `source`, ...) rather than invented near-synonyms.
- Omit metadata that merely restates the filename, file format, language, or repository owner.
- Resolve the human `creator` or `contributor` with `gh api user --jq '.login'`; never use an AI model or coding agent as the
  author.
- A new document uses `date`. After its first material revision, keep the original date as `created` and add or update
  `modified`.

### Markdown and diagrams

- Write for quick scanning: short sections, concise prose, tables where structure matters, and at most two TODO levels.
- Prefer Markdown tables, Mermaid diagrams and emojis only when they materially improve comprehension and scanability.
- Document data sources, structures, formats, provenance and retention explicitly. Keep internal links correct when documents
  move or are split.
- Use standard GitHub-flavored Markdown: pipe tables with a `|---|` separator, code fences with a language identifier (`text` for
  literal output), native Markdown over HTML.
- Put a blank line after every heading, and before and after lists, tables, code fences and diagrams.

#### Mermaid diagrams

- Prefer Mermaid for workflows, data flows, system overviews and component relationships; keep each diagram focused and add a
  short lead-in sentence.
- Use `<br/>` inside node labels for line breaks, never `\n`. Prefer `flowchart LR` or `flowchart TB` for flows.
- Dark-mode safe: dark fills with light text; never white or near-white fills.

Color by layer, for this stack's architecture diagrams (cooler for lower tiers, warmer for higher):

```text
classDef hw      fill:#0f172a,color:#93c5fd,stroke:#3b82f6,stroke-width:2px
classDef os      fill:#2e1065,color:#c4b5fd,stroke:#7c3aed
classDef runtime fill:#0c4a6e,color:#7dd3fc,stroke:#0ea5e9
classDef lib     fill:#14532d,color:#86efac,stroke:#22c55e
classDef model   fill:#713f12,color:#fde68a,stroke:#f59e0b
classDef app     fill:#7c2d12,color:#fdba74,stroke:#f97316
classDef ui      fill:#881337,color:#fda4af,stroke:#f43f5e
```

Color by role, for flows:

```text
classDef entry     fill:#1e1b4b,color:#c7d2fe,stroke:#4338ca,stroke-width:2px
classDef process   fill:#0c4a6e,color:#bae6fd,stroke:#0284c7
classDef decision  fill:#431407,color:#fed7aa,stroke:#ea580c
classDef storage   fill:#14532d,color:#bbf7d0,stroke:#16a34a
classDef output    fill:#064e3b,color:#6ee7b7,stroke:#10b981
classDef external  fill:#1c1917,color:#d6d3d1,stroke:#78716c
classDef warning   fill:#7f1d1d,color:#fca5a5,stroke:#ef4444
classDef highlight fill:#4a044e,color:#f0abfc,stroke:#c026d3
```

#### Emojis and file names

- Use functional emojis (✅ ❌ ⚠️ 📝 🔑 💡 📊) when they show status, risk or a callout faster than prose; use them freely in
  internal READMEs, runbooks and diagram labels, not decoratively.
- New prose documents use lowercase kebab-case (`model-switch-runbook.md`); keep conventional uppercase names (`README.md`,
  `AGENTS.md`, `CHANGELOG.md`, `TODO.md`). Do not rename existing documents just to satisfy this.

## TODO rules

- `TODO.md` is the single task ledger, with a **Next:** line at the top. At most two levels: a workstream (`## W<n> — ...`, with
  its owner and date) and its concrete tasks. *(from Charles)*
- States: `[ ]` not started · `[.]` doing · `[~]` deferred or blocked (say which, and why) · `[x]` done · `[-]` cancelled or
  superseded (kept for the audit trail). *(from Charles)*
- Size after the state, `(XS)` to `(L)`; priority written explicitly as `P0` to `P2`. Size is not priority. *(from Charles)*
- Never delete items. Update a task's state when work starts or finishes, with the date and a short result.
- Update `modified` in the front matter when the file changes.

## Changelog

`CHANGELOG.md` does not exist yet (TODO W5). Until it does, `docs/setup-log.md` and commit messages are the journal. When it is
created, follow Charles's rules: append-only, oldest entry first, one entry per work session; record new or materially revised
documents, changed decisions, moves and retirements with links; authors are human GitHub accounts; an AI-assisted entry ends with
`- Provenance: [tool/model/effort]`, runtime-known values only.

## Agent instruction compatibility

- `AGENTS.md` is canonical. `CLAUDE.md` is a relative symbolic link (`ln -s AGENTS.md CLAUDE.md`); never keep a divergent copy.
  *(from Charles)*
- There are no coding-agent skills in this repo. The skills in `hermes/skills/` belong to Hermes; edit them as product code and
  reinstall them.

## Not adopted from Charles's AGENTS.md (and why)

| His rule | Why not here |
|---|---|
| No AI attribution in commits | This repo's convention is a `Co-Authored-By` line (README); Sid's decision whether to align |
| `.data/` data folder | No data folder: personal data lives outside the repo (`~/humanloop`, `~/brain`) |
| `uv` only, `pyproject.toml` + `uv.lock` per component | Adopted for the `sid` CLI; the rest is shell scripts and Docker |
| Bun / Node.js 24 rules | No JavaScript here; bun (HyperFrames skills) and Node 24 (`cf`) are machine tools only |
| Host inventory (m5, unraid1, gpu1, pve1, m4, nano1; Tailscale ssh) | Everything runs on this Mac; Tailscale is planned only for the HumanLoop web app |
| Docker registry, deployments | Local Docker only; nothing is pushed to a registry or deployed |
| Successor-repository rules | Not a successor repo |

## My role

I build and run this stack on my Mac under Charles Cai's mentorship. Charles set most workstreams (TODO W0–W7); HumanLoop (W8) is
mine.
