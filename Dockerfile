FROM oven/bun:slim

# Install Letta Code
# git: required at runtime for memory sync
# python3: required at runtime for skills (e.g. Discord)
# curl/wget: common in tool and skill examples for fetching remote assets/APIs
# jq: common in API/debug examples for inspecting JSON responses
# cron: Unix cron daemon for non-LLM scheduled jobs
# Node 22: required by the installed letta CLI entrypoint and node-gyp's current undici dependency during native rebuilds
# npm: fallback package manager for channel runtime installs and remote shell use.
# It is installed with Bun below instead of Debian's npm package to avoid
# pulling a large extra dependency tree into the runtime image.
ENV BUN_INSTALL_GLOBAL_DIR=/opt/letta-code \
    DEBIAN_FRONTEND=noninteractive
# The CLI is installed with Bun into /opt, so path-based package-manager
# detection would otherwise fall back to npm. Prefer Bun for channel runtime
# installs while still shipping npm as a compatibility fallback.
ENV LETTA_PACKAGE_MANAGER="bun"

# The GitHub workflow keeps this file at the latest published npm version.
# Railway services connected to this repo can then auto-deploy from Git commits
# instead of staying pinned to the version baked into the first build.
ARG LETTA_CODE_VERSION=""
COPY letta-code-version.txt /tmp/letta-code-version.txt
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates cron curl git python3 wget jq make g++; \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -; \
    apt-get install -y nodejs; \
    version="${LETTA_CODE_VERSION:-$(cat /tmp/letta-code-version.txt)}"; \
    bun install -g "@letta-ai/letta-code@${version}" "npm@10"; \
    chmod +x /usr/local/bin/entrypoint.sh; \
    apt-get purge -y make g++; \
    apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*

ENV ENV_NAME="cloud"
ENV LETTA_RESTORE_ENABLED_CHANNELS="1"
ENV LETTA_SYSTEM_CRON_DIR="/root/.letta/system-cron"
ENV LETTA_SYSTEM_ROOT_CRONTAB="/root/.letta/system-crontab/root"

CMD ["/usr/local/bin/entrypoint.sh"]
