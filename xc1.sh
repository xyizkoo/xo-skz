#!/bin/bash
#
# Complete System Setup Script - Debian 12 (Bookworm) Optimized
# Based on current docs as of 2026
# Usage: curl -sSL https://your-server.com/setup.sh | bash
#

set -eo pipefail

# Disable ALL interactive prompts
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none
export UCF_FORCE_CONFFOLD=1
export DEBCONF_NONINTERACTIVE_SEEN=true

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Function to run commands with sudo if needed
run_with_sudo() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Get current user (for non-root installs)
CURRENT_USER=$(whoami)
log_info "Running as user: $CURRENT_USER"

# ============================================
# SYSTEM SETUP
# ============================================

# Configure apt for full auto-yes
configure_apt() {
    log_info "Configuring apt for unattended installation..."
    
    run_with_sudo bash -c 'echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/00autoaccept'
    run_with_sudo bash -c 'echo "APT::Get::force-yes \"true\";" >> /etc/apt/apt.conf.d/00autoaccept'
    run_with_sudo bash -c 'echo "DPkg::Options {\"--force-confdef\";\"--force-confold\";};" > /etc/apt/apt.conf.d/99force-conf'
}

# Update system
update_system() {
    log_info "Updating Debian 12 system..."
    run_with_sudo apt-get update -y
    run_with_sudo apt-get upgrade -y
    run_with_sudo apt-get dist-upgrade -y
    run_with_sudo apt-get autoremove -y
    run_with_sudo apt-get autoclean -y
    run_with_sudo apt-get clean -y
    log_info "System updated"
}

# Install base packages
install_base() {
    log_info "Installing base packages..."
    run_with_sudo apt-get install -y \
        wget curl gnupg software-properties-common \
        git build-essential unzip zip gpg-agent \
        ca-certificates sudo magic-wormhole shellcheck \
        openssh-server file procps lsb-release
    log_info "Base packages installed"
}

# ============================================
# FISH SHELL (Debian 12 specific)
# ============================================
install_fish() {
    log_info "Installing Fish shell v4 on Debian 12..."
    
    if command -v fish &>/dev/null; then
        log_info "Fish already installed"
        fish --version
        return 0
    fi
    
    # Debian 12 requires OBS repository for latest Fish (no PPA support) [citation:7]
    run_with_sudo bash -c 'echo "deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_12/ /" | tee /etc/apt/sources.list.d/shells:fish:release:4.list'
    curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_12/Release.key | run_with_sudo gpg --dearmor | run_with_sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
    run_with_sudo apt-get update -y
    run_with_sudo apt-get install -y fish
    
    log_info "Fish installed successfully"
    fish --version
}

# ============================================
# RUST INSTALLATION
# ============================================
install_rust() {
    log_info "Installing Rust on Debian 12..."
    
    if [[ -f "$HOME/.cargo/bin/cargo" ]]; then
        log_info "Rust already installed"
        cargo --version
        return 0
    fi
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    run_with_sudo bash -c 'echo "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" >> /etc/profile.d/rust.sh'
    
    rustup update
    cargo --version
    log_info "Rust installed successfully"
}

# ============================================
# GO INSTALLATION (FIXED PATHS)
# ============================================
install_go() {
    log_info "Installing Go 1.23.4 on Debian 12..."
    
    # Remove any conflicting Debian Go packages first [citation:1]
    run_with_sudo apt-get remove -y golang-go golang-1.19-go golang-1.20-go 2>/dev/null || true
    run_with_sudo rm -rf /usr/local/go 2>/dev/null || true
    
    GO_VERSION="1.23.4"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TAR}"
    
    # Download Go from official source
    wget -q --show-progress "$GO_URL" || log_error "Failed to download Go"
    
    # Extract to /usr/local (standard location) [citation:1]
    run_with_sudo tar -C /usr/local -xzf "$GO_TAR" || log_error "Failed to extract Go"
    rm -f "$GO_TAR"
    
    # Create GOPATH directory structure for current user
    mkdir -p "$HOME/go"/{bin,src,pkg}
    
    # System-wide environment for bash (this is the proper way per Debian docs) [citation:1]
    run_with_sudo bash -c 'cat > /etc/profile.d/go.sh << "EOF"
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOF'
    
    # Fish shell environment
    run_with_sudo mkdir -p /etc/fish/conf.d
    run_with_sudo bash -c 'cat > /etc/fish/conf.d/go.fish << "EOF"
