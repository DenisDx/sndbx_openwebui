# Getting Started

## Docker Compose

```bash
cp .env.example .env
chmod 0600 .env
# set WEBUI_UID/GID to your user, WEBUI_SECRET_KEY, and EXTERNAL_API_BASE_URL
./install.sh
```

Open `http://localhost:<published-ui-port>/`, create the admin account, and use
the preconfigured external-service connection.

## sndbx

```bash
docker build -t open-webui:latest .
sudo ./prepare_host_permissions.sh
```

Merge `config.sndbx.json5` into the root `sndbx` configuration, set
`WEBUI_HOST_ROOT` to this checkout, and start the `open-webui` sandbox.

## External services

Set `EXTERNAL_API_BASE_URL` in `.env` to the address of the external service. The launcher
publishes it to Open WebUI as both an OpenAI-compatible endpoint (`<base>/v1`)
and an Ollama-compatible endpoint (`<base>`). Set `EXTERNAL_API_KEY` only when the
service requires a bearer token.
