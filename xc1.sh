#!/bin/bash
#
# Complete System Setup Script - Debian 12 Optimized (with Homebrew)
# Usage: curl -sSL https://your-server.com/setup.sh | sudo bash
#

set -euo pipefail

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

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Must be root. Use: sudo bash $0"
    fi
}

# Configure apt for full auto-yes
configure_apt() {
    log_info "Configuring apt for unattended installation..."
    
    echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/00autoaccept
    echo 'APT::Get::force-yes "true";' >> /etc/apt/apt.conf.d/00autoaccept
    echo 'DPkg::Options {"--force-confdef";"--force-confold";};' > /etc/apt/apt.conf.d/99force-conf
}

# Update system
update_system() {
    log_info "Updating Debian 12 system..."
    apt-get update -y
    apt-get upgrade -y
    apt-get dist-upgrade -y
    apt-get autoremove -y
    apt-get autoclean -y
    apt-get clean -y
    log_info "System updated"
}

# Install base packages
install_base() {
    log_info "Installing base packages..."
    apt-get install -y \
        wget curl gnupg software-properties-common \
        git build-essential unzip zip gpg-agent \
        ca-certificates sudo magic-wormhole shellcheck \
        openssh-server \
        file procps
        
    log_info "Base packages installed"
}

# Install Homebrew (Linuxbrew) - FIXED
install_homebrew() {
    log_info "Installing Homebrew (Linuxbrew) on Debian 12..."
    
    # Non-interactive Homebrew installation
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for bash
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /etc/profile.d/homebrew.sh
    
    # Add Homebrew to PATH for fish shell
    mkdir -p /etc/fish/conf.d
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' > /etc/fish/conf.d/homebrew.fish
    
    # Source for current session
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    
    # Verify installation
    brew --version || log_error "Homebrew installation failed"
    
    log_info "Homebrew installed successfully at /home/linuxbrew/.linuxbrew"
}

# Install fzf via Homebrew (as in original script)
install_fzf() {
    log_info "Installing fzf via Homebrew..."
    
    # Install fzf
    brew install fzf
    
    # Auto-accept the install script
    yes | /home/linuxbrew/.linuxbrew/opt/fzf/install
    
    # fzf_key_bindings is automatically set up by the install script
    # No need for separate command
    
    log_info "fzf installed and configured"
}

# Install Fish shell - DEBIAN 12 SPECIFIC
install_fish() {
    log_info "Installing Fish shell v4 on Debian 12..."
    
    # Debian 12 doesn't use PPAs - use OBS repository instead
    echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_12/ /' | tee /etc/apt/sources.list.d/shells:fish:release:4.list
    curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_12/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
    apt-get update -y
    apt-get install -y fish
    
    fish --version
    log_info "Fish installed"
}

# Install Rust
install_rust() {
    log_info "Installing Rust on Debian 12..."
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /etc/profile.d/rust.sh
    
    rustup update
    cargo --version
    log_info "Rust installed"
}

# Install GO - Debian 12 optimized
install_go() {
    log_info "Installing Go 1.23.4 on Debian 12..."
    
    GO_VERSION="1.23.4"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TAR}"
    
    # Remove any existing Go from apt (to avoid conflicts)
    apt-get remove -y golang-go 2>/dev/null || true
    
    wget -q --show-progress "$GO_URL" || log_error "Failed to download Go"
    
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "$GO_TAR" || log_error "Failed to extract Go"
    rm -f "$GO_TAR"
    
    mkdir -p /root/go/{bin,src,pkg}
    
    # Debian-specific: use /etc/profile.d for system-wide PATH
    cat > /etc/profile.d/go.sh << 'EOF'
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOF
    
    source /etc/profile.d/go.sh
    
    # Fish shell config for Debian
    mkdir -p /etc/fish/conf.d
    cat > /etc/fish/conf.d/go.fish << 'EOF'
set -gx GOROOT /usr/local/go
set -gx GOPATH $HOME/go
set -gx PATH $PATH $GOROOT/bin $GOPATH/bin
EOF
    
    mkdir -p /root/.config/fish
    echo 'set -gx GOPATH $HOME/go' >> /root/.config/fish/config.fish
    echo 'set -gx PATH $PATH /usr/local/go/bin $GOPATH/bin' >> /root/.config/fish/config.fish
    
    if id "debian" &>/dev/null; then
        mkdir -p /home/debian/.config/fish
        echo 'set -gx GOPATH $HOME/go' >> /home/debian/.config/fish/config.fish
        echo 'set -gx PATH $PATH /usr/local/go/bin $GOPATH/bin' >> /home/debian/.config/fish/config.fish
        chown -R debian:debian /home/debian/.config
    fi
    
    /usr/local/go/bin/go version || log_error "Go installation failed"
    
    log_info "Go ${GO_VERSION} installed successfully on Debian 12"
}

# Install all cargo packages
install_cargo_pkgs() {
    log_info "Installing cargo packages on Debian 12..."
    
    cargo install eza
    cargo install fd-find
    cargo install ripgrep
    cargo install cfonts
    cargo install artem
    cargo install bat
    cargo install lolcrab
    cargo install bottom
    cargo install du-dust
    cargo install tokei
    cargo install quagga
    
    log_info "Cargo packages installed"
}