set -gx GOROOT /usr/local/go
set -gx GOPATH $HOME/go
set -gx PATH $PATH $GOROOT/bin $GOPATH/bin
EOF'
    
    # Source for current session
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    
    # Add to current user's fish config for persistence
    mkdir -p "$HOME/.config/fish"
    
    # Remove any existing Go lines to avoid duplicates
    sed -i '/GOROOT/d' "$HOME/.config/fish/config.fish" 2>/dev/null || true
    sed -i '/GOPATH/d' "$HOME/.config/fish/config.fish" 2>/dev/null || true
    
    echo 'set -gx GOROOT /usr/local/go' >> "$HOME/.config/fish/config.fish"
    echo 'set -gx GOPATH $HOME/go' >> "$HOME/.config/fish/config.fish"
    echo 'set -gx PATH $PATH $GOROOT/bin $GOPATH/bin' >> "$HOME/.config/fish/config.fish"
    
    # Add to .bashrc for current user
    echo 'export GOROOT=/usr/local/go' >> "$HOME/.bashrc"
    echo 'export GOPATH=$HOME/go' >> "$HOME/.bashrc"
    echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> "$HOME/.bashrc"
    
    # Verify installation
    /usr/local/go/bin/go version || log_error "Go installation failed"
    
    log_info "Go ${GO_VERSION} installed successfully"
    log_info "GOROOT: $GOROOT"
    log_info "GOPATH: $GOPATH"
}

# ============================================
# CARGO PACKAGES (Rust tools)
# ============================================
install_cargo_pkgs() {
    log_info "Installing cargo packages on Debian 12..."
    
    export PATH="$HOME/.cargo/bin:$PATH"
    
    local packages=(
        "eza"
        "fd-find"
        "ripgrep"
        "cfonts"
        "artem"
        "bat"
        "lolcrab"
        "bottom"
        "du-dust"
        "tokei"
        "quagga"
        "starship"
    )
    
    for pkg in "${packages[@]}"; do
        log_info "Installing: $pkg"
        cargo install "$pkg" || log_warn "Failed to install $pkg"
    done
    
    log_info "Cargo packages installed"
}

# ============================================
# UV AND BUN (Python/JS runtimes)
# ============================================
install_uv_bun() {
    log_info "Installing UV (Python package manager) on Debian 12..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    log_info "Installing Bun (JavaScript runtime) on Debian 12..."
    curl -fsSL https://bun.sh/install | bash
    
    log_info "UV and Bun installed"
}

# ============================================
# WITR INSTALLATION
# ============================================
install_witr() {
    log_info "Installing WITR on Debian 12..."
    curl -fsSL https://raw.githubusercontent.com/pranshuparmar/witr/main/install.sh | bash
    log_info "WITR installed"
}

