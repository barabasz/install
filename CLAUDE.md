# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Automated shell installation scripts for bootstrapping fresh Ubuntu/Debian and macOS systems. The primary purpose is to set up a complete zsh-based shell environment with essential tools and configurations.

## Core Files

**install.sh** - Main bootstrap script designed to be run on fresh systems via:
```bash
source <(curl -fsSL https://raw.githubusercontent.com/barabasz/install/HEAD/install.sh)
```

**install.lib.sh** - Helper functions library loaded dynamically by install.sh

## Architecture

### Installation Flow (install.sh)

The script performs 9 sequential steps:

1. **Sudo Setup** (Linux only) - Installs sudo if missing, configures user permissions
2. **Git Setup** - Installs git via xcode-select (macOS) or apt (Linux)
3. **Homebrew Setup** - Installs Homebrew package manager
4. **GitHub CLI Setup** - Installs gh CLI tool
5. **Repositories Setup** - Clones companion repos (bin, config, install, zsh-lib) to ~/GitHub and creates symlinks
6. **Zsh Setup** - Installs zsh, sets as default shell, links configuration
7. **Oh My Zsh Setup** - Installs Oh My Zsh framework and plugins
8. **Oh My Posh Setup** - Installs Oh My Posh prompt theme engine
9. **Basic Tools & Finalization** - Installs mc, bc, htop, sets up locales, configures bash fallback

### Environment Variables

Key directories set in install.sh:

```bash
GHDIR=$HOME/GitHub           # Repository root
GHBINDIR=$GHDIR/bin         # Executable scripts
GHLIBDIR=$GHDIR/zsh-lib     # Function library
GHCONFDIR=$GHDIR/config     # Configuration files
BINDIR=$HOME/bin            # User executables
LIBDIR=$HOME/lib            # User libraries (symlinks to zsh-lib)
CONFDIR=$HOME/.config       # User config directory
LOGDIR=$TMP/InstallShell    # Installation logs
```

XDG directories:
```bash
XDG_CONFIG_HOME=$HOME/.config
XDG_CACHE_HOME=$HOME/.cache
XDG_BIN_HOME=$HOME/.local/bin
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
```

### Bash/Zsh Compatibility

**Critical**: install.sh and install.lib.sh must work in both bash (Debian/Ubuntu default) and zsh (macOS default).

When modifying these files:
- Use POSIX-compliant syntax where possible
- Avoid zsh-specific features (array syntax with parentheses, etc.)
- Use `[[ -n "$BASH_VERSION" ]]` or `[[ -n "$ZSH_VERSION" ]]` for shell-specific code
- Test conditional read prompts work in both shells (see `prompt_continue` function)
- Use `is_installed` wrapper instead of direct `which` or `type` commands

## Helper Functions (install.lib.sh)

### Output Functions

- `load_colors()` - Initialize color variables (r, g, y, b, p, c, w, x)
- `print_title "text"` - Print title in decorated box
- `print_header "text"` - Print step header with counter (increments `step`)
- `print_commands cmd1 cmd2 ...` - Display bullet list of items to install
- `print_info "text"` - Cyan info message (ℹ)
- `print_start "text"` - White start message (★)
- `print_done "text"` - Green success message (✔)
- `print_error "text"` - Red error message (✘)
- `print_warning "text"` - Yellow warning message (⚠)
- `print_version "command" ["flag"]` - Show command version

### Execution Functions

- `run_silent "logname" command args...` - Execute command, redirect output to log file
- `install_silent "appname" command args...` - Install with logging and status messages
- `prompt_continue ["question"]` - Interactive Y/N prompt (universal bash/zsh)

### Detection Functions

- `is_installed cmd` - Check if command exists in PATH (works in bash and zsh)
- `is_debian_based()` - Checks for /etc/debian_version
- `is_debian()` - Specifically Debian (not Ubuntu)
- `is_ubuntu()` - Specifically Ubuntu
- `is_macos()` - Checks `uname == Darwin`
- `is_linux()` - Checks `uname == Linux`

### Homebrew Functions

- `brew_shellenv()` - Execute brew shellenv for correct platform:
  - macOS: `/opt/homebrew/bin/brew`
  - Linux: `/home/linuxbrew/.linuxbrew/bin/brew`

### Shell Configuration Functions

- `get_current_shell()` - Returns user's default shell path
- `is_zsh_default()` - Check if zsh is already default
- `set_zsh_default()` - Change default shell to zsh (platform-aware)
- `is_omz_installed()` - Check if Oh My Zsh is installed
- `zsh_cleanup()` - Remove old zsh config files and link .zshenv

### File Management Functions

- `lns source target` - Safe symlink creation:
  - Validates source exists
  - Converts relative paths to absolute
  - Removes existing target (file/dir/link)
  - Creates parent directories
  - Creates symlink

- `lnconf folder` - Link config folder from GHCONFDIR to CONFDIR

### Git Functions

- `git_clone "repo_name"` - Clone repository from github.com/barabasz/ with logging

### Oh My Zsh Functions

- `install_omz_plugin "plugin_name"` - Clone plugin from zsh-users org to ZSH_CUSTOM/plugins

### Locale Functions (Linux)

- `setup_locale()` - Install and configure locales (en_US.UTF-8 for messages, pl_PL.UTF-8 for regional)
- `uncomment_locale "locale"` - Uncomment locale in /etc/locale.gen
- `install_locale "locale"` - Generate locale if not present

## Important Patterns

### Loading Remote Scripts with Cache Bypass

Use random query parameter to bypass CDN/browser caching:

```bash
lib_script_url="https://raw.githubusercontent.com/barabasz/install/HEAD/install.lib.sh"
source <(curl -fsSL "${lib_script_url}?${RANDOM}") || {
    echo "Failed to load helper functions. Exiting."
    return 1
}
```

### Symbolic Link Management

Always use `lns` instead of `ln -s` directly:

```bash
lns "$GHLIBDIR" "$LIBDIR"                    # Link entire directory
lns "$GHCONFDIR/zsh/.zshenv" "$HOME/.zshenv" # Link single file
```

The function handles all edge cases (existing files, missing directories, relative paths).

### Platform-Specific Installation

Standard pattern for cross-platform package installation:

```bash
if is_macos; then
    install_silent "package" brew install package || return 1
elif is_linux; then
    install_silent "package" sudo apt install package -y || return 1
fi
```

### Error Handling

All critical operations should check exit status:

```bash
install_silent "git" sudo apt install git -y || return 1
run_silent "brew_update" brew update || return 1
```

Failed operations log to `$LOGDIR/{step}_{operation}.log`

### Interactive vs Non-Interactive

For Homebrew and other tools that may prompt:

```bash
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_EMOJI=1
export NONINTERACTIVE=1
```

### Terminfo Handling

On Linux systems, check for kitty terminfo and fall back to xterm-256color if unavailable:

```bash
check_terminfo  # Called early in install.sh
```

## Companion Repositories

The script expects these repositories to be cloned to ~/GitHub:

- **bin** - Executable scripts (symlinked to ~/bin subdirectories)
- **config** - Configuration files for zsh, bash, git, nvim, mc, gh, omp (symlinked to ~/.config)
- **install** - This repository (symlinked to ~/bin/install)
- **zsh-lib** - Zsh function library (symlinked to ~/lib)

Symlink structure created in install.sh step 5 (lines 247-268).

## Testing

Run the bootstrap script:
```bash
source install.sh
```

Check installation logs:
```bash
ls -la ~/.tmp/InstallShell/
```

Verify symlinks:
```bash
ls -la ~/bin
ls -la ~/lib
ls -la ~/.config
```
