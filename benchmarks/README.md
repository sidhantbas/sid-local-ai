---
title: Unsloth + Qwen3.8 benchmarks
date: 2026-10-22
creator: sidhantbas
description: llama-benchy results for Qwen3.8-27B UD-Q4_K_XL served by Unsloth Studio on the M4 Pro (48 GB), with method and caveats.
---

# Benchmarks

Tool: [llama-benchy](https://github.com/eugr/llama-benchy) 0.4.0 (`uv tool install llama-benchy`).
Script: [`scripts/bench-unsloth.sh`](../scripts/bench-unsloth.sh). Each run folder holds
`results.md` (table), `run.log` (full output) and `environment.txt` (machine, server
command line, memory before/after).

## Method

- Model: `unsloth/Qwen3.8-27B-GGUF` UD-Q4_K_XL, tokenizer `Qwen/Qwen3.8-27B`.
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

## Results

| Run | Context | Target | pp t/s | tg t/s | Time to first token | Valid |
|---|---|---|---|---|---|---|
| [smoke](#smoke-test) | 64K | engine | 116 (pp512) | 17 (tg32) | 4.2 s | yes, 1 run only |
| [20261022-1036-engine-ctx64k](20261022-1036-engine-ctx64k-INVALID-swapping/results.md) | 64K | engine | 84 / 103 / 51 | 11 / 15 / 9 | 26 s / 100 s / 815 s | **no**: swapping |

Columns with three values are depth 0 / 8K / 32K.

### Smoke test

`--pp 512 --tg 32 --depth 0 --runs 1` against the engine, 2026-10-22 10:36: pp512
116.4 t/s, tg32 17.3 t/s, time to first token 4.2 s (folder not kept).

### 2026-10-22 64K engine run: invalid

The run took about 4 hours instead of about 30 minutes. During it, Chrome used 13.3 GB,
the Colima VM 4 GB, llama-server ~28 GB wired for the GPU, macOS compressed 43.5 GB into
11.2 GB and swap was 15.3 of 16 GB. Results vary by up to ±65% between runs.
Kept as a record; to be repeated with Chrome closed.

## What the numbers mean in practice

At ~116 t/s prompt processing, a prompt's length decides the wait before the first word:
2K tokens ≈ 18 s, 20K ≈ 3 min, a full 256K ≈ 37 min or more (it slows with depth).
Generation at ~17 t/s ≈ 12 words/s.
