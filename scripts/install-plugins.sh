#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
apply=false
extras=false
update=false
usage() { printf 'Usage: %s [--apply | --dry-run] [--extras] [--update]\nInstall Oh My Zsh, Powerlevel10k and selected plugins. Existing directories are preserved.\n--update fast-forwards clean Git checkouts with the expected remote.\n' "$0"; }
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        --extras) extras=true ;;
        --update) update=true ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
zsh_dir=${ZSH:-$HOME/.oh-my-zsh}
custom_dir=${ZSH_CUSTOM:-$zsh_dir/custom}
normalize_remote() {
    local value=${1%.git}
    printf '%s\n' "${value/git@github.com:/https://github.com/}"
}
install_repo() {
    local url=$1 dest=$2 remote
    if [[ -e $dest || -L $dest ]]; then
        if ! $update; then
            printf 'Keep existing: %s\n' "$dest"
            return
        fi
        [[ -d $dest/.git ]] || { printf 'Skip non-Git directory: %s\n' "$dest"; return; }
        remote=$(git -C "$dest" remote get-url origin)
        if [[ $(normalize_remote "$remote") != "$(normalize_remote "$url")" ]]; then
            printf 'Skip different origin: %s\n' "$dest"
            return
        fi
        if [[ -n $(GIT_OPTIONAL_LOCKS=0 git -C "$dest" status --porcelain) ]]; then
            printf 'Skip local changes: %s\n' "$dest"
            return
        fi
        printf 'Fast-forward: %s\n' "$dest"
        if $apply; then git -C "$dest" pull --ff-only; fi
    else
        printf 'Clone: %s -> %s\n' "$url" "$dest"
        if $apply; then
            mkdir -p -- "$(dirname -- "$dest")"
            git clone --depth=1 --recurse-submodules -- "$url" "$dest"
        fi
    fi
}
if $apply || $update; then
    command -v git >/dev/null || { printf 'Install git first.\n' >&2; exit 1; }
fi
# Cloning the framework avoids an upstream installer changing .zshrc or chsh.
install_repo https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir"
while IFS='|' read -r profile relative url; do
    [[ -z $profile || $profile == \#* ]] && continue
    [[ $profile == core ]] || $extras || continue
    install_repo "$url" "$custom_dir/$relative"
    # Older manual ssh-connect clones may exist without their listbox submodule.
    # Fill that missing dependency only for the expected, unmodified repository.
    if [[ $relative == plugins/ssh-connect && ! -r $custom_dir/$relative/listbox/listbox.sh ]]; then
        printf 'Initialize missing ssh-connect submodules: %s\n' "$custom_dir/$relative"
        if $apply; then
            dest="$custom_dir/$relative"
            if [[ -d $dest/.git ]] &&
               [[ $(normalize_remote "$(git -C "$dest" remote get-url origin)") == "$(normalize_remote "$url")" ]] &&
               git -C "$dest" diff --quiet HEAD -- .gitmodules; then
                git -C "$dest" submodule update --init --recursive
            else
                printf 'Skip submodule repair in a custom or modified checkout: %s\n' "$dest"
            fi
        fi
    fi
done < "$repo_dir/manifests/plugins.txt"
if ! $apply; then printf '\nPreview only. Add --apply to run the listed operations.\n'; fi
