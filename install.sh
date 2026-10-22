#!/usr/bin/env bash
# Erfan's full personal setup. The public entry point applies by default.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=true ;;
        --apply) dry_run=false ;;
        -h|--help)
            cat <<'EOF'
Usage: ./install.sh [--dry-run]

Install Erfan's complete Debian 13/Sid x86_64 terminal and development setup.
Run as your normal account. One visible sudo prompt precedes the installation.
All package, Cargo, and plugin manifest entries are installed automatically.
Changed shared configs are backed up; existing personal editor configs are kept.
The progress bar counts completed stages. Detailed output is saved per stage.
--dry-run prints the complete plan without installing or writing user files.
EOF
            exit 0 ;;
        *) printf 'Unknown argument: %s\nRun ./install.sh --help.\n' "$arg" >&2; exit 2 ;;
    esac
done

stages=(
    'Debian packages|apt|install-apt.sh'
    'Zsh, mise, and Kitty configuration|config|install-config.sh'
    'mise, usage, and Rust|runtimes|install-runtimes.sh'
    'Oh My Zsh, Powerlevel10k, and every custom plugin|plugins|install-plugins.sh'
    'All 27 Cargo tools|cargo|install-cargo.sh'
    'Kubernetes, Helm, and Google Repo clients|dev-tools|install-dev-tools.sh'
    'MesloLGS Nerd Fonts|fonts|install-fonts.sh'
    'Neovim and the LazyVim development environment|neovim|install-neovim.sh'
    'Default shell, prompt, and Docker access|finish|finish-setup.sh'
    'Verify the installed collection|doctor|doctor.sh'
)

if $dry_run; then
    printf 'ERFAN / TERMINAL — complete installation plan\n\n'
    for entry in "${stages[@]}"; do
        IFS='|' read -r label log_name script <<< "$entry"
        printf '\n== %s ==\n' "$label"
        if [[ $script == doctor.sh ]]; then
            printf 'Check the full collection and installed configuration without starting a shell.\n'
        else
            bash "$repo_dir/scripts/$script" --dry-run
        fi
    done
    printf '\nPreview complete. ./install.sh applies this entire plan.\n'
    exit 0
fi

((EUID != 0)) || { printf 'Run ./install.sh as your normal account, without sudo.\nThe installer requests sudo for system changes itself.\n' >&2; exit 1; }
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { printf 'This personal setup targets Debian Linux x86_64.\n' >&2; exit 1; }
[[ -r /etc/os-release ]] || { printf 'Cannot identify this Linux distribution.\n' >&2; exit 1; }
# This file is supplied by the operating system, never downloaded by setup.
source /etc/os-release
[[ ${ID:-} == debian ]] || { printf 'This profile targets Debian 13/Sid. Detected: %s\n' "${PRETTY_NAME:-unknown}" >&2; exit 1; }
if [[ ${VERSION_ID:-} =~ ^([0-9]+) && ${BASH_REMATCH[1]} -lt 13 ]]; then
    printf 'Debian 13 or newer is required for this package and editor profile.\n' >&2; exit 1
fi
for cmd in sudo apt-get apt-cache ps flock; do
    command -v "$cmd" >/dev/null || { printf 'Missing prerequisite: %s\nInstall it with your Debian administrator account and rerun.\n' "$cmd" >&2; exit 1; }
done
: "${HOME:?Set HOME to the account receiving the installation}"
[[ -d $HOME && -w $HOME ]] || { printf 'HOME must be an existing writable directory.\n' >&2; exit 1; }

printf '\nERFAN / TERMINAL\nYour complete development terminal, installed in ten stages.\n\n'
printf 'This installs the full manifests, copies shared configs with backups,\nsets Zsh as your login shell, and enables Docker access for your account.\n\n'
sudo -v
export MYZSH_NONINTERACTIVE=1
export GIT_TERMINAL_PROMPT=0
export GOPATH=${GOPATH:-$HOME/.go}
export GOBIN=${GOBIN:-$GOPATH/bin}
export PATH="/opt/nvim-linux-x86_64/bin:$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:$GOBIN:/usr/games:$PATH"
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config
mkdir -p -- "$state_dir"
exec 9> "$state_dir/install.lock"
flock -n 9 || { printf 'Another installer is already running for this account.\n' >&2; exit 1; }
source "$repo_dir/scripts/lib/installer-ui.sh"
install_ui_init "$state_dir/install-logs/$(date -u +%Y%m%dT%H%M%SZ)-$$" "${#stages[@]}"
sudo_keeper=
cleanup() {
    local status=$?
    trap - EXIT INT TERM
    install_stop_child
    if [[ -n $sudo_keeper ]]; then
        kill "$sudo_keeper" 2>/dev/null || true
        wait "$sudo_keeper" 2>/dev/null || true
    fi
    return "$status"
}
trap cleanup EXIT
trap 'printf "\nInstallation interrupted; completed stages are kept. Rerun ./install.sh to resume.\n" >&2; exit 130' INT
trap 'exit 143' TERM
(
    keeper_sleep=
    trap '[[ -z $keeper_sleep ]] || kill "$keeper_sleep" 2>/dev/null; exit' TERM INT
    while sudo -n -v; do
        sleep 45 & keeper_sleep=$!
        wait "$keeper_sleep" || break
    done
) >/dev/null 2>&1 &
sudo_keeper=$!

for entry in "${stages[@]}"; do
    IFS='|' read -r label log_name script <<< "$entry"
    args=(--apply)
    [[ $script != install-apt.sh ]] || args+=(--yes)
    [[ $script != doctor.sh ]] || args=(--strict)
    run_stage "$label" "$log_name" bash "$repo_dir/scripts/$script" "${args[@]}"
done
awk '/^WARN / { print }' "$install_log_dir/doctor.log"
printf '\n%sSetup complete.%s Open Kitty to explore the tools.\n' "$install_green" "$install_reset"
printf 'Log out and back in once to activate the login shell and Docker group.\n'
printf 'Discover the collection: README.md and docs/tools.md\n'
printf 'Installation logs: %s\n' "$install_log_dir"
printf 'Configuration backups, when needed: %s/backups\n' "$state_dir"
