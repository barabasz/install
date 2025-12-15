#!/bin/zsh

# =========================================================
# Automated core shell installation script for new systems
# Author: https://github.com/barabasz
# Repository: https://github.com/barabasz/install
# Date: 2024-06-15
# License: MIT
# =========================================================

# This script is meant to be run on a fresh system this way:
# `source <(curl -fsSL https://raw.githubusercontent.com/barabasz/install/HEAD/install.sh)`
# and is compatible with both bash (Debian/Ubuntu default) and zsh (macOS default) shells.

# Script steps:
# 1. sudo setup
# 2. Git setup
# 3. Homebrew setup
# 4. GitHub CLI setup
# 5. Repositories setup
# 6. Zsh setup
# 7. Oh My Zsh setup
# 8. Oh My Posh setup
# 9. Basic tools & finalization

# =========================================================
# Initial environment setup
# =========================================================

## Folders and paths
export TMP=$HOME/.tmp
export TEMP=$TMP
export LOGDIR=$TMP/InstallShell
export BINDIR=$HOME/bin
export LIBDIR=$HOME/lib
export CONFDIR=$HOME/.config
export CACHEDIR=$HOME/.cache
export ZSH_SESSIONS_DIR=$CACHEDIR/.zsh_sessions
export VENVDIR=$HOME/.venv

# XDG
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$CONFDIR}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$CACHEDIR}
export XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# GitHub
export GHDIR=$HOME/GitHub
export GHBINDIR=$GHDIR/bin
export GHLIBDIR=$GHDIR/zsh-lib
export GHCONFDIR=$GHDIR/config

# Oh My Zsh
export ZSH=$CONFDIR/omz
export ZSH_CUSTOM=$ZSH/custom

# Temporary locale settings to avoid issues during installation
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Brew environment variables for non-interactive installation
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_VERBOSE=0
export HOMEBREW_DEBUG=0
export NONINTERACTIVE=1

# =========================================================
# Main function
# =========================================================

# Load helper functions
lib_script_url="https://raw.githubusercontent.com/barabasz/install/HEAD/install.lib.sh"
source <(curl -fsSL "${lib_script_url}?${RANDOM}") || {
    echo "Failed to load helper functions from ${lib_script_url##*/}. Exiting."
    return 1
}

# Load color variables
load_colors

# Ensure kitty terminfo is installed
check_terminfo

print_title "Core Shell Installation Script"
echo -e "This script will install and configure following components on your system:"
print_commands sudo git brew gh zsh "Oh My Zsh" oh-my-posh
echo -e "Log directory: ${y}$LOGDIR${x}\n"

# Prompt user to continue
prompt_continue || return 1

# Create base directories
mkdir -p $TMP
mkdir -p $LOGDIR
mkdir -p $BINDIR
mkdir -p $CONFDIR
mkdir -p $CACHEDIR
mkdir -p $ZSH_SESSIONS_DIR
mkdir -p $VENVDIR
mkdir -p $GHDIR
mkdir -p $XDG_BIN_HOME
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_STATE_HOME

## Set script counters
step=1 && steps=9

# ---------------------------------------------------------
# 1. Sudo Setup (Linux only)
# ---------------------------------------------------------

print_header "sudo setup"

if ! is_installed sudo; then
    print_start "sudo not found. Installing sudo..."
    if is_debian_based; then
        # Installing sudo
        install_silent "sudo" su -c "apt-get install -qq sudo" || return 1
        local sudostr="$(whoami) ALL=(ALL:ALL) ALL"
        su -c "echo '$sudostr' | sudo EDITOR='tee -a' visudo"
    fi
    print_done "sudo installed."
else
    print_info "sudo is already installed."
fi
print_version sudo

# Force sudo password prompt
echo -e "\n${y}⚠ Enter your password for sudo access:${x}"
sudo echo > /dev/null
if [[ $? -ne 0 ]]; then
    print_error "Failed to obtain sudo access."
    return 1
else
    print_done "Sudo access granted."
fi

