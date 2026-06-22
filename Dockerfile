FROM nousresearch/hermes-agent:v2026.6.19@sha256:9f367c7756ef087661a361536a89f438d57a122b958dc23d82d456b1433e6e9e

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
    # --- cleanup ---
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# Pre-install caldav python library in the virtual environment and preserve ownership
RUN owner=$(stat -c '%u:%g' /opt/hermes/.venv) \
    && uv pip install --python /opt/hermes/.venv/bin/python3 "caldav" \
    && chown -R "$owner" /opt/hermes/.venv
