---
title: sid-local-ai TODO
created: 2026-10-22
modified: 2026-10-24
creator: sidhantbas
description: Task ledger for the local AI stack. Open work as small units with status, size and priority, grouped by workstream; done items stay in place.
---

# TODO

**Next:** Sid signs in the two other Google accounts for Hermes (W3b) and logs in to `hf` and `cf` (W4); compare answer quality of Strata Gyro-S and the 35B-A3B on real tasks (W1). Main model since 2026-10-24: Strata Qwen3.8-Flash-Next Gyro-S, 64K (`scripts/start-strata.sh`, close Chrome first); `scripts/start-unsloth.sh` switches to the faster Qwen3.6-35B-A3B.

States: `[ ]` not started · `[.]` doing · `[~]` deferred or blocked (reason given) · `[x]` done · `[-]` cancelled or superseded.
Size `(XS)`–`(L)` after the state; priority `P0` (first) to `P2`. At most two levels. Items are never deleted.

## W0 — Initial setup (Charles, 2026-10-19)

- [x] Private repo `sidhantbas/sid-local-ai`
- [x] Colima Docker runtime (2 GB, raised to 4 GB with Charles's OK)
- [x] Open WebUI in Docker, connected to Unsloth on port 8890
- [x] Unsloth Studio + Qwen3.8-27B UD-Q4_K_XL
- [x] Hermes Agent via docker compose on the local model
- [x] uv + bun; HyperFrames skills via bun
- [x] gws CLI: 3 profiles tested with Gmail / Calendar / Tasks
- [x] Start/stop/status scripts and docs
- [x] `sid` CLI with double-clap launcher (2026-10-22)
- [ ] (XS) P1 Allow microphone for Python, then test lock → unlock → double clap

## W1 — Benchmark Unsloth + Qwen3.8 with llama-benchy (P0, Charles 2026-10-22)

- [x] (S) P0 Find llama-benchy, install with `uv tool install` (0.4.0; `scripts/bench-unsloth.sh`, 2026-10-22)
- [x] (M) P0 Baseline at 64K context, engine target, depths 0 / 8K / 32K: 27B pp 118 / 113 / 57 t/s, tg 19 / 20 / 8 t/s ([benchmarks](benchmarks/README.md), 2026-10-22; first run invalid, swapping)
- [x] (M) P0 Qwen3.6-35B-A3B (UD-Q4_K_XL, MTP) downloaded, SHA-256 checked, same benchmark: pp 813 / 710 / 517 t/s, tg 58 / 42 / 33 t/s (2026-10-22)
- [x] (XS) P0 Default model: Qwen3.6-35B-A3B (Sid, 2026-10-23); `start-unsloth.sh 27b` keeps the 27B
- [ ] (S) P1 Compare 27B vs 35B-A3B answer quality on a few real tasks
- [ ] (S) P1 Through-Unsloth runs (`:8890`, e2e_ttft) for both models
- [x] (S) P0 256K run (35B-A3B): pp 775 / 496 / 202 t/s at 0 / 32K / 128K, first token after 133K tokens 11 min (2026-10-23)
- [ ] (S) P0 `benchmarks/`: raw output + `README.md` (machine, model, flags, commands, results table)
- [ ] (XS) P0 Send Charles the summary table

## W2 — Full 256K context (P0, Charles 2026-10-22)

- [x] (S) P0 `start-unsloth.sh`: `UNSLOTH_CONTEXT=262144`; wired memory 28.2 → 33.5 GB, swap +4.2 GB under load; default stays 64K (2026-10-23)
- [x] (XS) P0 Hermes `model.context_length` follows the server: `start-unsloth.sh` sets it (and `model.default`) when Hermes runs (2026-10-23)
- [x] (XS) P0 Architecture doc + setup log updated with measured RAM (2026-10-23)

## W3 — Hermes latency (P1, Charles 2026-10-22)

- [x] (S) P1 Time "what is the capital of Nepal" in Hermes: 27B 132 s cold / 9 s cached, 35B-A3B 31 s / 4 s; cause: Hermes's ~14K-token prompt at ~115 t/s ([benchmarks](benchmarks/README.md), 2026-10-22)
- [ ] (M) P1 Test the suspects: Hermes system prompt size (tools/skills) at ~116 t/s prompt processing, Qwen3.8 thinking at its template default `xhigh`, Unsloth's reasoning wrapper and server-side tools (~2.3K tokens/request); apply what helps, record before/after

## W3b — Hermes + Google (P1, Sid 2026-10-23)

- [x] (S) P1 Hermes `google-workspace` skill logged in as sidhantbastola7 (full scopes, Sid's choice over a read-only bridge); token mode 600 (2026-10-23)
- [x] (S) P1 "Check my unread emails" works one-shot in 51 s with `-s google-workspace -t terminal --reasoning low`; full toolset ran 10+ min (2026-10-23)
- [x] (XS) P1 `sid` menu item 8: check mail
- [-] (S) P2 Other two accounts (sibastola6ucl, disisidstudio): Hermes profiles with their own Google login; superseded: one Hermes, one login folder per account (Sid, 2026-10-24: profiles would be hard to follow)
- [x] (S) P1 `google-accounts` skill (`hermes/skills/`, installed by `scripts/install-hermes-skills.sh`): `gacct <account|all> ...` runs google-workspace as one account or all; logins in `/opt/data/google-accounts/<account>/`; main login moved there (2026-10-24)
- [.] (XS) P1 Sid signs in sibastola6ucl and disisidstudio (link from `setup.py --auth-url` with that account's folder as HERMES_HOME)
- [ ] (XS) P2 Enable Drive / Docs / Sheets / People APIs in the GCP project if Hermes should use them

## W4 — CLI tools installed and authenticated (P1, Charles 2026-10-22)

- [.] (S) P1 `hf`: installed with `uv tool` (2.2.0, ahead of the Anaconda copy on PATH); Sid runs `hf auth login`, verify `hf auth whoami`
- [x] (XS) P1 `gh`: 2.93.0 already logged in as sidhantbas; `gh repo view sidhantbas/sid-local-ai` works (2026-10-22)
- [.] (S) P1 `cf`: Cloudflare's new CLI (open beta), `npm install --global cf` 1.0.0-beta.20 on Node 24 (Homebrew `node@24` first on PATH in `~/.zshrc`); Sid runs `cf auth login`
- [ ] (XS) P1 Install + login commands in `docs/setup-log.md` (no tokens in the repo)

## W5 — VS Code, clean and inspectable (P1, Charles 2026-10-22)

- [ ] (S) P1 VS Code workspace: `.vscode/settings.json`, recommended extensions, tasks for start/stop/status/benchmark
- [x] (S) P1 `TODO.md` in Charles's format (this file, 2026-10-22)
- [ ] (XS) P1 `CHANGELOG.md`, one dated entry per session
- [ ] (S) P1 AGENTS.md copied from Charles's original; `CLAUDE.md` symlink to it

## W6 — Naming (P2)

- [ ] (XS) P2 Confirm with Charles what "final name" refers to (repo, CLI or the whole stack) and reply

## W7 — Strata, the main model (P1, Charles 2026-10-22; main since 2026-10-24)

- [x] (S) P2 Read Niko1221/Strata (v0.2.2): its Mac engine runs only Qwen3.8-Flash-Next (125B MoE); on 48 GB that means the Gyro-S pack (~38 GB resident); Qwen3.6-35B-A3B is not supported on Mac (2026-10-22)
- [x] (M) P2 Benchmark Strata Gyro-S (streaming, 22.7 GB arena) with the same method: prompt 289 / 279 / 287 t/s, generation 29 t/s at 0 / 8K / 32K; Hermes 58 s / 55 s (no prompt-cache reuse); 35B-A3B on Unsloth stays the default (Sid, 2026-10-23)
- [x] (XS) P2 Ask Charles whether to keep Strata installed (54 GB on disk) for quality tests: keep it, Strata's Qwen3.8-Flash-Next should be the main model (Charles, 2026-10-24)
- [x] (S) P1 Find why Hermes's second question took 55 s on Strata: Strata keeps one cached prompt, and Hermes's session-title request replaced it; fixed with `auxiliary.title_generation.model_upgrade_enabled false` (5-6 s now; `--parallel 2` did not help) (Sid, 2026-10-24)
- [x] (S) P1 Make Strata the main model: `scripts/start-strata.sh` / `stop-strata.sh` (each start script stops the other server and points Hermes at itself), `sid` start stack and status, Open WebUI's second connection (Sid, 2026-10-24)
- [ ] (XS) P1 Tell Charles: Strata is the main model, the Hermes cache fix, and that Strata is faster with Chrome closed (arena sized at start)
- [ ] (S) P2 Ask Strata (Niko1221) whether its prompt cache can keep more than one prompt or rewind to a checkpoint, like llama-server's `--ctx-checkpoints`
