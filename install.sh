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
            curl -fsSL https://deb.nodesource.com/setup_lts.x | -E bash -
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
            echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
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
            echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
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

# Clangd (C/C++)
info "Installing clangd..."
if ! command -v clangd &> /dev/null; then
    case $PKG_MANAGER in
        apt)
            apt install -y clangd
            ;;
        dnf)
            dnf install -y clang-tools-extra
            ;;
        pacman)
            pacman -S --noconfirm clang
            ;;
        brew)
            brew install llvm
            ;;
    esac
    success "clangd installed"
else
    success "clangd already installed"
fi

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
# 11. Install plugins via lazy.nvim
# ============================================
echo ""
info "Installing Neovim plugins via lazy.nvim..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
success "Plugins installed"

# ============================================
# Summary
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
echo "  - clangd (C/C++)"
echo "  - rust-analyzer (Rust)"
echo "  - bash-language-server (Bash)"
echo ""
