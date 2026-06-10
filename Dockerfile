FROM oven/bun:slim

# Install Letta Code and the baseline tools needed by remote coding agents.
ENV BUN_INSTALL_GLOBAL_DIR=/opt/letta-code
ENV COREPACK_HOME=/opt/corepack
ARG LETTA_UID=10001
ARG LETTA_GID=10001
ARG LETTA_CODE_VERSION=""
ARG PNPM_VERSION="11.5.2"
ARG YARN_VERSION="4.16.0"
ARG WORKTRUNK_VERSION="0.57.0"

# The GitHub workflow keeps this file at the latest published npm version.
# Railway services connected to this repo can then auto-deploy from Git commits
# instead of staying pinned to the version baked into the first build.
COPY letta-code-version.txt /tmp/letta-code-version.txt

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg apt-transport-https; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main' \
      > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash \
      bat \
      build-essential \
      direnv \
      fd-find \
      file \
      gh \
      git \
      jq \
      less \
      make \
      nodejs \
      openssh-client \
      pipx \
      pre-commit \
      procps \
      python3 \
      python3-pip \
      python3-venv \
      ripgrep \
      shellcheck \
      tree \
      unzip \
      util-linux \
      wget \
      xz-utils \
      yq \
      zip \
      zstd; \
    for pkg in gitleaks just; do \
      if apt-cache show "$pkg" >/dev/null 2>&1; then \
        apt-get install -y --no-install-recommends "$pkg"; \
      else \
        echo "Skipping unavailable Debian package: $pkg"; \
      fi; \
    done; \
    mkdir -p "${COREPACK_HOME}"; \
    corepack enable; \
    corepack prepare "pnpm@${PNPM_VERSION}" --activate; \
    corepack prepare "yarn@${YARN_VERSION}" --activate; \
    corepack install -g "pnpm@${PNPM_VERSION}" "yarn@${YARN_VERSION}"; \
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh; \
    curl --proto '=https' --tlsv1.2 -LsSf "https://github.com/max-sixty/worktrunk/releases/download/v${WORKTRUNK_VERSION}/worktrunk-installer.sh" \
      | env WORKTRUNK_INSTALL_DIR=/usr/local WORKTRUNK_NO_MODIFY_PATH=1 sh; \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    ln -sf /usr/bin/batcat /usr/local/bin/bat; \
    mkdir -p /etc/xdg/worktrunk; \
    printf '%s\n' 'worktree-path = "{{ repo_path }}/../{{ branch | sanitize }}"' > /etc/xdg/worktrunk/config.toml; \
    groupadd --gid "${LETTA_GID}" letta; \
    useradd --uid "${LETTA_UID}" --gid "${LETTA_GID}" --create-home --home-dir /home/letta --shell /bin/bash letta; \
    version="${LETTA_CODE_VERSION:-$(cat /tmp/letta-code-version.txt)}"; \
    bun install -g "@letta-ai/letta-code@${version}"; \
    mkdir -p /home/letta/Code /home/letta/.config /home/letta/.letta; \
    chown -R letta:letta /home/letta; \
    chmod -R a+rX "${COREPACK_HOME}"; \
    rm -rf /var/lib/apt/lists/*

ENV ENV_NAME="cloud"
ENV LETTA_RESTORE_ENABLED_CHANNELS="1"
ENV LETTA_UID="${LETTA_UID}"
ENV LETTA_GID="${LETTA_GID}"
ENV HOME="/home/letta"
ENV XDG_CONFIG_HOME="/home/letta/.config"

COPY entrypoint.sh /usr/local/bin/letta-server-entrypoint
RUN chmod +x /usr/local/bin/letta-server-entrypoint

WORKDIR /home/letta/Code

ENTRYPOINT ["/usr/local/bin/letta-server-entrypoint"]
CMD ["letta-server"]
