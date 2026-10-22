# Commands

Run commands from the Open WebUI checkout unless stated otherwise.

## Docker Compose

```bash
docker compose build
sudo ./prepare_host_permissions.sh
bash ./deploy.sh
docker compose ps
docker compose logs -f open-webui
docker compose exec open-webui bash
docker compose restart open-webui
docker compose stop open-webui
docker compose down
```

`deploy.sh` asks for `sudo` and grants the invoking user and the container UID
ACL access only inside this checkout, then rebuilds and recreates the service.

## Open WebUI

```bash
curl -s "http://127.0.0.1:<published-ui-port>/health"
```

## sndbx

```bash
docker build -t open-webui:latest .
```

Merge `sndbx.overlay.json5` into the root configuration, then start the
`open-webui` sandbox with the normal sndbx operator command or UI. Use
`OPEN_WEBUI_*` variables in the root `.env` for optional resource and port
overrides.

With public keys configured in the sandbox's `ssh_keys` list:

```bash
ssh -p <published-ssh-port> openwebui@127.0.0.1
```

## Backup and restore

```bash
docker compose stop open-webui
rsync -aAX --numeric-ids data/ /backup/open-webui-data/
rsync -aAX --numeric-ids /backup/open-webui-data/ data/
sudo ./run_after_restore.sh
docker compose up -d
```

## Permissions

```bash
sudo ./grant_current_user_data_access.sh
sudo ./run_after_restore.sh
```
