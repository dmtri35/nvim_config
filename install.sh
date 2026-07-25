#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Append a line to ~/.bashrc only if that exact line is not already there, so
# re-running this installer does not stack up duplicate exports.
bashrc_append() {
    local line=$1
    if grep -Fqx "$line" "$HOME/.bashrc" 2> /dev/null; then
        return 0
    fi
    printf '%s\n' "$line" >> "$HOME/.bashrc"
}

# Detect package manager
detect_pkg_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v brew &> /dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)
info "Detected package manager: $PKG_MANAGER"

# Install system packages
install_pkg() {
    local pkg=$1
    case $PKG_MANAGER in
        apt)
            apt install -y "$pkg"
            ;;
        dnf)
            dnf install -y "$pkg"
            ;;
        pacman)
            pacman -S --noconfirm "$pkg"
            ;;
        brew)
            brew install "$pkg"
            ;;
        *)
            error "Unknown package manager. Please install $pkg manually."
            return 1
            ;;
    esac
}

# Update package manager
update_pkg_manager() {
    case $PKG_MANAGER in
        apt)
            apt update
            ;;
        dnf)
            dnf check-update || true
            ;;
        pacman)
            pacman -Sy
            ;;
        brew)
            brew update
            ;;
    esac
}

echo ""
echo "=============================================="
echo "  Neovim Configuration Installer"
echo "=============================================="
echo ""

# Update package manager
info "Updating package manager..."
update_pkg_manager

# ============================================
# 1. Install Neovim (latest from GitHub)
# ============================================
info "Installing latest Neovim from GitHub releases..."
NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
info "Latest version: $NVIM_VERSION"

cd /tmp
curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
tar xzf nvim-linux-x86_64.tar.gz
rm -rf /opt/nvim
mv nvim-linux-x86_64 /opt/nvim
ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz
cd - > /dev/null

success "Neovim installed: $(nvim --version | head -1)"

# ============================================
# 2. Install build essentials
# ============================================
info "Installing build tools..."
case $PKG_MANAGER in
    apt)
        apt install -y build-essential git curl wget unzip tar
        ;;
    dnf)
        dnf install -y gcc gcc-c++ make git curl wget unzip tar
        ;;
    pacman)
        pacman -S --noconfirm base-devel git curl wget unzip tar
        ;;
    brew)
        # Xcode command line tools should be installed
        brew install git curl wget
        ;;
esac
success "Build tools installed"

# ============================================
# 3. lazy.nvim (bootstraps automatically)
# ============================================
info "lazy.nvim will bootstrap automatically on first nvim launch"

# ============================================
# 4. Install Node.js (needed for some LSPs)
# ============================================
info "Checking Node.js..."
if ! command -v node &> /dev/null; then
    info "Installing Node.js..."
    case $PKG_MANAGER in
        apt)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -E -
            apt install -y nodejs
            ;;
        dnf)
            dnf install -y nodejs npm
            ;;
        pacman)
            pacman -S --noconfirm nodejs npm
            ;;
        brew)
            brew install node
            ;;
    esac
    success "Node.js installed"
else
    success "Node.js already installed: $(node --version)"
fi

# ============================================
# 5. Install Python and pip
# ============================================
info "Checking Python..."
if ! command -v python3 &> /dev/null; then
    info "Installing Python..."
    case $PKG_MANAGER in
        apt)
            apt install -y python3 python3-pip python3-venv
            ;;
        dnf)
            dnf install -y python3 python3-pip
            ;;
        pacman)
            pacman -S --noconfirm python python-pip
            ;;
        brew)
            brew install python
            ;;
    esac
fi
success "Python installed: $(python3 --version)"

# ============================================
# 6. Install Rust (for rust-analyzer)
# ============================================
info "Checking Rust..."
if ! command -v rustc &> /dev/null; then
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    success "Rust installed"
else
    success "Rust already installed: $(rustc --version)"
fi

# ============================================
# 7. Install Go (for gopls)
# ============================================
info "Checking Go..."
if ! command -v go &> /dev/null; then
    info "Installing Go..."
    case $PKG_MANAGER in
        apt|dnf)
            GO_VERSION="1.22.0"
            wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
            rm -rf /usr/local/go
            tar -C /usr/local -xzf /tmp/go.tar.gz
            rm /tmp/go.tar.gz
            bashrc_append 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin'
            export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
            ;;
        pacman)
            pacman -S --noconfirm go
            ;;
        brew)
            brew install go
            ;;
    esac
    success "Go installed"