# Update apt package lists on Linux systems
if ! is_macos; then
    print_start "Updating apt package lists..."
    run_silent "apt_update_initial" sudo apt update
    print_done "Package lists updated."
fi

# ---------------------------------------------------------
# 2. Git Setup
# ---------------------------------------------------------

print_header "git setup"

if ! is_installed git; then
    print_start "Git not found. Installing Git..."
    if is_macos; then
        install_silent "git" xcode-select --install || return 1
    elif is_linux; then
        run_silent "apt_update" sudo apt update || return 1
        install_silent "git" sudo apt install git -y || return 1
    fi
    print_done "Git installed."
else
    print_info "Git is already installed."
fi
print_version git

# ---------------------------------------------------------
# 3. Homebrew Setup
# ---------------------------------------------------------

brew_script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
print_header "homebrew setup"

# Execute shellenv if brew is installed
brew_shellenv

if ! is_installed brew; then
    print_start "Homebrew not found. Installing Homebrew..."
    # Ubuntu/Debian fix for Homebrew
    if ! is_macos; then
        sudo mkdir -p /home/linuxbrew/
        sudo chmod 755 /home/linuxbrew/
    fi
    install_silent "brew" /bin/bash -c "$(curl -fsSL $brew_script_url)" || return 1
    # Execute shellenv after brew installation
    brew_shellenv
    print_done "Homebrew installed."
else
    print_info "Homebrew is already installed."
fi
print_version brew

# Disable analytics
print_start "Disabling Homebrew analytics..."
run_silent "brew_analytics_disable" brew analytics off
print_done "Homebrew analytics disabled."

# Update Homebrew
print_start "Updating Homebrew..."
run_silent "brew_update" brew update
run_silent "brew_upgrade" brew upgrade
print_done "Homebrew updated."

# ---------------------------------------------------------
# 4. GitHub CLI Setup
# ---------------------------------------------------------

print_header "github cli setup"

