#!/usr/bin/env bash
# Container entrypoint: align the app user with the requested UID/GID, repair
# ownership of the persistent data directory, then drop privileges and start
# Open WebUI.
set -Eeuo pipefail

source /usr/local/lib/open-webui/load-env.sh

export HOME="${WEBUI_HOME:-/app/backend/data}"

target_uid="${WEBUI_UID:-${USER_UID:-1000}}"
target_gid="${WEBUI_GID:-${USER_GID:-1000}}"
home_dir="${HOME}"
ownership_marker="${home_dir}/.open-webui-ownership-verified"

if [[ "$(id -u)" -ne 0 ]]; then
    if [[ "$(id -u)" -ne "${target_uid}" || "$(id -g)" -ne "${target_gid}" ]]; then
        printf 'running unprivileged as %s:%s; cannot remap to %s:%s\n' \
            "$(id -u)" "$(id -g)" "${target_uid}" "${target_gid}" >&2
    fi
    exec "$@"
fi

# Remap the packaged openwebui account only when the requested identity differs.
if [[ "$(id -u openwebui)" -ne "${target_uid}" ]]; then
    printf 'updating openwebui UID to %s\n' "${target_uid}" >&2
    usermod -o -u "${target_uid}" openwebui
fi
if [[ "$(id -g openwebui)" -ne "${target_gid}" ]]; then
    printf 'updating openwebui GID to %s\n' "${target_gid}" >&2
    groupmod -o -g "${target_gid}" openwebui
    usermod -g "${target_gid}" openwebui
fi

# The mounted read-only environment file keeps its host ownership and is never
# touched.
external_env="${home_dir}/.env"

# find_foreign prints the first data entry not owned by openwebui below an
# optional depth, skipping the read-only environment file.
find_foreign() {
    local max_depth="$1"
    local -a cmd=(find "${home_dir}")
    if [[ -n "${max_depth}" ]]; then
        cmd+=(-maxdepth "${max_depth}")
    fi
    cmd+=(-path "${external_env}" -prune -o \( ! -user openwebui -o ! -group openwebui \) -print -quit)
    "${cmd[@]}" 2>/dev/null || true
}

# repair_ownership restores openwebui ownership, skipping the read-only env file.
repair_ownership() {
    find "${home_dir}" -path "${external_env}" -prune -o -exec chown openwebui:openwebui {} +
}

if [[ -d "${home_dir}" ]]; then
    expected_marker="v1 $(id -u openwebui):$(id -g openwebui)"
    current_marker="$(cat "${ownership_marker}" 2>/dev/null || true)"
    if [[ -n "$(find_foreign 3)" ]]; then
        printf 'repairing ownership of %s\n' "${home_dir}" >&2
        repair_ownership
    elif [[ "${current_marker}" != "${expected_marker}" ]]; then
        if [[ -z "$(find_foreign '')" ]]; then
            gosu openwebui sh -c 'printf "%s\n" "$1" > "$2"' sh "${expected_marker}" "${ownership_marker}" 2>/dev/null || true
        else
            printf 'repairing ownership of %s\n' "${home_dir}" >&2
            repair_ownership
        fi
    fi
fi

printf 'starting open webui as openwebui (%s:%s)\n' "$(id -u openwebui)" "$(id -g openwebui)" >&2
exec gosu openwebui "$@"
