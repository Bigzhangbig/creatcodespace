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
    unzip \
    # Modern Unix tools
    bat \
    ripgrep \
    fd-find \
    duf \
    tldr \
    zoxide \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install additional modern tools not in standard apt-repo or needing specific versions
RUN ARCH=$(dpkg --print-architecture) && \
    # eza (ls replacement)
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list && \
    apt-get update && apt-get install -y eza && \
    # dust (du replacement)
    curl -L https://github.com/bootandy/dust/releases/download/v1.0.0/dust-v1.0.0-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /usr/local/bin --strip-components=1 && \
    # xh (curl replacement)
    curl -L https://github.com/ducaale/xh/releases/download/v0.18.0/xh-v0.18.0-x86_64-unknown-linux-musl.tar.gz | tar xz -C /usr/local/bin --strip-components=1 && \
    # sd (sed replacement)
    curl -L https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /usr/local/bin --strip-components=1 && \
    # procs (ps replacement)
    curl -L https://github.com/dalance/procs/releases/download/v0.14.9/procs-v0.14.9-x86_64-linux.zip -o procs.zip && \
    unzip procs.zip -d /usr/local/bin && rm procs.zip && \
    # btm (top replacement)
    curl -L https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_x86_64-unknown-linux-gnu.tar.gz | tar xz -C /usr/local/bin && \
    # delta (diff replacement)
    DELTA_VER="0.16.5" && \
    curl -LO https://github.com/dandavison/delta/releases/download/$DELTA_VER/git-delta_${DELTA_VER}_$ARCH.deb && \
    dpkg -i git-delta_${DELTA_VER}_$ARCH.deb && rm git-delta_${DELTA_VER}_$ARCH.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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
    && npm install -g pnpm gemini-chat-cli \
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
    echo 'zoxide init fish | source' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias ls="eza --icons"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias cat="batcat --paging=never"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias grep="rg"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias find="fd"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias ps="procs"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias du="dust"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias df="duf"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias sed="sd"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias curl="xh"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias top="btm"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias diff="delta"' >> /home/vscode/.config/fish/config.fish && \
    echo 'alias gemini="gemini-chat"' >> /home/vscode/.config/fish/config.fish && \
    # Ensure fisher is loaded
    mkdir -p /home/vscode/.config/fish/functions && \
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o /home/vscode/.config/fish/functions/fisher.fish

# Back to root for any final steps
USER root

# Set the default shell to fish
SHELL ["/usr/bin/fish", "-c"]
