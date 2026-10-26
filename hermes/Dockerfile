# Hermes Agent plus local speech-to-text (faster-whisper), so HumanLoop's Telegram voice
# notes are transcribed on the Mac instead of by a cloud service.
#
# Built by docker compose (service hermes in docker/docker-compose.yml). The base is pinned to the digest installed on
# 2026-10-21; the packages are pinned to the versions in Hermes's own uv.lock. Packages go
# into the image, not the running container, so they survive a container recreate. The
# Whisper model itself downloads on first use into the data volume (HF_HOME in compose).
FROM nousresearch/hermes-agent@sha256:7a69201726bc64db2072a1371557137c23312d29705cda2b8ea2a0214a50a4cf

COPY --from=ghcr.io/astral-sh/uv:0.12.1 /uv /usr/local/bin/uv
RUN uv pip install --python /opt/hermes/.venv/bin/python --no-cache \
      faster-whisper==1.2.1 ctranslate2==4.8.1 onnxruntime==1.29.0 av==18.1.0 \
      tokenizers==0.23.1 huggingface-hub==1.24.0 \
 && /opt/hermes/.venv/bin/python -c "import faster_whisper; print('faster-whisper', faster_whisper.__version__)"
