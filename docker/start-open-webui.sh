#!/usr/bin/env bash
# Default Open WebUI launcher: derive the external service connections from
# AIDIR_BASE_URL, then run the user start script when present, otherwise start
# the bundled server.
set -Eeuo pipefail

source /usr/local/lib/open-webui/load-env.sh

export HOME="${WEBUI_HOME:-/app/backend/data}"
export PORT="${WEBUI_PORT:-${PORT:-8080}}"
export HOST="${WEBUI_BIND_HOST:-${HOST:-0.0.0.0}}"

# Point Open WebUI at the external service (for example aidir) through both its
# OpenAI-compatible and Ollama-compatible APIs. Explicit values win.
if [[ -n "${AIDIR_BASE_URL:-}" ]]; then
    aidir_base="${AIDIR_BASE_URL%/}"
    export OPENAI_API_BASE_URLS="${OPENAI_API_BASE_URLS:-${aidir_base}/v1}"
    export OPENAI_API_KEYS="${OPENAI_API_KEYS:-${AIDIR_API_KEY:-none}}"
    export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-${aidir_base}}"
fi
export ENABLE_OPENAI_API="${ENABLE_OPENAI_API:-true}"
export ENABLE_OLLAMA_API="${ENABLE_OLLAMA_API:-true}"

start_script="${HOME}/config/start.sh"
if [[ -x "${start_script}" ]]; then
    exec "${start_script}"
fi

cd /app/backend
exec bash start.sh
