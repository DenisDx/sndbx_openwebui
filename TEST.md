# Test Protocol

Static checks run without Docker. The build and runtime checks require Docker.

## Static checks

```bash
bash -n docker/entrypoint.sh docker/start-open-webui.sh docker/load-open-webui-env.sh
bash -n install.sh deploy.sh prepare_host_permissions.sh grant_current_user_data_access.sh run_after_restore.sh
python3 -m py_compile app.py
```

- Confirm `config.sndbx.json5` parses as JSON5 and contains no trailing commas.
- Confirm `.env` and `.env.example` expose the same keys.
- Confirm no real address, port, or secret appears in Git-tracked files (only
  `.env` and `data/` may hold environment-specific values).

## Image build

```bash
docker build -t open-webui:latest .
docker run --rm --entrypoint bash open-webui:latest -lc 'id openwebui; test -f /app/backend/start.sh && echo start-sh-ok'
```

Expected: the build finishes and the `openwebui` account and `start.sh` exist.

## Runtime (Docker Compose)

```bash
cp .env.example .env
./install.sh
docker compose ps
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:<published-ui-port>/health
```

Expected: the service is running and `/health` returns HTTP 200 with
`{"status":true}`.

## Runtime identity

```bash
docker compose exec open-webui id openwebui
ls -ln data | head
```

Expected: the app runs as the configured `WEBUI_UID:WEBUI_GID` and files created
under `data/` are owned by that UID/GID.

## aidir integration

```bash
curl -s -o /dev/null -w '%{http_code}\n' "${AIDIR_BASE_URL}/health"
curl -s "${AIDIR_BASE_URL}/v1/models" | head
```

Expected: the health check and the OpenAI-compatible models list succeed from
inside the VM, and the aidir connection appears under Settings -> Connections.