else
    success "Go already installed: $(go version)"
fi

# ============================================
# 8. Install LSP Servers
# ============================================
echo ""
info "Installing LSP servers..."

# Pyright (Python)
info "Installing pyright..."
if ! command -v pyright &> /dev/null; then
    npm install -g pyright
    success "pyright installed"
else
    success "pyright already installed"
fi

# TypeScript Language Server
info "Installing typescript-language-server..."
if ! command -v typescript-language-server &> /dev/null; then
    npm install -g typescript typescript-language-server
    success "typescript-language-server installed"
else
    success "typescript-language-server already installed"
fi

# ============================================
# 9. Install or update fzf
# ============================================
info "Installing latest fzf..."
case $PKG_MANAGER in
    brew)
        if command -v fzf &> /dev/null; then
            brew upgrade fzf || brew install fzf
        else
            brew install fzf
        fi
        ;;
    apt|dnf|pacman)
        FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        info "Latest version: $FZF_VERSION"

        case "$(uname -m)" in
            x86_64|amd64)
                FZF_ARCH="amd64"
                ;;
            aarch64|arm64)
                FZF_ARCH="arm64"
                ;;
            *)
                warn "Unsupported architecture for GitHub fzf binaries; falling back to package manager"
                install_pkg fzf
                FZF_ARCH=""
                ;;
        esac

        if [ -n "$FZF_ARCH" ]; then
            rm -rf /tmp/fzf-install
            mkdir -p /tmp/fzf-install
            curl -L "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION#v}-linux_${FZF_ARCH}.tar.gz" -o /tmp/fzf.tar.gz
            tar -xzf /tmp/fzf.tar.gz -C /tmp/fzf-install
            install -m 755 /tmp/fzf-install/fzf /usr/local/bin/fzf
            if [ -f /tmp/fzf-install/fzf-tmux ]; then
                install -m 755 /tmp/fzf-install/fzf-tmux /usr/local/bin/fzf-tmux
            fi
            rm -rf /tmp/fzf-install /tmp/fzf.tar.gz
        fi
        ;;
    *)
        install_pkg fzf
        ;;
esac
success "fzf installed: $(fzf --version)"

# ============================================
# 10. Set up fzf shell integration
# ============================================
info "Checking fzf shell integration..."
if command -v fzf &> /dev/null; then
    if grep -Fqx 'eval "$(fzf --bash)"' "$HOME/.bashrc" 2> /dev/null; then
        success "fzf bash integration already configured in ~/.bashrc"
    else
        echo '' >> "$HOME/.bashrc"
        echo '# Set up fzf key bindings and fuzzy completion' >> "$HOME/.bashrc"
        echo 'eval "$(fzf --bash)"' >> "$HOME/.bashrc"
        success "Added fzf bash integration to ~/.bashrc"
    fi
else
    warn "fzf is not installed; skipping bash integration setup"
fi

# ============================================
# 11. Set Neovim as default editor
# ============================================
info "Checking default editor..."
if grep -Fqx 'export EDITOR=nvim' "$HOME/.bashrc" 2> /dev/null; then
    success "Default editor already set to nvim in ~/.bashrc"
else
    echo '' >> "$HOME/.bashrc"
    echo 'export EDITOR=nvim' >> "$HOME/.bashrc"
    success "Set default editor to nvim in ~/.bashrc"
fi

# Biome (JS/TS formatter/linter)
info "Installing biome..."
if ! command -v biome &> /dev/null; then
    npm install -g @biomejs/biome
    success "biome installed"
else
    success "biome already installed"
fi