# ============================================
# DOCKER INSTALLATION (Official Docker CE)
# ============================================
install_docker() {
    log_info "Installing Docker CE on Debian 12 from official repository..."
    
    if command -v docker &>/dev/null; then
        log_info "Docker already installed"
        docker --version
        return 0
    fi
    
    # Remove old Docker packages that conflict with Docker CE [citation:2][citation:10]
    local old_packages=("docker.io" "docker-doc" "docker-compose" "podman-docker" "containerd" "runc")
    for pkg in "${old_packages[@]}"; do
        run_with_sudo apt-get remove -y "$pkg" 2>/dev/null || true
    done
    
    # Install prerequisites [citation:2]
    run_with_sudo apt-get update -y
    run_with_sudo apt-get install -y ca-certificates curl
    
    # Create keyrings directory
    run_with_sudo install -m 0755 -d /etc/apt/keyrings
    
    # Add Docker's official GPG key (2026 method) [citation:2][citation:10]
    run_with_sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    run_with_sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add Docker repository - auto-detects Debian 12 "bookworm" [citation:2]
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | run_with_sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update and install Docker CE with plugins [citation:2]
    run_with_sudo apt-get update -y
    run_with_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    run_with_sudo systemctl enable docker
    run_with_sudo systemctl start docker
    
    # Add current user to docker group (to run without sudo) [citation:2][citation:10]
    if [[ "$CURRENT_USER" != "root" ]]; then
        log_info "Adding user $CURRENT_USER to docker group..."
        run_with_sudo usermod -aG docker "$CURRENT_USER"
        log_warn "You may need to log out and back in for docker group to take effect"
    fi
    
    # Verify installation
    docker --version || log_error "Docker installation failed"
    docker compose version || log_error "Docker Compose installation failed"
    
    log_info "Docker CE installed successfully"
}

# ============================================
# HOMEBREW (MOVED TO END - SLOW)
# ============================================
install_homebrew() {
    log_info "Installing Homebrew (Linuxbrew) on Debian 12..."
    log_info "This may take a few minutes..."
    
    if command -v brew &>/dev/null; then
        log_info "Homebrew already installed"
        brew --version
        return 0
    fi
    
    # Non-interactive Homebrew installation
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for bash (system-wide)
    run_with_sudo bash -c 'echo "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"" >> /etc/profile.d/homebrew.sh'
    
    # Add Homebrew to PATH for fish shell (proper fish syntax uses eval, not $()) [citation:3]
    run_with_sudo mkdir -p /etc/fish/conf.d
    run_with_sudo bash -c 'echo "eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)" > /etc/fish/conf.d/homebrew.fish'
    
    # Add to current user's fish config
    mkdir -p "$HOME/.config/fish"
    echo '# Homebrew' >> "$HOME/.config/fish/config.fish"
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$HOME/.config/fish/config.fish"
    
    # Source for current session
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    
    brew --version || log_error "Homebrew installation failed"
    log_info "Homebrew installed at /home/linuxbrew/.linuxbrew"
}

# ============================================
# FZF INSTALLATION (AFTER HOMEBREW)
# ============================================
install_fzf() {
    log_info "Installing fzf via Homebrew..."
    
    if command -v fzf &>/dev/null; then
        log_info "fzf already installed"
        fzf --version
        return 0
    fi
    
    # Make sure brew is available
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    
    # Install fzf via Homebrew [citation:4][citation:8]
    brew install fzf
    
    # Set up shell integration for Fish (current method per fzf docs) [citation:4][citation:8]
    # The proper command for fish shell is: fzf --fish | source
    mkdir -p "$HOME/.config/fish"
    
    # Check if already added to avoid duplicates
    if ! grep -q "fzf --fish | source" "$HOME/.config/fish/config.fish" 2>/dev/null; then
        echo '# fzf key bindings' >> "$HOME/.config/fish/config.fish"
        echo 'fzf --fish | source' >> "$HOME/.config/fish/config.fish"
    fi
    
    log_info "fzf installed and configured"
    log_info "fzf version: $(fzf --version)"
}

# ============================================
# STARSIP CONFIGURATION
# ============================================
setup_starship() {
    log_info "Setting up Starship prompt on Debian 12..."
    
    export PATH="$HOME/.cargo/bin:$PATH"
    
    mkdir -p "$HOME/.config/fish" "$HOME/.config"
    
    # Download starship preset (pure preset) [citation:4]
    curl -fsSL https://raw.githubusercontent.com/starship/starship/master/presets/pure-preset.toml -o "$HOME/.config/starship.toml" 2>/dev/null || log_warn "Could not download starship preset"
    
    log_info "Starship configured"
}

