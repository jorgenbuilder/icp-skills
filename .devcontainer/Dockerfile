# Agentspace Template - Devcontainer Base Image
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl \
    git \
    jq \
    unzip \
    tmux \
    fzf \
    ripgrep \
    python3 \
    python3-pip \
    ca-certificates \
    gnupg \
    chromium-browser \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI as vscode user
USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash

# Ensure Claude is on PATH
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Switch back to root for any final setup
USER root

# Set working directory
WORKDIR /workspaces

# Default to vscode user
USER vscode