# Lua Language Server
info "Installing lua-language-server..."
if ! command -v lua-language-server &> /dev/null; then
    case $PKG_MANAGER in
        apt)
            # Install from GitHub releases
            LUA_LS_VERSION="3.7.4"
            mkdir -p ~/.local/share/lua-language-server
            curl -L "https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LS_VERSION}/lua-language-server-${LUA_LS_VERSION}-linux-x64.tar.gz" | tar xz -C ~/.local/share/lua-language-server
            mkdir -p ~/.local/bin
            ln -sf ~/.local/share/lua-language-server/bin/lua-language-server ~/.local/bin/lua-language-server
            bashrc_append 'export PATH=$PATH:$HOME/.local/bin'
            export PATH=$PATH:$HOME/.local/bin
            ;;
        pacman)
            pacman -S --noconfirm lua-language-server
            ;;
        brew)
            brew install lua-language-server
            ;;
        *)
            warn "Please install lua-language-server manually"
            ;;
    esac
    success "lua-language-server installed"
else
    success "lua-language-server already installed"
fi

# Go Language Server
info "Installing gopls..."
if ! command -v gopls &> /dev/null; then
    go install golang.org/x/tools/gopls@latest
    success "gopls installed"
else
    success "gopls already installed"
fi

# Clangd (C/C++) - latest from GitHub
info "Installing clangd from GitHub releases..."
CLANGD_DIR="$HOME/.local/share/clangd"
CLANGD_BIN="$HOME/.local/bin/clangd"

