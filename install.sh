#!/bin/zsh

# =========================================================
# Automated core shell installation script for new systems
# Author: https://github.com/barabasz
# Repository: https://github.com/barabasz/install
# Date: 2024-06-15
# License: MIT
# =========================================================

# This script is meant to be run on a fresh system this way:
# source <(curl -fsSL https://raw.githubusercontent.com/barabasz/install/refs/heads/main/init)

# Script steps:
# 1. sudo setup
# 2. Git setup
# 3. Homebrew setup
# 4. GitHub CLI setup
# 5. Cloning repositories
# 6. Symlink directories and files
# 7. Zsh setup
# 8. Oh My Zsh setup
# 9. oh-my-posh setup
# - makes symbolic links for zsh, omz and oh-my-posh configurations
# - sets locale settings
# - reloads zsh to apply changes

local step=1
local steps=5

# =========================================================
# Initial environment setup
# =========================================================

# Create base directories
mkdir -p $HOME/.cache
mkdir -p $HOME/.cache/.zsh_sessions
mkdir -p $HOME/.config
mkdir -p $HOME/.local
mkdir -p $HOME/.local/bin
mkdir -p $HOME/.local/share
mkdir -p $HOME/.local/state
mkdir -p $HOME/.tmp
mkdir -p $HOME/.venv

## Folders and paths
export TMP=$HOME/.tmp
export TEMP=$TMP
export TEMPDIR=$TMP
export TMPDIR=$TMP
export BINDIR=$HOME/bin
export LIBDIR=$HOME/lib
export CONFDIR=$HOME/.config
export CACHEDIR=$HOME/.cache
export VENVDIR=$HOME/.venv
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$CONFDIR}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$CACHEDIR}
export XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# Temporary locale settings to avoid issues during installation
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# set terminal type to support colors
export TERM=xterm-256color

# Brew environment variables for non-interactive installation
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_VERBOSE=0
export HOMEBREW_DEBUG=0
export NONINTERACTIVE=1

# Load colors
r=$(tput setaf 1)    # red
g=$(tput setaf 2)    # green
y=$(tput setaf 3)    # yellow
c=$(tput setaf 6)    # cyan
w=$(tput setaf 7)    # white
x=$(tput sgr0)       # reset

# Installation script URLs
brew_script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

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

# Print formatted title in a box (cyan frame, white text)
# Usage: print_title "some text"
print_title() {
    local text="$1"
    local len=${#text}
    local line=""
    local i
    for ((i=0; i<len; i++)); do line+="━"; done
    
    printf '%s┍━%s━┑%s\n' "$y" "$line" "$x"
    printf '%s│%s %s %s│%s\n' "$y" "$y" "$text" "$y" "$x"
    printf '%s┕━%s━┙%s\n' "$y" "$line" "$x"
}

# Print formatted header with underline (yellow line, white text)
# Usage: print_header "some text"
print_header() {
    local text="${step}/${steps}: $1"
    local len=${#text}+2
    local line=""
    local i
    for ((i=0; i<len; i++)); do line+="▔"; done
    printf '\n%s%s%s%s\n' "$c" "█ " "$text" "$x"
    printf '%s%s%s\n' "$c" "$line" "$x"
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

# Execute brew shellenv
brew_shellenv() {
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
}

# =========================================================
# Main function
# =========================================================

print_title "Core System Installation Script"
echo -e "\nThis script will install and configure following components on your system:"
print_commands

# Prompt user to continue
prompt_continue
if [[ $? -ne 0 ]]; then
    exit 1
fi

# ---------------------------------------------------------
# 1. Sudo Setup (Linux only)
# ---------------------------------------------------------

print_header "Setting up sudo..."

if ! is_installed sudo; then
    print_info "sudo not found. Installing sudo..."
    if is_debian_based; then
        su -c "apt-get install -qq sudo 2> /dev/null"
        if [[ $? -eq 0 ]]; then
            print_done "sudo installed successfully."
        else
            print_error "Failed to install sudo. Exiting."
            exit 1
        fi
        sudostr="$(whoami) ALL=(ALL:ALL) ALL"
        su -c "echo '$sudostr' | sudo EDITOR='tee -a' visudo"
    fi
else
    print_done "sudo is already installed."
fi
print_info "sudo version:${x} $(sudo --version | head -n1)"

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
        xcode-select --install &> "$TMP/git_install.log"
        if [[ $? -eq 0 ]]; then
            print_done "Git installed successfully."
        else
            print_error "Git installation failed. Exiting."
            exit 1
        fi
    elif is_linux; then
        sudo apt update && sudo apt install git -y &> "$TMP/git_install.log"
        if [[ $? -eq 0 ]]; then
            print_done "Git installed successfully."
        else
            print_error "Git installation failed. Exiting."
            exit 1
        fi
    fi

else
    print_done "Git is already installed."
fi
print_info "Git version:${x} $(git --version)"

# ---------------------------------------------------------
# 3. Homebrew Setup
# ---------------------------------------------------------

print_header "Setting up Homebrew..."

# Execute shellenv if brew is installed
brew_shellenv

if ! is_installed brew; then

    print_info "Homebrew not found. Installing Homebrew..."

    # Ubuntu/Debian fix
    if ! is_macos; then
        sudo mkdir -p /home/linuxbrew/
        sudo chmod 755 /home/linuxbrew/
    fi

    # Excute Homebrew installation script
    /bin/bash -c "$(curl -fsSL $brew_script_url)" &> "$TMP/brew_install.log"
    if [[ $? -eq 0 ]]; then
        print_done "Homebrew installed successfully."
    else
        print_error "Homebrew installation failed. Exiting."
        exit 1
    fi
    # Execute shellenv after brew installation
    brew_shellenv
else
    print_done "Homebrew is already installed"
fi
print_info "Homebrew version:${x} $(brew --version | head -n1)"

# Disable analytics
print_info "Disabling Homebrew analytics..."
brew analytics off &>/dev/null
print_done "Homebrew analytics disabled."

# Update Homebrew
print_info "Updating Homebrew..."
brew update &> "$TMP/brew_update.log"
brew upgrade &> "$TMP/brew_upgrade.log"
print_done "Homebrew updated."

# ---------------------------------------------------------
# 4. GitHub CLI Setup
# ---------------------------------------------------------

print_header "Setting up Github CLI..."

if ! is_installed gh; then
    print_info "Installing GitHub CLI..."

    if is_macos; then
        brew install gh &> "$TMP/gh_install.log"
        if [[ $? -eq 0 ]]; then
            print_done "GitHub CLI installed successfully."
        else
            print_error "GitHub CLI installation failed. Exiting."
            exit 1
        fi
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
print_info "GitHub CLI version:${x} $(gh --version | head -n1)"

# ---------------------------------------------------------
# 5. Cloning Repositories
# ---------------------------------------------------------