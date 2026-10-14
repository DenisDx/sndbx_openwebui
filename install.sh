#!/usr/bin/env bash
# Install and start the Docker Compose Open WebUI service for this checkout.
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly script_dir
readonly environment_file="${script_dir}/.env"
readonly service_name="open-webui"

prepare_environment() {
    if [[ ! -f "${environment_file}" ]]; then
        cp "${script_dir}/.env.example" "${environment_file}"
        chmod 0600 "${environment_file}"
    fi

    if grep --quiet '^WEBUI_SECRET_KEY=replace-with-a-long-random-secret$' "${environment_file}"; then
        local secret
        secret="$(openssl rand -hex 32)"
        sed -i "s/^WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${secret}/" "${environment_file}"
        unset secret
    fi
}

main() {
    prepare_environment
    "${script_dir}/deploy.sh"
    printf '\nOpen WebUI is starting at http://localhost:%s\n' \
        "$(sed -n 's/^WEBUI_HOST_PORT=//p' "${environment_file}" | head -n1)"
    printf 'Set EXTERNAL_API_BASE_URL in .env to the external service address before use.\n'
    docker compose --project-directory "${script_dir}" logs --tail 20 "${service_name}" || true
}

main "$@"
