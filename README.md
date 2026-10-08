# Hermes with Tools 🛠️

A custom Docker image for [nousresearch/hermes-agent](https://hub.docker.com/r/nousresearch/hermes-agent) equipped with essential command-line tools for automation, cluster management, and repository interaction.

## Features

This image extends the base Hermes Agent image with the following tools:

- **`kubectl`**: The Kubernetes command-line tool, used for communicating with a Kubernetes cluster's control plane.
- **`gh`**: The GitHub CLI, providing a command-line interface for GitHub features like issues, pull requests, and GitHub Actions.
- **`jq`**: A lightweight and flexible command-line JSON processor, perfect for parsing and manipulating API responses.
- **`caldav`**: A Python CalDAV client library, pre-installed in the agent's virtual environment.

## Base Image

The image is built on top of:
`nousresearch/hermes-agent`

## CI/CD

This repository uses GitHub Actions to automatically build and push the Docker image to the GitHub Container Registry (GHCR) whenever the `Dockerfile` or the build workflow is updated on the `main` branch, or when the workflow is run manually.

**Image Registry:** `ghcr.io/cmmmota/hermes-with-tools`

### Tags

Image versions follow the base `nousresearch/hermes-agent` tag in the `Dockerfile`:

| Tag | Example | Behaviour |
| --- | --- | --- |
| `<base>` | `v2026.9.24` | Newest build on that base version. Moves if the `Dockerfile` changes without a base bump. |
| `<base>-<sha>` | `v2026.9.24-af81a39` | Immutable. Pins one exact build. |
| `<sha>` | `af81a39` | Immutable. Short commit SHA. |
| `latest`, `main` | | Newest build from `main`. |

## Usage

You can use this image in your Kubernetes deployments or run it locally:

```bash
docker pull ghcr.io/cmmmota/hermes-with-tools:latest
```

### Local Testing

To run the container locally and verify the tools are installed:

```bash
docker run --rm -it ghcr.io/cmmmota/hermes-with-tools:latest bash
kubectl version --client
gh --version
jq --version
/opt/hermes/.venv/bin/python3 -c "import caldav; print('caldav version:', caldav.__version__)"
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).