# Setup Starship
setup_starship() {
    log_info "Setting up Starship on Debian 12..."
    
    # Install starship via cargo
    cargo install starship
    
    mkdir -p ~/.config/fish ~/.config
    
    # Create fish config with all integrations
    cat > ~/.config/fish/config.fish << 'EOF'
starship init fish | source
uv generate-shell-completion fish | source
uvx --generate-shell-completion fish | source
# Homebrew
eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
EOF
    
    # Add Homebrew to root's fish config
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> /root/.config/fish/config.fish
    
    # Download starship preset
    curl -fsSL https://raw.githubusercontent.com/starship/starship/master/presets/pure-preset.toml -o ~/.config/starship.toml 2>/dev/null || true
    
    log_info "Starship configured"
}

# Install UV and Bun
install_uv_bun() {
    log_info "Installing UV on Debian 12..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    log_info "Installing Bun on Debian 12..."
    curl -fsSL https://bun.sh/install | bash
    
    log_info "UV and Bun installed"
}

# Install WITR
install_witr() {
    log_info "Installing WITR on Debian 12..."
    curl -fsSL https://raw.githubusercontent.com/pranshuparmar/witr/main/install.sh | bash
    log_info "WITR installed"
}

# Set Fish as default shell
set_fish_default() {
    if command -v fish &>/dev/null; then
        log_info "Setting Fish as default shell on Debian 12..."
        chsh -s "$(command -v fish)" root 2>/dev/null || true
        if id "debian" &>/dev/null; then
            chsh -s "$(command -v fish)" debian 2>/dev/null || true
        fi
        if [[ -n "${SUDO_USER:-}" ]] && [[ "$SUDO_USER" != "root" ]]; then
            chsh -s "$(command -v fish)" "$SUDO_USER" 2>/dev/null || true
        fi
    fi
}

# Verify all installations
verify_install() {
    log_info "Verifying Debian 12 installations..."
    
    echo ""
    echo "========================================="
    echo "DEBIAN 12 - INSTALLED VERSIONS:"
    echo "========================================="
    
    cat /etc/debian_version 2>/dev/null && echo "✓ Debian detected"
    
    command -v fish && fish --version || echo "✗ Fish not found"
    command -v brew && brew --version || echo "✗ Homebrew not found"
    command -v fzf && fzf --version || echo "✗ fzf not found"
    command -v cargo && cargo --version || echo "✗ Rust not found"
    command -v go && go version || echo "✗ Go not found"
    command -v starship && starship --version || echo "✗ Starship not found"
    command -v uv && uv --version || echo "✗ UV not found"
    command -v bun && bun --version || echo "✗ Bun not found"
    command -v eza && eza --version || echo "✗ Eza not found"
    command -v bat && bat --version || echo "✗ Bat not found"
    command -v witr && witr --version 2>/dev/null || echo "✗ WITR not found"
    
    echo "========================================="
    
    if command -v go &>/dev/null; then
        echo ""
        echo "Go Environment:"
        echo "  GOROOT: $(go env GOROOT)"
        echo "  GOPATH: $(go env GOPATH)"
    fi
    
    if command -v brew &>/dev/null; then
        echo ""
        echo "Homebrew Environment:"
        brew --prefix
    fi
}

# Main
main() {
    check_root
    
    log_info "Starting UNATTENDED installation on Debian 12 (Bookworm) with Homebrew"
    echo ""
    
    configure_apt
    update_system
    install_base
    
    # Install Homebrew first (needed for fzf)
    install_homebrew
    install_fzf               # fzf installed via Homebrew
    
    install_fish
    install_rust
    install_go
    install_cargo_pkgs
    setup_starship            # This now includes Homebrew in fish config
    install_uv_bun
    install_witr
    
    set_fish_default
    verify_install
    
    echo ""
    log_info "✅ INSTALLATION COMPLETE on Debian 12!"
    echo ""
    echo "Installed components:"
    echo "  ✓ Homebrew (Linuxbrew)"
    echo "  ✓ fzf (fuzzy finder)"
    echo "  ✓ Fish shell v4"
    echo "  ✓ Rust + Cargo tools"
    echo "  ✓ Go 1.23.4"
    echo "  ✓ Starship prompt"
    echo "  ✓ UV (Python package manager)"
    echo "  ✓ Bun (JavaScript runtime)"
    echo "  ✓ WITR (file transfer)"
    echo ""
    echo "Quick commands after logging in:"
    echo "  brew list                  # Show Homebrew packages"
    echo "  fzf --version             # Fuzzy finder"
    echo "  eza --long                # Modern ls"
    echo "  go version                # Go"
    echo "  starship prompt           # Custom prompt"
    echo "  uv --help                 # Python package manager"
    echo "  bun --version             # JavaScript runtime"
    echo "  wormhole send             # Secure file transfer"
    echo "  witr send                 # WITR transfer"
    echo ""
    log_info "Restart your shell or run: exec fish"
}

# Run it
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi