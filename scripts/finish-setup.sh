#!/usr/bin/env bash
# Complete the personal defaults after all installers have succeeded.
set -euo pipefail
apply=false
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        -h|--help) printf 'Usage: scripts/finish-setup.sh [--apply | --dry-run]\nSet up the prompt, SSH directory, fd shim, Zsh login shell, and Docker access.\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
: "${HOME:?Set HOME to the account receiving the setup}"
printf 'Use the upstream lean Powerlevel10k preset when no personal prompt exists.\n'
printf 'Create a private ~/.ssh directory and fd -> fdfind link only when missing.\n'
printf 'Set Zsh as the account login shell; enable Docker and add this user to its group.\n'
printf 'A new login activates the shell and Docker group membership.\n'
$apply || exit 0
((EUID != 0)) || { printf 'Run this step as your normal account.\n' >&2; exit 1; }
sudo_cmd=(sudo)
[[ ${MYZSH_NONINTERACTIVE:-0} != 1 ]] || sudo_cmd+=(-n)
zsh_dir=${ZSH:-$HOME/.oh-my-zsh}
custom_dir=${ZSH_CUSTOM:-$zsh_dir/custom}
prompt_file="${ZDOTDIR:-$HOME}/.p10k.zsh"
if [[ ! -e $prompt_file && ! -L $prompt_file ]]; then
    preset="$custom_dir/themes/powerlevel10k/config/p10k-lean.zsh"
    [[ -r $preset ]] || { printf 'Powerlevel10k lean preset missing: %s\n' "$preset" >&2; exit 1; }
    mkdir -p -- "$(dirname -- "$prompt_file")"
    # noclobber protects a prompt created while setup was in progress.
    (set -o noclobber; cat -- "$preset" > "$prompt_file")
    printf 'Created Powerlevel10k lean prompt: %s\n' "$prompt_file"
else
    printf 'Keep personal prompt: %s\n' "$prompt_file"
fi
if [[ ! -e $HOME/.ssh && ! -L $HOME/.ssh ]]; then
    (umask 077; mkdir -- "$HOME/.ssh")
fi
[[ -d $HOME/.ssh ]] || { printf '~/.ssh exists but is not a directory.\n' >&2; exit 1; }

if ! command -v fd >/dev/null; then
    fd_target=$(command -v fdfind)
    mkdir -p -- "$HOME/.local/bin"
    ln -s -- "$fd_target" "$HOME/.local/bin/fd"
    printf 'Created fd -> %s\n' "$fd_target"
fi

account=$(id -un)
zsh_bin=$(command -v zsh)
grep -Fxq -- "$zsh_bin" /etc/shells || { printf 'Zsh is absent from /etc/shells: %s\n' "$zsh_bin" >&2; exit 1; }
current_shell=$(getent passwd "$account" | cut -d: -f7)
[[ -n $current_shell ]] || { printf 'Cannot find the local account: %s\n' "$account" >&2; exit 1; }
if [[ $current_shell != "$zsh_bin" ]]; then
    "${sudo_cmd[@]}" chsh -s "$zsh_bin" "$account"
    printf 'Login shell set to %s for %s\n' "$zsh_bin" "$account"
else
    printf 'Zsh is already the login shell.\n'
fi
getent group docker >/dev/null || { printf 'Docker group is missing; check the APT stage.\n' >&2; exit 1; }
if ! id -nG "$account" | tr ' ' '\n' | grep -Fxq docker; then
    "${sudo_cmd[@]}" usermod -aG docker "$account"
    printf 'Added %s to the Docker group; log out and in to activate it.\n' "$account"
fi
if [[ -d /run/systemd/system ]]; then
    "${sudo_cmd[@]}" systemctl enable --now docker.service
    "${sudo_cmd[@]}" systemctl is-active --quiet docker.service
    printf 'Docker service is enabled and running.\n'
else
    printf 'No running systemd instance: Docker is installed; start its service with your init system.\n'
fi
