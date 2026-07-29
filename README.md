# Letta Code Remote Deployment

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/letta-code-remote?utm_medium=integration&utm_source=template&utm_campaign=generic)

Deploy a [Letta Code](https://docs.letta.com/letta-code) remote environment to any cloud platform. Runs `letta server` so your agent is always-on and accessible from [chat.letta.com](https://chat.letta.com) or the [Letta Code](https://letta.com) desktop app.

The Docker image includes common runtime utilities used by Letta Code, tools, skills, cron jobs, and channel runtime installers: `nodejs`, `npm`, `git`, `python3`, `curl`, `wget`, `jq`, and Unix `cron`. The image is Bun-based and sets `LETTA_PACKAGE_MANAGER=bun`, so `letta channels install ...` uses Bun by default with npm available as a compatibility fallback.

On every boot, the container also restores Unix cron definitions from persistent storage before starting `letta server`. By default it looks under `/root/.letta`, matching this repo's `/root` volume examples, but you can point it at any durable mount with `LETTA_SYSTEM_CRON_DIR` and `LETTA_SYSTEM_ROOT_CRONTAB`.

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

## Persistent Unix cron

If you want token-free scheduled jobs such as tweet posting, backups, or health checks, store cron definitions on a persistent volume instead of editing `/etc/cron.d` directly. The default paths use `/root/.letta` because this repo's Docker Compose, Fly, and Railway examples mount durable storage at `/root`; if your platform mounts storage somewhere else, set `LETTA_SYSTEM_CRON_DIR` and `LETTA_SYSTEM_ROOT_CRONTAB` to paths on that mount.

### Supported persistent paths

- `/root/.letta/system-cron/`: files copied into `/etc/cron.d/` on every boot
- `/root/.letta/system-crontab/root`: optional root crontab installed on every boot

For a durable mount at another path, for example `/data`, use:

```bash
LETTA_SYSTEM_CRON_DIR=/data/letta/system-cron
LETTA_SYSTEM_ROOT_CRONTAB=/data/letta/system-crontab/root
```

Anything written directly into `/etc/cron.d` or the live root crontab inside a running container is ephemeral and can be lost when the container is restarted, rebuilt, redeployed, or replaced.

### Example cron file

```cron
*/15 * * * * root flock -n /tmp/tweet-poster.lock /root/.letta/x_twitter/post_tweets.sh >> /root/.letta/logs/tweet-poster.log 2>&1
```

Place your shell script and logs on the same durable volume. If your persistent mount is `/data`, update the paths in the cron command to `/data/...` too.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LETTA_API_KEY` | optional | Your Letta API key from [app.letta.com](https://app.letta.com). Developer plans only. If unset, the server uses OAuth device flow. Required for self-hosted deployments. |
| `ENV_NAME` | `cloud` | Name shown in the environment picker on chat.letta.com |
| `LETTA_RESTORE_ENABLED_CHANNELS` | `1` | Restores enabled channel adapters from the persistent volume when the server starts. Keep this enabled for Telegram, Discord, Slack, and WhatsApp remotes. |
| `LETTA_SYSTEM_CRON_DIR` | `/root/.letta/system-cron` | Directory on durable storage whose files are copied into `/etc/cron.d/` on every boot. Change this if your persistent volume is mounted somewhere other than `/root`. |
| `LETTA_SYSTEM_ROOT_CRONTAB` | `/root/.letta/system-crontab/root` | Optional root crontab file on durable storage, installed with `crontab` on every boot. Change this if your persistent volume is mounted somewhere other than `/root`. |
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
