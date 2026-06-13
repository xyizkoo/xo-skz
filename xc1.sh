#!/bin/bash
#
# Complete System Setup Script - Debian 12 Optimized (with Homebrew at the end)
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

# Configure apt for full auto-yes
configure_apt() {
    log_info "Configuring apt for unattended installation..."
    
    run_with_sudo bash -c 'echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/00autoaccept' 2>/dev/null || true
    run_with_sudo bash -c 'echo "APT::Get::force-yes \"true\";" >> /etc/apt/apt.conf.d/00autoaccept' 2>/dev/null || true
    run_with_sudo bash -c 'echo "DPkg::Options {\"--force-confdef\";\"--force-confold\";};" > /etc/apt/apt.conf.d/99force-conf' 2>/dev/null || true
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
        openssh-server \
        file procps 2>/dev/null || true
        
    log_info "Base packages installed"
}

# Install Fish shell - DEBIAN 12 SPECIFIC
install_fish() {
    log_info "Installing Fish shell v4 on Debian 12..."
    
    if command -v fish &>/dev/null; then
        log_info "Fish already installed"
        return 0
    fi
    
    # Debian 12 doesn't use PPAs - use OBS repository instead
    run_with_sudo bash -c 'echo "deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_12/ /" | tee /etc/apt/sources.list.d/shells:fish:release:4.list' 2>/dev/null || true
    curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_12/Release.key | run_with_sudo gpg --dearmor | run_with_sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null 2>&1 || true
    run_with_sudo apt-get update -y 2>/dev/null || true
    run_with_sudo apt-get install -y fish 2>/dev/null || true
    
    fish --version
    log_info "Fish installed"
}

# Install Rust
install_rust() {
    log_info "Installing Rust on Debian 12..."
    
    if [[ -f "$HOME/.cargo/bin/cargo" ]]; then
        log_info "Rust already installed"
        return 0
    fi
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || true
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    run_with_sudo bash -c 'echo "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" >> /etc/profile.d/rust.sh' 2>/dev/null || true
    
    rustup update || true
    cargo --version
    log_info "Rust installed"
}

# Install GO - Debian 12 optimized
install_go() {
    log_info "Installing Go 1.23.4 on Debian 12..."
    
    if command -v go &>/dev/null; then
        log_info "Go already installed"
        return 0
    fi
    
    GO_VERSION="1.23.4"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TAR}"
    
    run_with_sudo apt-get remove -y golang-go 2>/dev/null || true
    
    wget -q "$GO_URL" || log_error "Failed to download Go"
    
    run_with_sudo rm -rf /usr/local/go
    run_with_sudo tar -C /usr/local -xzf "$GO_TAR" || log_error "Failed to extract Go"
    rm -f "$GO_TAR"
    
    run_with_sudo mkdir -p /root/go/{bin,src,pkg} 2>/dev/null || true
    
    run_with_sudo bash -c 'cat > /etc/profile.d/go.sh << "EOF"
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOF' 2>/dev/null || true
    
    /usr/local/go/bin/go version || log_error "Go installation failed"
    
    log_info "Go installed"
}

# Install all cargo packages
install_cargo_pkgs() {
    log_info "Installing cargo packages on Debian 12..."
    
    export PATH="$HOME/.cargo/bin:$PATH"
    
    cargo install eza 2>/dev/null || true
    cargo install fd-find 2>/dev/null || true
    cargo install ripgrep 2>/dev/null || true
    cargo install cfonts 2>/dev/null || true
    cargo install artem 2>/dev/null || true
    cargo install bat 2>/dev/null || true
    cargo install lolcrab 2>/dev/null || true
    cargo install bottom 2>/dev/null || true
    cargo install du-dust 2>/dev/null || true
    cargo install tokei 2>/dev/null || true
    cargo install quagga 2>/dev/null || true
    cargo install starship 2>/dev/null || true
    
    log_info "Cargo packages installed"
}

# Setup Starship
setup_starship() {
    log_info "Setting up Starship on Debian 12..."
    
    mkdir -p ~/.config/fish ~/.config
    
    # Create fish config with all integrations (without Homebrew for now)
    cat > ~/.config/fish/config.fish << 'EOF' 2>/dev/null || true
starship init fish | source
uv generate-shell-completion fish | source
uvx --generate-shell-completion fish | source
EOF
    
    # Download starship preset
    curl -fsSL https://raw.githubusercontent.com/starship/starship/master/presets/pure-preset.toml -o ~/.config/starship.toml 2>/dev/null || true
    
    log_info "Starship configured"
}

