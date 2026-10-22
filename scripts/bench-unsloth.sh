#!/usr/bin/env bash
# Benchmark the running Unsloth server with llama-benchy (uv tool install llama-benchy).
# Each run gets its own folder in benchmarks/ with the results table, the full log
# and the server settings it ran against.
#
#   ./scripts/bench-unsloth.sh [--engine] <label> [llama-benchy args]
#   ./scripts/bench-unsloth.sh ctx64k             # through Unsloth's API (:8890), what apps see
#   ./scripts/bench-unsloth.sh --engine ctx64k    # straight to Unsloth's llama-server
#   ./scripts/bench-unsloth.sh smoke --pp 512 --tg 32 --depth 0 --runs 1
#
# Through Unsloth, the stream opens before the prompt is processed, so llama-benchy's
# pp t/s and ttfr are not meaningful there; use e2e_ttft, or --engine for pp t/s.
# Thinking is turned off so that generated tokens are answer tokens.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

target=unsloth
[ "${1:-}" = "--engine" ] && { target=engine; shift; }
label="${1:?usage: bench-unsloth.sh [--engine] <label> [llama-benchy args]}"; shift
out="benchmarks/$(date +%Y%m%d-%H%M)-${target}-${label}"

if [ "${target}" = engine ]; then
  # llama-server's port and key file are only visible on its command line
  engine_args="$(pgrep -fl llama-server | head -1 | tr ' ' '\n')"
  base_url="http://127.0.0.1:$(grep -A1 -x -- --port <<<"${engine_args}" | tail -1)/v1"
  api_key="$(cat "$(grep -A1 -x -- --api-key-file <<<"${engine_args}" | tail -1)")"
else
  base_url="http://127.0.0.1:${UNSLOTH_PORT}/v1"
  api_key="${UNSLOTH_API_KEY}"
fi
mkdir -p "${out}"

{
  echo "date: $(date '+%F %T %Z')"
  echo "machine: $(sysctl -n machdep.cpu.brand_string), $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
  echo "llama-benchy: $(llama-benchy --version 2>&1)"
  echo "target: ${target} (${base_url})"
  echo "unsloth: $(pgrep -fl 'unsloth studio run' | head -1 | sed 's/--api-key[^ ]* [^ ]*//')"
  echo "llama-server: $(pgrep -fl llama-server | head -1 | sed 's/--api-key [^ ]*//')"
  echo "llama-server RSS: $(( $(ps -o rss= -p "$(pgrep -f llama-server | head -1)") / 1024 )) MB"
} > "${out}/environment.txt"

# defaults: 2K prompt + 128 generated tokens at 0 / 8K / 32K of earlier context,
# 3 runs each, no prefix cache reuse; any args after the label override these
args=(--pp 2048 --tg 128 --depth 0 8192 32768 --runs 3)
[ $# -gt 0 ] && args=("$@")

llama-benchy \
  --base-url "${base_url}" \
  --api-key "${api_key}" \
  --model unsloth/Qwen3.8-27B-GGUF \
  --tokenizer Qwen/Qwen3.8-27B \
  --no-cache --latency-mode generation \
  --extra-body 'chat_template_kwargs={"enable_thinking": false}' \
  --format md --save-result "${out}/results.md" \
  "${args[@]}" 2>&1 | tee "${out}/run.log"

echo "saved: ${out}"
