FROM nousresearch/hermes-agent:v0.23.1@sha256:276d44685c65c0cb2a25f190b63c65c8906f9dc76486fb1c05ae71b5826bda08

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
# The claude CLI backs the claude-subscription-directsdk provider plugin, which
# runs Hermes turns on a Claude Pro/Max login. npm's default global prefix sits in
# Hermes' versioned node dir, which is not on PATH, so install under /usr/local.
# The login lives in $HOME/.claude on the PVC; the image only carries the binary,
# and the auto-updater stays off because uid 10000 cannot write /usr/local.
# Its postinstall fetches the native binary, and this npm blocks install scripts
# unless the package is allowed by name.
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.319
ENV DISABLE_AUTOUPDATER=1
RUN npm install -g --prefix /usr/local --allow-scripts=@anthropic-ai/claude-code \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    && npm cache clean --force \
    && claude --version
# Start in the writable data dir, where the gateway's terminal already runs by
# default. In /opt/hermes, uv finds Hermes' own pyproject.toml and tries to build it.
WORKDIR /opt/data
