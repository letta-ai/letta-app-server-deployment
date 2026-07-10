# Letta Code Remote Deployment

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/letta-code-remote?utm_medium=integration&utm_source=template&utm_campaign=generic)

Deploy a [Letta Code](https://docs.letta.com/letta-code) remote environment to any cloud platform. Runs `letta server` so your agent is always-on and accessible from [chat.letta.com](https://chat.letta.com) or the [Letta Code](https://letta.com) desktop app.

The Docker image includes common runtime utilities used by Letta Code, tools, skills, cron jobs, and channel runtime installers: `nodejs`, `npm`, `git`, `python`/`python3`, `curl`, `wget`, `jq`, Unix `cron`, process tools such as `ps`, networking tools such as `ip`, `ss`, `ping`, `dig`, `nslookup`, `lsof`, and `nc`, plus `file` for quick file inspection. The image is Bun-based and sets `LETTA_PACKAGE_MANAGER=bun`, so `letta channels install ...` uses Bun by default with npm available as a compatibility fallback.

## How it works

`letta server` opens an outbound WebSocket to Letta Cloud. No inbound ports, no reverse proxy, no domain name needed.

## Authentication

On first deploy, `letta server` starts an OAuth device flow and prints an authorization URL in the logs. Open the URL, approve the request, and the server connects. Auth tokens are persisted under `~/.letta/`, so container deployments need a persistent volume mounted at `/root` to survive restarts.

OAuth is the only authentication method on Pro, Max-lite, and Max plans. On Developer plans, you can alternatively set `LETTA_API_KEY` as an environment variable to skip OAuth.

If you set `LETTA_BASE_URL` to a self-hosted server, device flow is not available. Use `LETTA_API_KEY`.

## Quick start (Docker)

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f
# Check the logs for the OAuth URL and approve it in your browser
```

The included `docker-compose.yml` mounts `letta-data` at `/root`, so auth survives container restarts.

## Deploy to a cloud platform

### DigitalOcean

SSH into a $4/mo droplet and run directly:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs python3 make g++
npm install -g @letta-ai/letta-code

letta server --env-name "cloud"
# Check the output for the OAuth URL and approve it in your browser
```

Or use Docker:

```bash
apt-get install -y docker.io docker-compose-v2
git clone https://github.com/letta-ai/letta-code-server-deployment.git
cd letta-code-server-deployment
cp .env.example .env
docker compose up -d
docker compose logs -f
# Check the logs for the OAuth URL and approve it in your browser
```

If you bootstrap with OAuth over SSH, the saved auth state under `/root/.letta` is reused across restarts.

### Fly.io

```bash
fly launch --name letta-remote --no-deploy
fly volumes create letta_data --region sjc --size 1
fly deploy
fly logs --app letta-remote
# Check the logs for the OAuth URL and approve it in your browser
```

The included `fly.toml` mounts `/root`, so auth survives machine restarts.

### Railway

#### One-click template

Use the **Deploy on Railway** button at the top of this README. The template includes a persistent volume mounted at `/root`.

After deployment, open the deploy logs, find the OAuth URL, and approve it in your browser.

#### Git-backed auto-updating deployment

For deployments that should automatically pick up new Letta Code releases, connect the service to this GitHub repo instead of leaving it as a pinned template snapshot:

- Repository: `letta-ai/letta-code-server-deployment`
- Branch: `main`
- Root directory: `/`
- Builder: Dockerfile
- Volume mount: `/root`
- Automatic deploys: enabled

This repo commits a `letta-code-version.txt` bump whenever a new `@letta-ai/letta-code` npm release ships. Railway then sees a normal Git commit and redeploys services connected to `main`.

Or via CLI:

```bash
railway init
railway up
railway logs
# Check the logs for the OAuth URL and approve it in your browser
```

## Updating

This repo tracks the Letta Code npm release in `letta-code-version.txt`. A scheduled GitHub Actions workflow checks `@letta-ai/letta-code` and commits a version bump to `main` when a new release ships.

That gives Railway a real Git commit to deploy. Any Railway service connected to this repo with automatic deploys enabled will rebuild and install the new Letta Code version without manual redeploys.

Other platforms still update on rebuild:

- **Railway template snapshots**: reconnect the service to `letta-ai/letta-code-server-deployment` on branch `main`, then enable automatic deploys.
- **Fly**: `fly deploy`.
- **Docker Compose**: `docker compose build --pull && docker compose up -d`.

To pin a specific version, set the Docker build arg `LETTA_CODE_VERSION=<version>` or fork this repo and edit `letta-code-version.txt`.

## Channels (Telegram, Discord, Slack, WhatsApp)

To connect your remote agent to [Telegram, Discord, Slack, or WhatsApp](https://docs.letta.com/letta-code/channels):

1. Open the [Letta Code desktop app](https://letta.com).
2. Switch to your remote server in the device picker (bottom left).
3. Open the **Channels** sidebar and add a Telegram bot or Slack app.

Configuration, pairing, and binding all happen through the app's WebSocket control channel — no shell access or env vars needed on the server.

Enabled channel adapters are restored automatically after container restarts. You should not need to edit the Railway start command or add `--channels telegram` manually.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LETTA_API_KEY` | optional | Your Letta API key from [app.letta.com](https://app.letta.com). Developer plans only. If unset, the server uses OAuth device flow. Required for self-hosted deployments. |
| `ENV_NAME` | `cloud` | Name shown in the environment picker on chat.letta.com |
| `LETTA_RESTORE_ENABLED_CHANNELS` | `1` | Restores enabled channel adapters from the persistent volume when the server starts. Keep this enabled for Telegram, Discord, Slack, and WhatsApp remotes. |
| `LETTA_PACKAGE_MANAGER` | `bun` | Package manager used by Letta Code for runtime installs and self-update operations. The Docker image defaults this to Bun because Letta Code is installed with Bun in the image; npm is also present as a fallback. |
| `LETTA_BASE_URL` | `https://api.letta.com` | Override for self-hosted Letta servers. |

## Verify

1. Deploy using any method above
2. Open [chat.letta.com](https://chat.letta.com) or the [Letta Code](https://letta.com) desktop app
3. Select your remote environment from the picker (bottom left)
4. Send a message

## Docs

- [Remote environments](https://docs.letta.com/letta-code/remote)
- [Letta Code](https://docs.letta.com/letta-code)
