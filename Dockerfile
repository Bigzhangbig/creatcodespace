FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    fish \
    python3 \
    python3-pip \
    python3-venv \
    llvm \
    locales \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up Chinese Language Pack
RUN sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# Install Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js and pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install oh-my-posh
RUN curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin

# Set fish as default shell for the vscode user
RUN chsh -s /usr/bin/fish vscode

# Install fisher and plugins as vscode user
USER vscode
WORKDIR /home/vscode

# Pre-configure fish: install fisher and plugins, setup oh-my-posh
RUN fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && \
    fisher install jorgebucaran/fisher \
    fisher install jethrokuan/z \
    fisher install patrickf1/fzf.fish \
    fisher install Bridgetown-rb/fish-done"

# Create fish config and initialize oh-my-posh
RUN mkdir -p /home/vscode/.config/fish && \
    echo 'oh-my-posh init fish --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json | source' >> /home/vscode/.config/fish/config.fish && \
    # Ensure fisher is loaded
    mkdir -p /home/vscode/.config/fish/functions && \
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o /home/vscode/.config/fish/functions/fisher.fish

# Back to root for any final steps
USER root

# Set the default shell to fish
SHELL ["/usr/bin/fish", "-c"]
