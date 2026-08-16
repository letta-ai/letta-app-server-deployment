# Letta App Server deployment

Deploy [Letta App Server](https://docs.letta.com/platform/app-server) with Docker and connect through the [Letta Agent SDK](https://docs.letta.com/agent-sdk).

## Docker Compose

```bash
cp .env.example .env
# Replace LETTA_APP_SERVER_TOKEN and set a model provider key in .env.
docker compose up --build -d
docker compose logs -f
```

App Server listens on `http://localhost:4500`. The Compose configuration keeps agent state in `letta-state` and gives agents a persistent `/workspace` volume.

Connect from a Node.js application:

```typescript
import { LettaAgentClient } from "@letta-ai/letta-agent-sdk";

const client = new LettaAgentClient({
  backend: "remote",
  url: "http://localhost:4500",
  authToken: process.env.LETTA_APP_SERVER_TOKEN,
});
```

The SDK converts HTTP and HTTPS base URLs to WS and WSS connections at `/ws`.

## Configuration

- `LETTA_APP_SERVER_TOKEN` is required. Generate one with `openssl rand -hex 32`.
- `LETTA_BACKEND=local` keeps agent state in the mounted Letta directory.
- `LETTA_BACKEND=cloud` keeps agent state in Letta Cloud and requires `LETTA_API_KEY`.
- `PORT` defaults to `4500`.
- Session `cwd` values must point to directories inside the container, such as `/workspace`.

For production, terminate TLS in front of App Server and connect with an HTTPS or WSS URL. The included Fly.io and Railway configurations proxy WebSockets and check `/readyz`.

## Image version

The Dockerfile uses `ghcr.io/letta-ai/letta-code:latest`. Pin a release when reproducible builds matter:

```bash
docker build \
  --build-arg LETTA_CODE_IMAGE=ghcr.io/letta-ai/letta-code:0.30.21 \
  -t my-letta-app-server .
```

See [Deploying your agents](https://docs.letta.com/agent-sdk/deployment) for backend choices and the [App Server Docker guide](https://docs.letta.com/agent-sdk/examples/docker) for complete deployment guidance.
