FROM nousresearch/hermes-agent:v0.22.7@sha256:e6d81ae52ebf6a43efa529701405509f20054ba818f179ddd748bed4f8af584c

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
# Pre-install caldav python library in the virtual environment and preserve ownership.
# Hermes no longer puts uv on PATH; its pinned copy lives in a versioned store dir.
RUN owner=$(stat -c '%u:%g' /opt/hermes/.venv) \
    && /opt/hermes/tools/uv-*/uv pip install --python /opt/hermes/.venv/bin/python3 "caldav" \
    && chown -R "$owner" /opt/hermes/.venv
# agent-browser is a standalone CLI. Hermes itself no longer uses it: its browser
# tool is browser_exec (browser-harness, shipped in the base venv), and upstream
# removed AGENT_BROWSER_NPX_SPEC, so this pin no longer tracks a Hermes range.
# --prefix keeps it on PATH: npm's default global prefix is the versioned Node
# dir in Hermes' tool store, which is not on PATH.
RUN npm install -g --prefix /usr/local agent-browser@0.26.0 \
    && npm cache clean --force \
    && agent-browser --version
