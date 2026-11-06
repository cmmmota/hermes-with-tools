FROM nousresearch/hermes-agent:v0.23.0@sha256:adb7890916de63245523492be8f68f9d2095fecbec4e2a6dab7960381f0fc002

# Install kubectl, gh (GitHub CLI), and jq
# kubectl and gh are not in standard Debian repos, so we add their official apt sources.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    # --- kubectl ---
    && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
        | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" \
        > /etc/apt/sources.list.d/kubernetes.list \
    # --- gh (GitHub CLI) ---
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    # --- install everything ---
    && apt-get update && apt-get install -y --no-install-recommends \
        kubectl \
        gh \
        jq \
        openscad \
    # --- cleanup ---
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# Skills run uv and uvx directly, but Hermes keeps its pinned copies in a versioned
# tool store dir that is not on PATH. The glob survives upstream uv bumps, and the
# build fails unless it matches exactly one directory.
RUN set -- /opt/hermes/tools/uv-*/ \
    && [ "$#" -eq 1 ] && [ -d "$1" ] \
    && ln -s "${1}uv" "${1}uvx" /usr/local/bin/ \
    && uv --version \
    && uvx --version
# Pre-install caldav python library in the virtual environment and preserve ownership.
# The pinned packages are baked in because the pod runs as uid 10000, where Hermes'
# boot dependency refresh fails, and v0.22.7 no longer reads /opt/data/lazy-packages.
RUN owner=$(stat -c '%u:%g' /opt/hermes/.venv) \
    && uv pip install --python /opt/hermes/.venv/bin/python3 \
        "caldav" \
        "hindsight-client==0.10.1" \
        "firecrawl-py==4.53.2" \
        "edge-tts==7.3.1" \
    && chown -R "$owner" /opt/hermes/.venv
# Start in the writable data dir, where the gateway's terminal already runs by
# default. In /opt/hermes, uv finds Hermes' own pyproject.toml and tries to build it.
WORKDIR /opt/data
