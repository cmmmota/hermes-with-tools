FROM nousresearch/hermes-agent:v0.23.4@sha256:ef0650d523ee1b5ab32c779acabc446d9936869a9932591553688a62bcf0c42f

# Install gh (GitHub CLI), jq and openscad. gh is not in Debian, so its apt source
# is added; the base image already ships curl and ca-certificates, and the key is
# published dearmored, so gnupg is not needed.
# The package lists and downloads live in BuildKit cache mounts, which never reach
# the image, so a rebuild after a base image bump downloads nothing it already has.
# docker-clean is removed because it deletes the downloads after every install.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        gh \
        jq \
        openscad
# kubectl must stay within one minor of the cluster, so it is the release binary
# pinned here (and tracked by Renovate) rather than a pkgs.k8s.io minor channel.
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.37.3
RUN url="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl" \
    && curl -fsSLo /usr/local/bin/kubectl "$url" \
    && echo "$(curl -fsSL "$url.sha256")  /usr/local/bin/kubectl" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/kubectl \
    && kubectl version --client
# Skills run uv and uvx directly, but Hermes keeps its pinned copies in a versioned
# tool store dir that is not on PATH. The glob survives upstream uv bumps, and the
# build fails unless it matches exactly one directory.
RUN set -- /opt/hermes/tools/uv-*/ \
    && [ "$#" -eq 1 ] && [ -d "$1" ] \
    && ln -s "${1}uv" "${1}uvx" /usr/local/bin/ \
    && uv --version \
    && uvx --version
# Pre-install Python libraries in the virtual environment and preserve ownership.
# The pinned packages are baked in because the pod runs as uid 10000, where Hermes'
# boot dependency refresh fails, and v0.22.7 no longer reads /opt/data/lazy-packages.
# Only files uv wrote with another owner are changed: a blanket `chown -R` copies
# every venv file into this layer even when the owner is unchanged.
# uv's cache is a BuildKit cache mount on another filesystem, so it copies instead
# of hardlinking.
RUN --mount=type=cache,target=/root/.cache/uv \
    owner=$(stat -c '%u:%g' /opt/hermes/.venv) \
    && UV_LINK_MODE=copy uv pip install --python /opt/hermes/.venv/bin/python3 \
        "caldav==3.7.0" \
        "hindsight-client==0.10.1" \
        "firecrawl-py==4.53.2" \
        "edge-tts==7.3.1" \
    && find /opt/hermes/.venv \( ! -user "${owner%:*}" -o ! -group "${owner#*:}" \) \
        -exec chown -h "$owner" {} +
# The claude CLI backs the claude-subscription-directsdk provider plugin, which
# runs Hermes turns on a Claude Pro/Max login. npm's default global prefix sits in
# Hermes' versioned node dir, which is not on PATH, so install under /usr/local.
# The login lives in $HOME/.claude on the PVC; the image only carries the binary,
# and the auto-updater stays off because uid 10000 cannot write /usr/local.
# Its postinstall fetches the native binary, and this npm blocks install scripts
# unless the package is allowed by name. npm's cache is a BuildKit cache mount.
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.330
ENV DISABLE_AUTOUPDATER=1
RUN --mount=type=cache,target=/root/.npm \
    npm install -g --prefix /usr/local --allow-scripts=@anthropic-ai/claude-code \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    && claude --version
# Start in the writable data dir, where the gateway's terminal already runs by
# default. In /opt/hermes, uv finds Hermes' own pyproject.toml and tries to build it.
WORKDIR /opt/data
