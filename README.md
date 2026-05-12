# Hermes with Tools 🛠️

A custom Docker image for [nousresearch/hermes-agent](https://hub.docker.com/r/nousresearch/hermes-agent) equipped with essential command-line tools for automation, cluster management, and repository interaction.

## Features

This image extends the base Hermes Agent image with the following tools:

- **`kubectl`**: The Kubernetes command-line tool, used for communicating with a Kubernetes cluster's control plane.
- **`gh`**: The GitHub CLI, providing a command-line interface for GitHub features like issues, pull requests, and GitHub Actions.
- **`jq`**: A lightweight and flexible command-line JSON processor, perfect for parsing and manipulating API responses.

## Base Image

The image is built on top of:
`nousresearch/hermes-agent`

## CI/CD

This repository uses GitHub Actions to automatically build and push the Docker image to the GitHub Container Registry (GHCR) whenever the `Dockerfile` is updated on the `main` branch.

**Image Registry:** `ghcr.io/cmmmota/hermes-with-tools`

## Usage

You can use this image in your Kubernetes deployments or run it locally:

```bash
docker pull ghcr.io/cmmmota/hermes-with-tools:latest
```

### Local Testing

To run the container locally and verify the tools are installed:

```bash
docker run --rm -it ghcr.io/cmmmota/hermes-with-tools:latest bash
# Inside the container:
kubectl version --client
gh --version
jq --version
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).