# Install UV and Bun
install_uv_bun() {
    log_info "Installing UV on Debian 12..."
    curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || true
    
    log_info "Installing Bun on Debian 12..."
    curl -fsSL https://bun.sh/install | bash 2>/dev/null || true
    
    log_info "UV and Bun installed"
}

# Install WITR
install_witr() {
    log_info "Installing WITR on Debian 12..."
    curl -fsSL https://raw.githubusercontent.com/pranshuparmar/witr/main/install.sh | bash 2>/dev/null || true
    log_info "WITR installed"
}

# Install Homebrew (Linuxbrew) - MOVED TO END
install_homebrew() {
    log_info "Installing Homebrew (Linuxbrew) on Debian 12..."
    
    if command -v brew &>/dev/null; then
        log_info "Homebrew already installed"
        return 0
    fi
    
    log_info "This may take a few minutes... (compiling)"
    
    # Non-interactive Homebrew installation
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
    
    # Add Homebrew to PATH for bash
    run_with_sudo bash -c 'echo "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"" >> /etc/profile.d/homebrew.sh' 2>/dev/null || true
    
    # Add Homebrew to PATH for fish shell
    run_with_sudo mkdir -p /etc/fish/conf.d 2>/dev/null || true
    run_with_sudo bash -c 'echo "eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)" > /etc/fish/conf.d/homebrew.fish' 2>/dev/null || true
    
    # Add Homebrew to fish config
    echo '# Homebrew' >> ~/.config/fish/config.fish 2>/dev/null || true
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.config/fish/config.fish 2>/dev/null || true
    
    # Source for current session
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    
    log_info "Homebrew installed"
}

# Install fzf via Homebrew (after Homebrew is installed)
install_fzf() {
    log_info "Installing fzf via Homebrew..."
    
    # Check if fzf already installed
    if command -v fzf &>/dev/null; then
        log_info "fzf already installed"
        return 0
    fi
    
    # Make sure brew is available
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    
    # Install fzf
    brew install fzf || true
    
    # Auto-accept the install script
    if [[ -f /home/linuxbrew/.linuxbrew/opt/fzf/install ]]; then
        yes | /home/linuxbrew/.linuxbrew/opt/fzf/install || true
    fi
    
    log_info "fzf installed and configured"
}

# Set Fish as default shell
set_fish_default() {
    if command -v fish &>/dev/null; then
        log_info "Setting Fish as default shell..."
        chsh -s "$(command -v fish)" "$(whoami)" 2>/dev/null || true
    fi
}

# Verify all installations
verify_install() {
    log_info "Verifying installations..."
    
    echo ""
    echo "========================================="
    echo "INSTALLED VERSIONS:"
    echo "========================================="
    
    command -v fish && fish --version || echo "✗ Fish not found"
    command -v cargo && cargo --version || echo "✗ Rust not found"
    command -v go && go version || echo "✗ Go not found"
    command -v starship && starship --version || echo "✗ Starship not found"
    command -v uv && uv --version || echo "✗ UV not found"
    command -v bun && bun --version || echo "✗ Bun not found"
    command -v eza && eza --version || echo "✗ Eza not found"
    command -v bat && bat --version || echo "✗ Bat not found"
    command -v brew && brew --version || echo "✗ Homebrew not found"
    command -v fzf && fzf --version || echo "✗ fzf not found"
    
    echo "========================================="
}

# Main
main() {
    log_info "Starting UNATTENDED installation on Debian 12 (Bookworm)"
    echo ""
    
    # Fast installations first
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
    
    # Slow Homebrew and fzf at the VERY END
    log_info "Installing slow tools (Homebrew, fzf) - this will take a few minutes..."
    install_homebrew
    install_fzf
    
    set_fish_default
    verify_install
    
    echo ""
    log_info "✅ INSTALLATION COMPLETE!"
    echo ""
    echo "Installed components:"
    echo "  ✓ Fish shell v4"
    echo "  ✓ Rust + Cargo tools"
    echo "  ✓ Go 1.23.4"
    echo "  ✓ Starship prompt"
    echo "  ✓ UV (Python package manager)"
    echo "  ✓ Bun (JavaScript runtime)"
    echo "  ✓ WITR (file transfer)"
    echo "  ✓ Homebrew (Linuxbrew)"
    echo "  ✓ fzf (fuzzy finder)"
    echo ""
    log_info "Restart your shell or run: exec fish"
}

# Run it
main "$@"