ARG LETTA_CODE_IMAGE=ghcr.io/letta-ai/letta-code:latest
FROM ${LETTA_CODE_IMAGE}

COPY --chmod=755 start-app-server.sh /usr/local/bin/start-letta-app-server

ENV LETTA_BACKEND=local \
    PORT=4500

EXPOSE 4500

HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=5 \
  CMD curl --fail --silent "http://127.0.0.1:${PORT:-4500}/readyz" || exit 1

CMD ["/usr/local/bin/start-letta-app-server"]