# Always install latest from GitHub
CLANGD_VERSION=$(curl -sL https://api.github.com/repos/clangd/clangd/releases | grep -m1 '"tag_name"' | cut -d'"' -f4)
info "Latest clangd version: $CLANGD_VERSION"

mkdir -p "$HOME/.local/bin"
mkdir -p "$CLANGD_DIR"

# Determine platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    CLANGD_PLATFORM="mac"
else
    CLANGD_PLATFORM="linux"
fi

cd /tmp
curl -LO "https://github.com/clangd/clangd/releases/download/${CLANGD_VERSION}/clangd-${CLANGD_PLATFORM}-${CLANGD_VERSION}.zip"
rm -rf "$CLANGD_DIR"/*
unzip -q "clangd-${CLANGD_PLATFORM}-${CLANGD_VERSION}.zip" -d "$CLANGD_DIR"
# The zip extracts to a subdirectory
ln -sf "$CLANGD_DIR/clangd_${CLANGD_VERSION}/bin/clangd" "$CLANGD_BIN"
rm "clangd-${CLANGD_PLATFORM}-${CLANGD_VERSION}.zip"
cd - > /dev/null

# Ensure ~/.local/bin is in PATH
bashrc_append 'export PATH=$PATH:$HOME/.local/bin'
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH=$PATH:$HOME/.local/bin
fi

success "clangd installed: $($CLANGD_BIN --version | head -1)"

# Rust Analyzer
info "Installing rust-analyzer..."
if ! command -v rust-analyzer &> /dev/null; then
    rustup component add rust-analyzer
    success "rust-analyzer installed"
else
    success "rust-analyzer already installed"
fi

# Bash Language Server
info "Installing bash-language-server..."
if ! command -v bash-language-server &> /dev/null; then
    npm install -g bash-language-server
    success "bash-language-server installed"
else
    success "bash-language-server already installed"
fi

# Zig Language Server (optional)
info "Checking zls (Zig LSP)..."
if ! command -v zls &> /dev/null; then
    warn "zls not installed. Install Zig and zls manually if needed: https://github.com/zigtools/zls"
else
    success "zls already installed"
fi

# ============================================
# 9. Install extra tools for Telescope
# ============================================
echo ""
info "Installing tools for Telescope..."

# ripgrep
if ! command -v rg &> /dev/null; then
    info "Installing ripgrep..."
    case $PKG_MANAGER in
        apt)
            apt install -y ripgrep
            ;;
        dnf)
            dnf install -y ripgrep
            ;;
        pacman)
            pacman -S --noconfirm ripgrep
            ;;
        brew)
            brew install ripgrep
            ;;
    esac
    success "ripgrep installed"
else
    success "ripgrep already installed"
fi

# fd
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    info "Installing fd..."
    case $PKG_MANAGER in
        apt)
            apt install -y fd-find
            # Create symlink for fd
            mkdir -p ~/.local/bin
            ln -sf $(which fdfind) ~/.local/bin/fd 2>/dev/null || true
            ;;
        dnf)
            dnf install -y fd-find
            ;;
        pacman)
            pacman -S --noconfirm fd
            ;;
        brew)
            brew install fd
            ;;
    esac
    success "fd installed"
else
    success "fd already installed"
fi

# ============================================
# 10. Setup nvim config
# ============================================
echo ""
info "Setting up Neovim configuration..."

NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$SCRIPT_DIR" != "$NVIM_CONFIG_DIR" ]; then
    if [ -d "$NVIM_CONFIG_DIR" ]; then
        warn "Existing nvim config found at $NVIM_CONFIG_DIR"
        read -p "Backup and replace? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d%H%M%S)"
            ln -s "$SCRIPT_DIR" "$NVIM_CONFIG_DIR"
            success "Config linked to $NVIM_CONFIG_DIR"
        fi
    else
        ln -s "$SCRIPT_DIR" "$NVIM_CONFIG_DIR"
        success "Config linked to $NVIM_CONFIG_DIR"
    fi
else
    success "Config already at $NVIM_CONFIG_DIR"
fi

# ============================================
# 11. Git global defaults (~/.gitconfig)
# ============================================
echo ""
info "Configuring git global defaults..."

GITCONFIG="${HOME}/.gitconfig"
if [[ -f "$GITCONFIG" ]] && grep -qF '# clearly makes git better' "$GITCONFIG" 2>/dev/null; then
    success "Git defaults already present in $GITCONFIG"
else
    cat >> "$GITCONFIG" <<'GITCONFIG_EOF'

# clearly makes git better

[column]
        ui = auto
[branch]
        sort = -committerdate
[tag]
        sort = version:refname
[init]
        defaultBranch = main
[diff]
        algorithm = histogram
        colorMoved = plain
        mnemonicPrefix = true
        renames = true
[push]
        default = simple
        autoSetupRemote = true
        followTags = true
[fetch]
        prune = true
        pruneTags = true
        all = true

# why the hell not?

[help]
        autocorrect = prompt
[commit]
        verbose = true
[rerere]
        enabled = true
        autoupdate = true
[core]
        excludesfile = ~/.gitignore
[rebase]
        autoSquash = true
        autoStash = true
        updateRefs = true

# a matter of taste (uncomment if you dare)

[core]
        # fsmonitor = true
        # untrackedCache = true
[merge]
        # (just 'diff3' if git version < 2.3)
        # conflictstyle = zdiff3
[pull]
        # rebase = true
GITCONFIG_EOF
    success "Appended git defaults to $GITCONFIG"
fi

# ============================================
# 12. Persist Codex state on mounted workspace
# ============================================
echo ""
info "Configuring Codex to use /workspace as HOME..."

CODEX_WRAPPER_BLOCK=$(cat <<'EOF'
# Persist Codex state on the mounted workspace volume.
mkdir -p /workspace/.codex /workspace/.agents
codex() {
    # 'command' is required: without it the name resolves back to this
    # function, recursing until bash overflows its stack and segfaults.
    HOME=/workspace command codex "$@"
}
EOF
)

if grep -qF '# Persist Codex state on the mounted workspace volume.' ~/.bashrc 2>/dev/null; then
    success "Codex wrapper already present in ~/.bashrc"
else
    printf '\n%s\n' "$CODEX_WRAPPER_BLOCK" >> ~/.bashrc
    success "Codex wrapper added to ~/.bashrc"
fi

# ============================================
# 13. Install plugins via lazy.nvim
# ============================================
echo ""
info "Installing Neovim plugins via lazy.nvim..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
success "Plugins installed"

# ============================================
# 14. Summary
# ============================================
echo ""
echo "=============================================="
echo -e "${GREEN}  Installation Complete!${NC}"
echo "=============================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.bashrc)"
echo "  2. Open nvim - lazy.nvim will auto-install plugins"
echo "  3. Install a Nerd Font for icons: https://www.nerdfonts.com/"
echo ""
echo "Optional:"
echo "  - Install jdtls (Java) manually if needed"
echo "  - Install zls (Zig) if you use Zig"
echo ""
echo "LSP servers installed:"
echo "  - pyright (Python)"
echo "  - typescript-language-server (TypeScript/JavaScript)"
echo "  - biome (JS/TS formatter)"
echo "  - lua-language-server (Lua)"
echo "  - gopls (Go)"
echo "  - clangd (C/C++) - latest from GitHub"
echo "  - rust-analyzer (Rust)"
echo "  - bash-language-server (Bash)"
echo ""
