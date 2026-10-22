---
title: sid-local-ai TODO
created: 2026-10-22
modified: 2026-10-22
creator: sidhantbas
description: Task ledger for the local AI stack. Open work as small units with status, size and priority, grouped by workstream; done items stay in place.
---

# TODO

**Next:** decide 27B vs 35B-A3B as the default (W1: 35B-A3B is 6.9x faster on prompts, 3x on generation; Hermes 31 s vs 132 s cold); Sid logs in to `hf` and `cf` (W4); then 256K context (W2). Running now: Qwen3.6-35B-A3B.

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
- [ ] (XS) P0 Decide the default model with Charles (speed above; quality not yet compared)
- [ ] (S) P1 Through-Unsloth runs (`:8890`, e2e_ttft) for both models
- [ ] (S) P0 Same run at 256K context (after W2) to show the cost of the larger context
- [ ] (S) P0 `benchmarks/`: raw output + `README.md` (machine, model, flags, commands, results table)
- [ ] (XS) P0 Send Charles the summary table

## W2 — Full 256K context (P0, Charles 2026-10-22)

- [ ] (S) P0 `start-unsloth.sh`: `--max-seq-length 262144`; restart and measure RAM (64K = ~23.7 GB; estimate ~33 GB at 256K, to verify)
- [ ] (XS) P0 Hermes `model.context_length` 262144
- [ ] (XS) P0 Architecture doc + setup log updated with measured RAM

## W3 — Hermes latency (P1, Charles 2026-10-22)

- [x] (S) P1 Time "what is the capital of Nepal" in Hermes: 27B 132 s cold / 9 s cached, 35B-A3B 31 s / 4 s; cause: Hermes's ~14K-token prompt at ~115 t/s ([benchmarks](benchmarks/README.md), 2026-10-22)
- [ ] (M) P1 Test the suspects: Hermes system prompt size (tools/skills) at ~116 t/s prompt processing, Qwen3.8 thinking at its template default `xhigh`, Unsloth's reasoning wrapper and server-side tools (~2.3K tokens/request); apply what helps, record before/after

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