if ! is_installed gh; then
    print_start "GitHub CLI not found. Installing gh..."

    if is_macos; then
        install_silent "gh" brew install gh || return 1
    elif is_linux; then
        (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
            && sudo mkdir -p -m 755 /etc/apt/keyrings \
            && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
            && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
            && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
            && sudo apt update \
            && sudo apt install gh -y
    fi
    print_done "GitHub CLI installed."
else
    print_done "GitHub CLI is already installed."
fi
print_version gh

# ---------------------------------------------------------
# 5. Repositories setup
# ---------------------------------------------------------

print_header "Repositories setup"

print_start "Cloning repositories..."
cd $GHDIR 
repos=("bin" "config" "install" "zsh-lib")
for repo in "${repos[@]}"; do
    rm -rf "$GHDIR/$repo"
    git_clone "$repo" || return 1
done
print_done "Repositories cloned successfully."

print_start "Symlinking directories and files..."

# lib - whole directory
lns "$GHLIBDIR" "$LIBDIR"

# Remove old bin structure if exists
[[ -e $BINDIR ]] && rm -rf $BINDIR
# Create fresh directory
mkdir -p $BINDIR
# Create new bin structure
dirs=("common" "linux" "macos" "test" "windows")
for dir in "${dirs[@]}"; do
    lns "$GHBINDIR/$dir" "$BINDIR/$dir"
done
lns "$GHDIR/install/common" "$BINDIR/install"

# Apps
repos=("bash" "gh" "git" "mc" "nvim" "omp" "zsh")
for app in "${repos[@]}"; do
    lnconf "$app"
done
print_done "Directories and files symlinked."

# ---------------------------------------------------------
# 6. Zsh Setup
# ---------------------------------------------------------

print_header "zsh setup"

# Install Zsh if not present (Linux only)
if ! is_macos && ! is_installed zsh; then
    print_start "Zsh not found. Installing Zsh..."
    run_silent "zsh_install" sudo apt install zsh -y || return 1
else
    print_done "Zsh is already installed."
fi
print_version zsh

print_start "Setting Zsh as default shell..."

if is_zsh_default; then
    print_done "zsh is already the default shell."
else
    if set_zsh_default; then
        print_done "Default shell changed to zsh."
    else
        print_error "Failed to change default shell to zsh."
        return 1
    fi
fi

# Link Zsh configuration
print_start "Linking zsh configuration..."
if zsh_cleanup; then
    print_done "Zsh configuration linked."
else
    print_error "Failed to link Zsh configuration."
    return 1
fi

# ---------------------------------------------------------
# 7. Oh My Zsh Setup
# ---------------------------------------------------------

omz_script_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
print_header "Oh My Zsh setup"

if ! is_omz_installed; then
    print_start "Oh My Zsh not found. Installing Oh My Zsh..."
    install_silent "omz" sh -c "$(curl -fsSL $omz_script_url)" "" --unattended --keep-zshrc || return 1
    # Post-install cleanup
    rm -rf "$CONFDIR/zsh"
else
    print_done "Oh My Zsh is already installed."
fi
print_version omz version

# Install Oh My Zsh plugins
print_start "Installing Oh My Zsh plugins..."
install_omz_plugin zsh-autosuggestions
install_omz_plugin zsh-syntax-highlighting

# Link Zsh configuration
print_start "Re-linking zsh configuration..."
if zsh_cleanup; then
    print_done "Zsh configuration re-linked."
else
    print_error "Failed to re-link Zsh configuration."
    return 1
fi

# ---------------------------------------------------------
# 8. Oh My Posh Setup
# ---------------------------------------------------------

omp_script_url="https://ohmyposh.dev/install.sh"
print_header "Oh My Posh Setup"

if ! is_installed oh-my-posh; then
    print_start "oh-my-posh not found. Installing oh-my-posh..."
    curl -s $omp_script_url | bash -s -- -d "$XDG_BIN_HOME" || return 1
    print_done "oh-my-posh installed."
else
    print_info "oh-my-posh is already installed."
fi
print_version oh-my-posh

# ---------------------------------------------------------
# 9. Basic tools & finalization
# ---------------------------------------------------------

print_header "Basic tools & finalization"

# Setup locales on Linux systems
is_linux && setup_locale

# mc ------------------------------------------------------
if ! is_installed mc; then
    print_start "Midnight Commander not found. Installing mc..."
    if is_macos; then
        install_silent "mc" brew install mc || return 1
    elif is_linux; then
        install_silent "mc" sudo apt install mc -y || return 1
    fi
    print_done "Midnight Commander installed."
else
    new_line
    print_info "Midnight Commander is already installed."
fi
# Reinstalling mc skins
print_info "Reinstalling mc skins..."
mkdir -p "$XDG_DATA_HOME/mc"
lns "$GHCONFDIR/mc/skins" "$XDG_DATA_HOME/mc/skins"
print_version mc

# bc ------------------------------------------------------
if ! is_installed bc; then
    print_start "bc not found. Installing bc..."
    if is_macos; then
        install_silent "bc" brew install bc || return 1
    elif is_linux; then
        install_silent "bc" sudo apt install bc -y || return 1
    fi
    print_done "bc installed."
else
    print_info "bc is already installed."
fi
print_version bc

# htop ----------------------------------------------------
if ! is_installed htop; then
    print_start "htop not found. Installing htop..."
    if is_macos; then
        install_silent "htop" brew install htop || return 1
    elif is_linux; then
        install_silent "htop" sudo apt install htop -y || return 1
    fi
    print_done "htop installed."
else
    new_line
    print_info "htop is already installed."
fi
print_version htop

# Bash cleanup and fallback configuration
print_start "Fallback bash configuration..."
# Remove old bash config files...
rm -f $HOME/.bash*
# ...and link new ones as fallback
lns "$GHCONFDIR/bash/.bashrc" "$HOME/.bashrc"
lns "$GHCONFDIR/bash/.bash_profile" "$HOME/.bash_profile"
print_done "Bash configuration linked."

print_title "Installation Completed"
echo -e "The core shell installation and configuration is now complete.\n"
echo -e "Restart your terminal or log out and back in for all changes to take effect.\n"

# Attempt to shwitch to zsh immediately
exec zsh
