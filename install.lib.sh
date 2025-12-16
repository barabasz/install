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

# Function to show current date/time and version
show_date_time_version() {
    local date="$(date '+%Y-%m-%d @ %H:%M:%S')"
    echo -e "Date: $y${date}$x | Version: $y${version}${x}\n"
}

# Function to log current date/time and version to log file
log_date_time_version() {
    local date="$(date '+%Y-%m-%d @ %H:%M:%S')"
    {
        echo "Date: $date | Version: $version"
        echo ""
    } >> "$LOGFILE"

}

# Load color variables
load_colors() {
    # ANSI color codes - work universally without tput dependency
    r='\033[0;31m'      # Red
    g='\033[0;32m'      # Green
    y='\033[0;33m'      # Yellow
    b='\033[0;34m'      # Blue
    p='\033[0;35m'      # Purple
    c='\033[0;36m'      # Cyan
    w='\033[0;37m'      # White
    x='\033[0m'         # Reset
}

# Function to print list of things to be installed (universal zsh/bash)
print_commands() {
    local output=""
    for cmd in "$@"; do
        output+="• ${g}${cmd}${x} "
    done
    echo -e "${output}•"
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
    local len=$((${#text} + 4 + ${#script_type} + 3))
    echo -e "${y}$(repeat_char '▁' "$len")"
    echo -e "${y}█ $text ${w}($script_type) ${y}█"
    echo -e "$(repeat_char '▔' "$len")${x}"
    # Log title to file
    {
        echo "$(repeat_char '▁' "$len")▁▁▁▁"
        echo "█ $text Log ($script_type) █"
        echo "$(repeat_char '▔' "$len")▔▔▔▔"
    } >> "$LOGFILE"
}

# Calculate elapsed time if START_TIME is set
get_elapsed_time() {
    if [[ -n "$START_TIME" ]]; then
        local current_time=$(date +%s)
        local elapsed=$((current_time - START_TIME))
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        local seconds=$((elapsed % 60))
        local output=""

        # Format elapsed time
        if [[ $hours -gt 0 ]]; then
            output=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)
        else
            output=$(printf "%02d:%02d" $minutes $seconds)
        fi
        echo -$output
    else
        echo ""
    fi
}

# Print formatted header with underline
# Usage: print_header "some text"
print_header() {
    # Keep sudo timestamp alive in each section
    sudo -v
    local text=""
    local text_elapsed=""

    if [[ -z "$step" || -z "$steps" ]]; then
        text="$1"
    else
        text="${step}/${steps}: $1"
    fi

    # Log section header to file
    {
        echo ""
        echo "█ SECTION $text"
        echo "█ Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "█ Elapsed: $(get_elapsed_time)"
        echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
    } >> "$LOGFILE"

    text_elapsed=" ${w}(elapsed: $(get_elapsed_time))${x}"
    local len=$((${#text} + 2))
    local line=""
    local i
    for ((i=0; i<len; i++)); do line+="▔"; done
    echo -e "\n${y}█ $text${x}$text_elapsed"
    echo -e "${y}$line${x}"
    step=$((step + 1))
}

# Print formatted end header with underline (green color)
# Usage: print_end_header "some text"
print_end_header() {
    local text="❇️ $1"
    local text_elapsed=""
    
    # Calculate elapsed time if START_TIME is set
    if [[ -n "$START_TIME" ]]; then
        local elapsed_str
        elapsed_str=$(get_elapsed_time)
        text_elapsed=" ${w}(elapsed: $elapsed_str)${x}"
    fi
    text_elapsed=$(get_elapsed_time)

    local len=$((${#text} + 2))
    local line=""
    local i
    for ((i=0; i<len; i++)); do line+="▔"; done
    echo -e "\n${g}█ $text${x}$text_elapsed"
    echo -e "${g}$line${x}"
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
    echo -e "${w}★ ${text}${x}"
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

# Log message to file only (not displayed to user)
# Usage: print_log "message"
print_log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOGFILE"
}

# Run command silently, log output to file
# Usage: run_silent "operation_name" command [args...]
# Example: run_silent "chmod" chmod +x "$FILE" || return 1
run_silent() {
    local operation="$1"
    shift
    local cmd="$*"

    {
        echo ""
        echo "=========================================="
        echo "Operation: $operation"
        echo "Command: $cmd"
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=========================================="
    } >> "$LOGFILE"

    if "$@" >> "$LOGFILE" 2>&1; then
        return 0
    else
        print_error "Failed to execute: '$cmd'"
        print_info "See log: $LOGFILE"
        return 1
    fi
}

# Install command silently, log output to file
# Usage: install_silent "app_name" command [args...]
# Example: install_silent "gh" brew install gh || return 1
install_silent() {
    local name="$1"
    shift
    local cmd="$*"

    {
        echo ""
        echo "=========================================="
        echo "Installing: $name"
        echo "Command: $cmd"
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=========================================="
    } >> "$LOGFILE"

    if "$@" >> "$LOGFILE" 2>&1; then
        return 0
    else
        print_error "Failed to install $name."
        print_info "See log: $LOGFILE"
        return 1
    fi
}

# Check if program is installed (executable exists in PATH)
# with special case for "omz" (function check)
# Usage: is_installed "command_name"
is_installed() {
    [[ $# -eq 1 ]] || return 1
    if [[ "$1" == "omz" ]]; then
        # Check if omz function exists
        if [[ -n "${BASH_VERSION}" ]]; then
            [[ "$(type -t omz 2>/dev/null)" == "function" ]]
        elif [[ -n "${ZSH_VERSION}" ]]; then
            (( ${+functions[omz]} ))
        else
            type omz 2>/dev/null | grep -qw function
        fi
    else
        # Check if command exists as executable
        if [[ -n "${ZSH_VERSION}" ]]; then
            whence -p -- "$1" &>/dev/null
        else
            type -P -- "$1" &>/dev/null
        fi
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
        # Install without logging (called before step counter is set)
        sudo apt install -y kitty-terminfo &>/dev/null
        # Verify installation worked
        if ! has_kitty_terminfo; then
            print_warning "kitty terminfo not available; using xterm-256color as fallback."
            set_default_term
        fi
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
        sudo chsh -s "$zsh_path" "$USER"
    fi
}

# Create symbolic link safely (universal zsh/bash function)
# Usage: lns source target
lns() {
    local source="$1"
    local target="$2"
    
    # Validate source exists
    if [[ ! -e "$source" ]]; then
        print_error "Source does not exist: $source"
        return 1
    fi
    
    # Convert source to absolute path if relative
    [[ "$source" != /* ]] && source="$PWD/$source"
    
    # Remove target if exists (anything - link, file, directory)
    rm -rf "$target"
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
    # Create symlink
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
    rm -f "$HOME/.zshrc"
    rm -f "$HOME/.zprofile"
    rm -f "$HOME/.zlogin"
    rm -f "$HOME/.zlogout"
    rm -f "$HOME/.bash_history"
    rm -f "$HOME/.bash_logout"
    lns "$GHCONFDIR/zsh/.zshenv" "$HOME/.zshenv"
}

# Git clone function with error handling
# Usage: git_clone "repository_name" "log_prefix"
git_clone() {
    local repo="https://github.com/barabasz/${1}.git"
    local log="git_${1}_clone"
    if ! run_silent "$log" git clone --progress "$repo"; then
        print_error "Failed to clone ${1} repository."
        return 1
    fi
}

# Install Oh My Zsh plugin
# Usage: install_omz_plugin "plugin_name"
install_omz_plugin() {
        local repo="https://github.com/zsh-users/$1.git"
        local pdir="$ZSH_CUSTOM/plugins/$1"
        print_info "Installing $1"
        [[ -d $pdir ]] && rm -rf "$pdir"
        install_silent "$1" git clone "$repo" "$pdir"
}

# Uncomment locale in /etc/locale.gen
uncomment_locale() {
    sudo sed -i "s/^# *\($1\)/\1/" /etc/locale.gen
    if grep -q "^$1" /etc/locale.gen; then
        echo "Locale $1 has been uncommented in /etc/locale.gen."
    else
        echo "Failed to uncomment locale $1 in /etc/locale.gen."
        return 1
    fi
}

# Install locale if not present
install_locale() {
    if [[ -z "$(localectl list-locales | grep "$1")" ]]; then
        uncomment_locale "$1"
        sudo locale-gen "$1" | grep 'done'
    else
        echo "Locale $1 already exists."
    fi
}

# Setup locales for the system
setup_locale() {
    print_start 'Installing locales...'
    # Refresh sudo timestamp before locale operations
    sudo -v || return 1
    export LC_ALL=C.utf8
    {
        echo ""
        echo "=========================================="
        echo "Installing: locales package"
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=========================================="
    } >> "$LOGFILE"
    sudo apt install -yq locales >> "$LOGFILE" 2>&1
    local lang_pl="pl_PL.UTF-8"
    local lang_en="en_US.UTF-8"
    install_locale "$lang_pl"
    install_locale "$lang_en"

    print_start 'Setting locales...'
    # English language
    export LANG=$lang_en
    sudo update-locale LANG="$lang_en"
    export LANGUAGE=$lang_en
    sudo update-locale LANGUAGE="$lang_en"
    export LC_MESSAGES=$lang_en
    sudo update-locale LC_MESSAGES="$lang_en"
    # Polish regiional settings
    export LC_ADDRESS=$lang_pl
    sudo localectl set-locale LC_ADDRESS="$lang_pl"
    export LC_COLLATE=$lang_pl
    sudo localectl set-locale LC_COLLATE="$lang_pl"
    export LC_CTYPE=$lang_pl
    sudo localectl set-locale LC_CTYPE="$lang_pl"
    export LC_IDENTIFICATION=$lang_pl
    sudo localectl set-locale LC_IDENTIFICATION="$lang_pl"
    export LC_MEASUREMENT=$lang_pl
    sudo localectl set-locale LC_MEASUREMENT="$lang_pl"
    export LC_MONETARY=$lang_pl
    sudo localectl set-locale LC_MONETARY="$lang_pl"
    export LC_NAME=$lang_pl
    sudo localectl set-locale LC_NAME="$lang_pl"
    export LC_NUMERIC=$lang_pl
    sudo localectl set-locale LC_NUMERIC="$lang_pl"
    export LC_PAPER=$lang_pl
    sudo localectl set-locale LC_PAPER="$lang_pl"
    export LC_TELEPHONE=$lang_pl
    sudo localectl set-locale LC_TELEPHONE="$lang_pl"
    export LC_TIME=$lang_pl
    sudo localectl set-locale LC_TIME="$lang_pl"
    print_done 'Locales installed and set.'
    echo
}

# Set Warsaw timezone (Linux only)
set-warsaw-timezone() {
    if ! is_macos; then
        print_start 'Setting timezone...'
        if [[ "$(grep -o 'Warsaw' /etc/timezone)" != "Warsaw" ]]; then
            sudo timedatectl set-timezone Europe/Warsaw
            sudo dpkg-reconfigure -f noninteractive tzdata
            print_done 'Timezone set to Europe/Warsaw.'
        else
            print_info "Timezone: $(cat /etc/timezone)"
        fi
    fi
}

# modify /etc/needrestart/needrestart.conf
# use: needrestart-mod parameter value
needrestart-mod() {
    local filename=/etc/needrestart/needrestart.conf
    if [[ -f $filename ]]; then
        sudo sed -i "s/^#\?\s\?\$nrconf{$1}.*/\$nrconf{$1} = $2;/" "$filename"
    fi
}

# set needrestart to quiet mode
needrestart-quiet() {
    needrestart-mod verbosity 0
    needrestart-mod systemctl_combine 0
    needrestart-mod kernelhints 0
    needrestart-mod ucodehints 0
}

# set needrestart to verbose mode
needrestart-verbose() {
    needrestart-mod verbosity 1
    needrestart-mod systemctl_combine 1
    needrestart-mod kernelhints 1
    needrestart-mod ucodehints 1
}
