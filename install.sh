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
# 5. Cloning repositories
# 6. Zsh setup
# 7. Oh My Zsh setup
# 8. oh-my-posh setup
# 9. Finalization

# =========================================================
# Initial environment setup
# =========================================================

## Script counters
step=1
steps=9

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
export GHLIBDIR=$GHDIR/lib
export GHCONFDIR=$GHDIR/config

# Temporary locale settings to avoid issues during installation
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Brew environment variables for non-interactive installation
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_VERBOSE=0
export HOMEBREW_DEBUG=0
export NONINTERACTIVE=1

# Create base directories
mkdir -p $TMP
mkdir -p $CACHEDIR
mkdir -p $ZSH_SESSIONS_DIR
mkdir -p $CONFDIR
mkdir -p $XDG_BIN_HOME
mkdir -p $XDG_BIN_HOME
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_STATE_HOME
mkdir -p $LOGDIR
mkdir -p $VENVDIR
# Ubuntu/Debian fix for Homebrew
if ! is_macos; then
    sudo mkdir -p /home/linuxbrew/
    sudo chmod 755 /home/linuxbrew/
fi

# Load colors
r=$(tput setaf 1)    # red
g=$(tput setaf 2)    # green
y=$(tput setaf 3)    # yellow
c=$(tput setaf 6)    # cyan
w=$(tput setaf 7)    # white
x=$(tput sgr0)       # reset

# Installation script URLs
brew_script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
omz_script_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# =========================================================
# Helper functions
# =========================================================

# Function to print list of things to be installed
print_commands() {
  local commands=("sudo" "git" "brew" "gh" "zsh" "Oh My Zsh" "oh-my-posh")
  local output=""
  
  for cmd in "${commands[@]}"; do
    output+="• ${g}${cmd}${x} "
  done
  
  echo -e "${output}•\n"
}

# Function to prompt the user for continuation
# Usage: prompt_continue ["Custom question?"]
prompt_continue() {
    local prompt="${1:-Do you want to continue?}"
    local yn
    
    while true; do
        if [[ -n "$BASH_VERSION" ]]; then
            read -r -p "$prompt (Y/N): " yn
        else
            read -r "yn?$prompt (Y/N): "
        fi
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) echo "Aborted."; return 1 ;;
            "") ;;
            *) echo "Please answer Y or N." ;;
        esac
    done
}

# Generate repeated character string
# Usage: repeat_char "char" count
repeat_char() {
    local char="$1" count="$2" result="" i
    for ((i=0; i<count; i++)); do result+="$char"; done
    printf '%s' "$result"
}