# ============================================
# SET FISH AS DEFAULT SHELL
# ============================================
set_fish_default() {
    if command -v fish &>/dev/null && [[ "$CURRENT_USER" != "root" ]]; then
        log_info "Setting Fish as default shell for $CURRENT_USER..."
        chsh -s "$(command -v fish)" "$CURRENT_USER" 2>/dev/null || log_warn "Could not change shell. Run: chsh -s $(command -v fish)"
    fi
}

# ============================================
# VERIFICATION
# ============================================
verify_install() {
    log_info "Verifying installations..."
    
    echo ""
    echo "========================================="
    echo "DEBIAN 12 - INSTALLED VERSIONS:"
    echo "========================================="
    
    # OS version
    cat /etc/debian_version 2>/dev/null && echo "✓ Debian detected"
    
    # Fish
    if command -v fish &>/dev/null; then
        echo "✓ Fish: $(fish --version)"
    else
        echo "✗ Fish not found"
    fi
    
    # Rust/Cargo
    if command -v cargo &>/dev/null; then
        echo "✓ Rust/Cargo: $(cargo --version)"
    else
        echo "✗ Rust not found"
    fi
    
    # Go
    if command -v go &>/dev/null; then
        echo "✓ Go: $(go version)"
        echo "    GOROOT: $(go env GOROOT)"
        echo "    GOPATH: $(go env GOPATH)"
    else
        echo "✗ Go not found"
    fi
    
    # Starship
    if command -v starship &>/dev/null; then
        echo "✓ Starship: $(starship --version)"
    else
        echo "✗ Starship not found"
    fi
    
    # UV
    if command -v uv &>/dev/null; then
        echo "✓ UV: $(uv --version)"
    else
        echo "✗ UV not found"
    fi
    
    # Bun
    if command -v bun &>/dev/null; then
        echo "✓ Bun: $(bun --version)"
    else
        echo "✗ Bun not found"
    fi
    
    # Cargo tools
    for tool in eza bat bottom; do
        if command -v $tool &>/dev/null; then
            echo "✓ $tool: installed"
        else
            echo "✗ $tool not found"
        fi
    done
    
    # Docker
    if command -v docker &>/dev/null; then
        echo "✓ Docker: $(docker --version)"
        echo "✓ Docker Compose: $(docker compose version)"
    else
        echo "✗ Docker not found"
    fi
    
    # Homebrew
    if command -v brew &>/dev/null; then
        echo "✓ Homebrew: $(brew --version | head -1)"
    else
        echo "✗ Homebrew not found"
    fi
    
    # fzf
    if command -v fzf &>/dev/null; then
        echo "✓ fzf: $(fzf --version)"
    else
        echo "✗ fzf not found"
    fi
    
    # WITR
    if command -v witr &>/dev/null; then
        echo "✓ WITR: installed"
    else
        echo "✗ WITR not found"
    fi
    
    # Wormhole
    if command -v wormhole &>/dev/null; then
        echo "✓ Magic Wormhole: installed"
    else
        echo "✗ Magic Wormhole not found"
    fi
    
    echo "========================================="
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    log_info "Starting UNATTENDED installation on Debian 12 (Bookworm)"
    echo ""
    log_info "Fast installations first..."
    echo ""
    
    configure_apt
    update_system
    install_base
    install_fish
    install_rust
    install_go
    install_cargo_pkgs
    setup_starship
    install_uv_bun
    install_witr
    install_docker
    
    echo ""
    log_info "Slow installations (Homebrew, fzf) - this will take a few minutes..."
    echo ""
    
    install_homebrew
    install_fzf
    
    set_fish_default
    verify_install
    
    echo ""
    log_info "========================================="
    log_info "✅ INSTALLATION COMPLETE!"
    log_info "========================================="
    echo ""
    log_info "To use Go immediately in this terminal:"
    echo "  export GOROOT=/usr/local/go"
    echo "  export GOPATH=\$HOME/go"
    echo "  export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin"
    echo ""
    log_info "To use Docker without sudo (after logging out and back in):"
    echo "  docker run hello-world"
    echo ""
    log_info "Restart your shell or run: exec fish"
}

# Run main if script is executed directly
main "$@"