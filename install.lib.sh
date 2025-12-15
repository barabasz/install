#!/bin/zsh

# =============================================================
# Helper functions for Automated core shell installation script
# Author: https://github.com/barabasz
# Repository: https://github.com/barabasz/install
# Date: 2024-06-15
# License: MIT
# =============================================================

# Below functions are used exclusively in install.sh
# They are intentionally universal for both bash and zsh shells

# Load color variables
load_colors() {
    if is_installed tput; then
        # Using tput for better compatibility
        r=$(tput setaf 1)   # Red
        g=$(tput setaf 2)   # Green
        y=$(tput setaf 3)   # Yellow
        b=$(tput setaf 4)   # Blue
        p=$(tput setaf 5)   # Purple
        c=$(tput setaf 6)   # Cyan
        w=$(tput setaf 7)   # White
        x=$(tput sgr0)      # Reset
        return
    else
        # Fallback to ANSI codes
        r='\033[0;31m'      # Red
        g='\033[0;32m'      # Green
        y='\033[0;33m'      # Yellow
        b='\033[0;34m'      # Blue
        p='\033[0;35m'      # Purple
        c='\033[0;36m'      # Cyan
        w='\033[0;37m'      # White
        x='\033[0m'         # Reset
    fi
}

# Function to print list of things to be installed
print_commands() {
    local output=""
    
    for cmd in "$@"; do
        output+="• ${g}${cmd}${x} "
    done

    print "${output}•\n"
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

# Print new line
new_line() {
    echo -e "\n"
}

# Print info message (cyan info symbol)
# Usage: print_info "some text"
print_info() {
    local text="$1"
    echo -e "${c}ℹ ${text}${x}"
}

# Print start message with white star
# Usage: print_start "some text"
print_start() {
    local text="$1"
    echo -e "\n${w}★ ${text}${x}"
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
# Example: run_silent "chmod" chmod +x "$FILE" || return 1
run_silent() {
    local log="$LOGDIR/${step}_$1.log"
    shift
    local cmd="$*"
    
    if "$@" &> "$log"; then
        return 0
    else
        print_error "Failed to execute: '$cmd'"
        print_info "See log: $log"
        return 1
    fi
}

# Install command silently, log output to file
# Usage: install_silent "app_name" command [args...]
# Example: install_silent "gh" brew install gh || return 1
install_silent() {
    local name="$1"
    local log="$LOGDIR/${step}_installing_${name}.log"
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

# Verify and install kitty terminfo if missing
check_terminfo() {
    if is_linux && ! has_kitty_terminfo; then
        run_silent "kitty-terminfo" sudo apt install -y kitty-terminfo || {
            print_warning "Failed to install kitty terminfo; using xterm-256color as fallback."
            set_default_term
        }
    fi
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

# Create symbolic link safely (universal zsh/bash function)
# Usage: lns source target
lns() {
    local source target target_dir current
    source="$(realpath -s "$1")"
    target="$(realpath -s "$2")"
    target_dir="$(dirname "$target")"
    
    # Validate: source must exist
    if [[ ! -e "$source" ]]; then
        print_error "Source does not exist: $source"
        return 1
    fi
    
    # Create parent directory for the symlink if needed
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi
    
    # Handle existing target
    if [[ -L "$target" ]]; then
        # Target is a symlink - check if it already points to source
        current="$(readlink "$target")"
        if [[ "$current" == "$source" ]]; then
            return 0  # Already correct, nothing to do
        else
            rm "$target"  # Points elsewhere, remove and recreate
        fi
    elif [[ -e "$target" ]]; then
        # Target is a real file/directory - backup before replacing
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
    rm -f $HOME/.zshrc
    rm -f $HOME/.zprofile
    rm -f $HOME/.zlogin
    rm -f $HOME/.zlogout
    rm -f $HOME/.bash_history
    rm -f $HOME/.bash_logout
    lns "$GHCONFDIR/zsh/.zshenv" "$HOME/.zshenv"
}

# Git clone function with error handling
# Usage: git_clone "repository_name" "log_prefix"
git_clone() {
    local repo="https://github.com/barabasz/${1}.git"
    local log="git_${1}_clone"
    run_silent "$log" git clone --progress $repo
    if [[ $? -ne 0 ]]; then
        print_error "Failed to clone ${1} repository."
        return 1
    else
        return 0
    fi
}

# Install Oh My Zsh plugin
# Usage: install_omz_plugin "plugin_name"
install_omz_plugin() {
        local repo=https://github.com/zsh-users/$1.git
        local pdir=$ZSH_CUSTOM/plugins/$1
        print_info "Installing $1"
        [[ -d $pdir ]] && rm -rf $pdir
        install_silent "$1" git clone $repo $pdir
}

# Uncomment locale in /etc/locale.gen
function uncomment_locale() {
    sudo sed -i "s/^# *\($1\)/\1/" /etc/locale.gen
    if grep -q "^$1" /etc/locale.gen; then
        echo "Locale $1 has been uncommented in /etc/locale.gen."
    else
        echo "Failed to uncomment locale $1 in /etc/locale.gen."
        return 1
    fi
}

# Install locale if not present
function install_locale() {
    if [[ -z "$(localectl list-locales | grep $1)" ]]; then
        uncomment_locale $1
        sudo locale-gen $1 | grep 'done'
    else
        echo "Locale $1 already exists."
    fi
}

# Setup locales for the system
setup_locale() {
    print_start 'Installing locales...'
    export LC_ALL=C.utf8
    sudo apt install -yq locales >/dev/null 2>&1
    lang_pl="pl_PL.UTF-8"
    lang_en="en_US.UTF-8"
    install_locale $lang_pl
    install_locale $lang_en
    
    printhead 'Setting locales...'
    # English language
    export LANG=$lang_en
    sudo update-locale LANG=$lang_en
    export LANGUAGE=$lang_en
    sudo update-locale LANGUAGE=$lang_en
    export LC_MESSAGES=$lang_en
    sudo update-locale LC_MESSAGES=$lang_en
    # Polish regiional settings
    export LC_ADDRESS=$lang_pl
    sudo localectl set-locale LC_ADDRESS=$lang_pl
    export LC_COLLATE=$lang_pl
    sudo localectl set-locale LC_COLLATE=$lang_pl
    export LC_CTYPE=$lang_pl
    sudo localectl set-locale LC_CTYPE=$lang_pl
    export LC_IDENTIFICATION=$lang_pl
    sudo localectl set-locale LC_IDENTIFICATION=$lang_pl
    export LC_MEASUREMENT=$lang_pl
    sudo localectl set-locale LC_MEASUREMENT=$lang_pl
    export LC_MONETARY=$lang_pl
    sudo localectl set-locale LC_MONETARY=$lang_pl
    export LC_NAME=$lang_pl
    sudo localectl set-locale LC_NAME=$lang_pl
    export LC_NUMERIC=$lang_pl
    sudo localectl set-locale LC_NUMERIC=$lang_pl
    export LC_PAPER=$lang_pl
    sudo localectl set-locale LC_PAPER=$lang_pl
    export LC_TELEPHONE=$lang_pl
    sudo localectl set-locale LC_TELEPHONE=$lang_pl
    export LC_TIME=$lang_pl
    sudo localectl set-locale LC_TIME=$lang_pl
    print_done 'Locales installed and set.'
}

# Set Warsaw timezone (Linux only)
function set-warsaw-timezone() {
    if [[ "$(osname)" != "macos" ]]; then
        printhead 'Setting timezone...'
        if [[ "$(cat /etc/timezone | grep -o 'Warsaw')" != "Warsaw" ]]; then
            sudo timedatectl set-timezone Europe/Warsaw
            sudo dpkg-reconfigure -f noninteractive tzdata
        else
            echo "Timezone: $(cat /etc/timezone)"
        fi
    fi
}

# modify /etc/needrestart/needrestart.conf
# use: needrestart-mod parameter value
function needrestart-mod() {
    filename=/etc/needrestart/needrestart.conf
    if [[ -f $filename ]]; then
        sudo sed -i "s/^#\?\s\?\$nrconf{$1}.*/\$nrconf{$1} = $2;/" $filename
    fi
}

# set needrestart to quiet mode
function needrestart-quiet() {
    needrestart-mod verbosity 0
    needrestart-mod systemctl_combine 0
    needrestart-mod kernelhints 0
    needrestart-mod ucodehints 0
}

# set needrestart to verbose mode
function needrestart-verbose() {
    needrestart-mod verbosity 1
    needrestart-mod systemctl_combine 1
    needrestart-mod kernelhints 1
    needrestart-mod ucodehints 1
}