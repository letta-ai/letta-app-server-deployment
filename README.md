# Letta computer deployment

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/letta-code-remote?utm_medium=integration&utm_source=template&utm_campaign=generic)

Run an always-on [computer](https://docs.letta.com/platform/computers/byom) for agents hosted in Letta Cloud. The container connects outward to Letta Cloud and appears in the computer picker in the Letta app and chat.letta.com.

## Docker Compose

```bash
cp .env.example .env
docker compose up --build -d
docker compose logs -f
```

If `LETTA_API_KEY` is unset, the logs print an OAuth authorization URL. Open it and approve the computer. The Compose configuration persists Letta settings and gives the computer a persistent `/workspace` volume.

No inbound port, reverse proxy, or domain is required.

## Configuration

- `ENV_NAME` controls the name shown in the computer picker.
- `LETTA_API_KEY` skips OAuth on plans that support API-key computer authentication.
- `LETTA_RESTORE_ENABLED_CHANNELS=1` restores configured channel adapters after restart.
- `LETTA_BASE_URL` points the computer at another Letta API deployment.
- `LETTA_SYSTEM_CRON_DIR` and `LETTA_SYSTEM_ROOT_CRONTAB` restore Unix cron files from persistent storage on boot. Their defaults are under `/root/.letta`.

Files stored directly in `/etc/cron.d` disappear when a container is replaced. Put persistent definitions under `/root/.letta/system-cron`, and put an optional root crontab at `/root/.letta/system-crontab/root`.

The Dockerfile uses `ghcr.io/letta-ai/letta-code:latest`. Pin a release when reproducible builds matter:

```bash
docker build \
  --build-arg LETTA_CODE_IMAGE=ghcr.io/letta-ai/letta-code:0.30.21 \
  -t my-letta-computer .
```

See [Bring Your Own Machine](https://docs.letta.com/platform/computers/byom) for provider-specific deployment instructions, authentication, and verification.