# Print formatted title in a box
# Usage: print_title "some text"
print_title() {
    local text="$1"
    local len=$((${#text} + 4))
    printf '%s%s\n' "$y" "$(repeat_char '▁' "$len")"
    printf '%s█ %s █\n' "$y" "$text"
    printf '%s%s%s\n' "$(repeat_char '▔' "$len")" "$x"
}

# Print formatted header with underline
# Usage: print_header "some text"
print_header() {
    local text="${step}/${steps}: $1"
    local len=${#text}+2
    local line=""
    local i
    for ((i=0; i<len; i++)); do line+="▔"; done
    printf '\n%s%s%s%s\n' "$y" "█ " "$text" "$x"
    printf '%s%s%s\n' "$y" "$line" "$x"
    step=$((step + 1))
}

# Print info message (cyan info symbol)
# Usage: print_info "some text"
print_info() {
    local text="$1"
    echo -e "${c}ℹ ${text}${x}"
}

# Print done message with green checkmark
# Usage: print_done "some text"
print_done() {
    local text="$1"
    echo -e "${g}✔ ${text}${x}"
}

# Print error message with red cross
# Usage: print_error "some text"
print_error() {
    local text="$1"
    echo -e "${r}✘ ${text}${x}\n"
}

# Print warning message with yellow warning sign
# Usage: print_warning "some text"
print_warning() {
    local text="$1"
    echo -e "${y}⚠ ${text}${x}\n"
}

# Print version of a command
# Usage: print_version "command" ["--version"]
print_version() {
    local cmd="$1"
    local opt="${2:---version}"
    local ver
    
    if ! command -v "$cmd" &> /dev/null; then
        print_error "$cmd not found"
        return 1
    fi
    
    ver=$("$cmd" "$opt" 2>&1 | head -n1)
    print_info "$cmd version:${x} $ver"
}

# Run command silently, log output to file
# Usage: run_silent "logfile" command [args...]
# Example: run_silent "chmod" chmod +x "$FILE" || exit 1
run_silent() {
    local log="$LOGDIR/${step}_$1.log"
    shift
    local cmd="$*"
    
    if "$@" &> "$log"; then
        return 0
    else
        print_error "Failed to execute: $cmd"
        print_info "See log: $log"
        return 1
    fi
}

# Install command silently, log output to file
# Usage: install_silent "name" "logfile" command [args...]
# Example: install_silent "gh" brew install gh || exit 1
install_silent() {
    local name="$1"
    local log="$LOGDIR/${step}_${name}.log"
    shift
    local cmd="$*"
    
    if "$@" &> "$log"; then
        print_done "$name installed."
        return 0
    else
        print_error "Failed to install $name."
        print_info "See log: $log"
        return 1
    fi
}

# Check if program is installed (executable exists in PATH)
is_installed() {
    [[ $# -eq 1 ]] || return 1
    if [[ -n $ZSH_VERSION ]]; then
        whence -p -- "$1" &>/dev/null
    else
        type -P -- "$1" &>/dev/null
    fi
}

# Check if current OS is Debian-based (includes Ubuntu, Mint, etc.)
is_debian_based() {
    [[ -f /etc/debian_version ]]
}

# Check if current OS is specifically Debian (not Ubuntu or other derivatives)
is_debian() {
    [[ -f /etc/os-release ]] && grep -q '^ID=debian' /etc/os-release
}

# Check if current OS is specifically Ubuntu
is_ubuntu() {
    [[ -f /etc/os-release ]] && grep -q '^ID=ubuntu' /etc/os-release
}

# Check if current OS is macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Check if current OS is Linux
is_linux() {
    [[ "$(uname)" == "Linux" ]]
}

# Check if kitty terminfo is installed
has_kitty_terminfo() {
    infocmp xterm-kitty &>/dev/null
}

# Set default terminal type to support colors
set_default_term() {
    export TERM=xterm-256color
    export COLORTERM=truecolor
}

# Execute brew shellenv
brew_shellenv() {
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
}

# Get current user's default shell
get_current_shell() {
    if is_macos; then
        dscl . -read ~/ UserShell | awk '{print $2}'
    else
        getent passwd "$USER" | cut -d: -f7
    fi
}

# Check if zsh is already the default shell
is_zsh_default() {
    [[ "$(get_current_shell)" == "$(command -v zsh)" ]]
}

# Set zsh as default shell
set_zsh_default() {
    local zsh_path
    zsh_path=$(command -v zsh)
    
    if is_macos; then
        sudo dscl . -create "/Users/$USER" UserShell "$zsh_path"
    else
        if ! grep -qx "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
        fi
        chsh -s "$zsh_path"
    fi
}

# Check if Oh My Zsh is installed
is_omz_installed() {
    omz version &>/dev/null
}

# Create symbolic link safely
# Usage: lns source target
lns() {
    local source="$1"
    local target="$2"
    local target_dir
    target_dir=$(dirname "$target")
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        print_error "Source does not exist: $source"
        return 1
    fi
    
    # Ensure target directory exists
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi
    
    # Check if target already exists
    if [[ -L "$target" ]]; then
        local current
        current=$(readlink "$target")
        if [[ "$current" == "$source" ]]; then
            return 0
        else
            rm "$target"
        fi
    elif [[ -e "$target" ]]; then
        mv "$target" "${target}.bak"
    fi
    
    ln -s "$source" "$target"
}

# Link config folder from repository to config directory
# Usage: lnconf folder
lnconf() {
    local folder="$1"
    
    if lns "$GHCONFDIR/$folder" "$CONFDIR/$folder"; then
        print_done "$folder linked."
    else
        print_error "Failed to link $folder."
        return 1
    fi
}

# Zsh cleanup function to remove old config files and relink .zshenv
zsh_cleanup() {
    lnconf zsh
    rm -f $HOME/.zshrc
    rm -f $HOME/.zprofile
    rm -f $HOME/.zlogin
    rm -f $HOME/.zlogout
    lns "$GHCONFDIR/zsh/.zshenv" "$HOME/.zshenv"
}

# =========================================================
# Main function
# =========================================================

# Ensure kitty terminfo is installed for proper terminal support
if is_linux && ! has_kitty_terminfo; then
    run_silent "kitty-terminfo" sudo apt install -y kitty-terminfo || {
        print_warning "Failed to install kitty terminfo; using xterm-256color as fallback."
        set_default_term
    }
fi

print_title "Core Shell Installation Script"
echo -e "\nThis script will install and configure following components on your system:"
print_commands
echo -e "Log directory: ${y}$LOGDIR${x}\n"

# Prompt user to continue
prompt_continue
if [[ $? -ne 0 ]]; then
    exit 1
fi

if ! is_macos; then
    print_info "Updating apt package lists..."
    run1
    print_done "Package lists updated."
fi

# ---------------------------------------------------------
# 1. Sudo Setup (Linux only)
# ---------------------------------------------------------

print_header "Setting up sudo..."

if ! is_installed sudo; then
    print_info "sudo not found. Installing sudo..."
    if is_debian_based; then
        install_silent "sudo" "sudo_install" su -c "apt-get install -qq sudo" || exit 1
        local sudostr="$(whoami) ALL=(ALL:ALL) ALL"
        su -c "echo '$sudostr' | sudo EDITOR='tee -a' visudo"
    fi
else
    print_done "sudo is already installed."
fi
print_version sudo

# Force sudo password prompt
echo -e "\n${y}⚠ Enter your password for sudo access:${x}"
sudo echo > /dev/null

# ---------------------------------------------------------
# 2. Git Setup
# ---------------------------------------------------------

print_header "Setting up Git..."

if ! is_installed git; then
    print_info "Git not found. Installing Git..."
    if is_macos; then
        install_silent "git" "git_install" xcode-select --install || exit 1
    elif is_linux; then
        run_silent "apt_update" sudo apt update || exit 1
        install_silent "git" "git_install" sudo apt install git -y || exit 1
    fi
else
    print_done "Git is already installed."
fi
print_version git

# ---------------------------------------------------------
# 3. Homebrew Setup
# ---------------------------------------------------------

print_header "Setting up Homebrew..."

# Execute shellenv if brew is installed
brew_shellenv

if ! is_installed brew; then
    print_info "Homebrew not found. Installing Homebrew..."
    install_silent "brew" "brew_install" /bin/bash -c "$(curl -fsSL $brew_script_url)" || exit 1
    # Execute shellenv after brew installation
    brew_shellenv
else
    print_done "Homebrew is already installed"
fi
print_version brew

# Disable analytics
print_info "Disabling Homebrew analytics..."
run_silent "brew_analytics_disable" brew analytics off
print_done "Homebrew analytics disabled."

# Update Homebrew
print_info "Updating Homebrew..."
run_silent "brew_update" brew update
run_silent "brew_upgrade" brew upgrade
print_done "Homebrew updated."

# ---------------------------------------------------------
# 4. GitHub CLI Setup
# ---------------------------------------------------------

print_header "Setting up Github CLI..."

if ! is_installed gh; then
    print_info "Installing GitHub CLI..."

    if is_macos; then
        install_silent "gh" "gh_install" brew install gh || exit 1
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

else
    print_done "GitHub CLI is already installed."
fi
print_version gh

# ---------------------------------------------------------
# 5. Cloning Repositories
# ---------------------------------------------------------

print_header "Cloning repositories..."

cd $GHDIR
repos=("bin" "config" "install" "lib")
for repo in "${repos[@]}"; do
    print_info "Cloning $repo..."
    git clone "https://github.com/barabasz/${repo}.git" &> "$LOGDIR/${step}_git_${repo}_clone.log"
    print_done "$repo successfully cloned."
done

print_info "Symlinking directories and files..."

# Library
lns "$GHLIBDIR" "$LIBDIR"
# Bindir
lns "$GHBINDIR" "$BINDIR"

# zsh cleanup and linking
zsh_cleanup




# logic

# ---------------------------------------------------------
# 6. Zsh Setup
# ---------------------------------------------------------

print_header "Setting up Zsh..."

# Install Zsh if not present (Linux only)
if ! is_macos && ! is_installed zsh; then
    print_info "Zsh not found. Installing Zsh..."
    run_silent "zsh_install" sudo apt install zsh -y || exit 1
else
    print_done "Zsh is already installed."
fi
print_version zsh

print_info "Setting Zsh as default shell..."

if is_zsh_default; then
    print_done "zsh is already the default shell."
else
    if set_zsh_default; then
        print_done "Default shell changed to zsh."
    else
        print_error "Failed to change default shell to zsh."
        exit 1
    fi
fi

# Link Zsh configuration
print_info "Linking zsh configuration..."
if zsh_cleanup; then
    print_done "Zsh configuration linked."
else
    print_error "Failed to link Zsh configuration."
    exit 1
fi

# bash fallback
print_info "Linking fallback bash configuration..."
lns "$GHCONFDIR/bash/.bashrc" "$HOME/.bashrc"
lns "$GHCONFDIR/bash/.bash_profile" "$HOME/.bash_profile"
print_done "Bash configuration linked."


# ---------------------------------------------------------
# 7. Oh My Zsh Setup
# ---------------------------------------------------------

print_header "Setting up Oh My Zsh..."

if ! is_omz_installed; then
    [[ ! -n $ZSH ]] && ZSH=$HOME/.config/omz
    [[ ! -n $ZSH_CUSTOM ]] && ZSH_CUSTOM=$ZSH/custom
    print_info "Oh My Zsh not found. Installing Oh My Zsh..."
    install_silent "omz" "omz_install" sh -c "$(curl -fsSL $omz_script_url)" "" --unattended --keep-zshrc || exit 1
    # Post-install cleanup
    rm -rf "$CONFDIR/zsh"
else
    print_done "Oh My Zsh is already installed."
fi
print_version omz version

# Link Zsh configuration
print_info "Re-linking zsh configuration..."
if zsh_cleanup; then
    print_done "Zsh configuration re-linked."
else
    print_error "Failed to re-link Zsh configuration."
    exit 1
fi

# ---------------------------------------------------------
# 8. oh-my-posh Setup
# ---------------------------------------------------------

print_header "Setting up oh-my-posh..."

# ---------------------------------------------------------
# 9. Finalization
# ---------------------------------------------------------

print_header "Finalizing installation..."

# logic

