FROM nousresearch/hermes-agent:v2026.9.24@sha256:fca358f12efd65bfaaca05884166f15c0e2788375ca30d77061ac1ebc96452b7

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
# Pre-install caldav python library in the virtual environment and preserve ownership
RUN owner=$(stat -c '%u:%g' /opt/hermes/.venv) \
    && uv pip install --python /opt/hermes/.venv/bin/python3 "caldav" \
    && chown -R "$owner" /opt/hermes/.venv
# agent-browser drives the browser_* tools. Hermes only needs the CLI here: the
# browser itself is a headless-shell sidecar reached over CDP (browser.cdp_url),
# so no Chromium is installed in this image. Pinned to the range Hermes itself
# resolves via npx (AGENT_BROWSER_NPX_SPEC in tools/browser_tool.py); without a
# global install it would fall back to npx and cache under $HOME, the backed-up PVC.
RUN npm install -g agent-browser@0.26.0 \
    && npm cache clean --force \
    && agent-browser --version
