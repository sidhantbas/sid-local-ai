---
title: Unsloth + Qwen3.8 benchmarks
date: 2026-10-22
creator: sidhantbas
description: llama-benchy and Hermes timings for Qwen3.8-27B and Qwen3.6-35B-A3B (UD-Q4_K_XL) served by Unsloth Studio on the M4 Pro (48 GB), with method and caveats.
---

# Benchmarks

Tool: [llama-benchy](https://github.com/eugr/llama-benchy) 0.4.0 (`uv tool install llama-benchy`).
Script: [`scripts/bench-unsloth.sh`](../scripts/bench-unsloth.sh). Each run folder holds
`results.md` (table), `run.log` (full output) and `environment.txt` (machine, server
command line, memory before/after).

## Method

- Models (both UD-Q4_K_XL, 64K context, 4 slots, Unsloth's default MTP + n-gram drafting):
  `unsloth/Qwen3.8-27B-GGUF` (dense, 17.6 GB, tokenizer `Qwen/Qwen3.8-27B`) and
  `unsloth/Qwen3.6-35B-A3B-MTP-GGUF` (mixture of experts, 3B active, 22.9 GB, tokenizer `Qwen/Qwen3.6-35B-A3B`).
  The script detects the loaded model; switch with `./scripts/start-unsloth.sh [27b|35b-a3b]`.
- Default test: 2048-token prompt, 128 generated tokens, at 0 / 8K / 32K tokens of earlier
  context, 3 runs each, `--no-cache` (no prefix-cache reuse), thinking off.
- Two targets:
  - `--engine`: straight to the llama-server that Unsloth starts (internal port). This is
    the real prompt-processing (pp) and generation (tg) speed.
  - default: Unsloth's API on `:8890`, what Open WebUI and Hermes see. Unsloth opens the
    stream before the prompt is processed, so llama-benchy's pp t/s and ttfr are not
    meaningful here; read `e2e_ttft` (time to the first real token).
- Valid only without swapping: close Chrome and other large apps first. The script warns
  when more than 2 GB of swap is in use.

## Summary: 27B vs 35B-A3B (2026-10-22)

Engine target, 2048-token prompt + 128 generated tokens, 3 runs each (mean):

| | Qwen3.8-27B | Qwen3.6-35B-A3B | Speed-up |
|---|---|---|---|
| Prompt processing, no earlier context | 117.6 t/s | **812.9 t/s** | 6.9x |
| Prompt processing, 8K earlier context | 112.9 t/s | **710.3 t/s** | 6.3x |
| Prompt processing, 32K earlier context | 57.1 t/s ±16 (*) | **516.8 t/s** | 9.0x |
| Generation, no earlier context | 18.9 t/s | **57.6 t/s** | 3.0x |
| Generation, 8K | 19.5 t/s | **42.5 t/s** | 2.2x |
| Generation, 32K | 8.3 t/s ±4 (*) | **32.5 t/s** | 3.9x |
| Time to first token, 2K prompt | 17.3 s | **2.6 s** | |
| Time to first token, 34.8K prompt | 662 s (11 min) | **67 s** | |

(*) The 27B's 32K rows were noisy: swap grew by 1.1 GB during that phase (Chrome was
reopened); the 0 and 8K rows are within ±0.2 t/s.

Hermes Agent, `hermes chat -q "What is the capital of Nepal?" --oneshot -Q`, two runs in a row
(prompt tokens from llama-server's `/metrics`):

| | Qwen3.8-27B | Qwen3.6-35B-A3B |
|---|---|---|
| 1st question (Hermes's ~14,000-token prompt read in full) | 132 s | **31 s** |
| 2nd question (prompt cache: 8 new tokens) | 9 s | **4 s** |

Hermes's slowness on the 27B is its ~14K-token system prompt (tools, skills) read at
~115 t/s. The prompt cache removes that from every following request in the same slot.

## All runs

| Run | Model | Context | Target | pp t/s (d0 / 8K / 32K) | tg t/s (d0 / 8K / 32K) | Valid |
|---|---|---|---|---|---|---|
| [20261022-2326-engine-35b-a3b-ctx64k](20261022-2326-engine-35b-a3b-ctx64k/results.md) | 35B-A3B | 64K | engine | 813 / 710 / 517 | 58 / 42 / 33 | yes |
| [20261022-2205-engine-27b-ctx64k](20261022-2205-engine-27b-ctx64k/results.md) | 27B | 64K | engine | 118 / 113 / 57 | 19 / 20 / 8 | yes; 32K row noisy (*) |
| [20261022-1036-engine-ctx64k](20261022-1036-engine-ctx64k-INVALID-swapping/results.md) | 27B | 64K | engine | 84 / 103 / 51 | 11 / 15 / 9 | **no**: swapping |
| smoke (not kept) | 27B | 64K | engine | 116 (pp512) | 17 (tg32) | 1 run only |

### 2026-10-22 64K engine run: invalid

The run took about 4 hours instead of about 30 minutes. During it, Chrome used 13.3 GB,
the Colima VM 4 GB, llama-server ~28 GB wired for the GPU, macOS compressed 43.5 GB into
11.2 GB and swap was 15.3 of 16 GB. Results vary by up to ±65% between runs.
Kept as a record; repeated as 20261022-2205 with Chrome closed.

## What the numbers mean in practice

- 27B: at ~115 t/s a prompt's length decides the wait: 2K tokens ≈ 18 s, 14K (Hermes) ≈ 2 min,
  a full 256K would be well over an hour (it slows with depth). Generation ~19 t/s ≈ 14 words/s.
- 35B-A3B: 2K ≈ 2.6 s, 14K ≈ 20 s, 34K ≈ 67 s. Generation ~58 t/s ≈ 40 words/s, faster than reading.
- Quality is not measured here: the 27B is dense (all 27B parameters per token), the 35B-A3B
  uses 3B of 35B per token. Both are Qwen; compare answers on real tasks before choosing.
