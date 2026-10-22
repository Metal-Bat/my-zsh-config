#!/usr/bin/env bash
# Copy only the three tracked configs. Package installation is separate.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
apply=false
only=all
usage() {
    cat <<'EOF'
Usage: scripts/install-config.sh [--apply | --dry-run] [--only zsh|mise|kitty]

Preview by default. --apply copies configs, backing up every changed destination.
Uses HOME, ZDOTDIR, XDG_CONFIG_HOME and XDG_STATE_HOME when set.
Does not install packages, change your login shell or touch your Neovim config.
EOF
}
while (($#)); do
    case "$1" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        --only)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            only=$2; shift
            case "$only" in zsh|mise|kitty) ;; *) usage >&2; exit 2 ;; esac ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

: "${HOME:?Set HOME to the account receiving the configuration}"
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}
zsh_dir=${ZDOTDIR:-$HOME}
backup_dir="$state_dir/my-zsh-config/backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"
names=(zsh mise kitty)
sources=("$repo_dir/.zshrc" "$repo_dir/config/mise/config.toml" "$repo_dir/config/kitty/kitty.conf")
targets=("$zsh_dir/.zshrc" "$config_dir/mise/config.toml" "$config_dir/kitty/kitty.conf")

# Validate the whole selected operation before touching a destination.
for i in "${!names[@]}"; do
    [[ $only == all || $only == "${names[i]}" ]] || continue
    [[ -f ${sources[i]} ]] || { printf 'Missing source: %s\n' "${sources[i]}" >&2; exit 1; }
    [[ ! -d ${targets[i]} ]] || { printf 'Refusing directory destination: %s\n' "${targets[i]}" >&2; exit 1; }
    target_identity="$(realpath -m -- "$(dirname -- "${targets[i]}")")/$(basename -- "${targets[i]}")"
    [[ $(realpath -m -- "${sources[i]}") != "$target_identity" ]] || {
        printf 'Source and destination are the same file: %s\n' "${targets[i]}" >&2; exit 1;
    }
done

for i in "${!names[@]}"; do
    [[ $only == all || $only == "${names[i]}" ]] || continue
    src=${sources[i]}; dest=${targets[i]}; name=${names[i]}
    if [[ -f $dest && ! -L $dest ]] && cmp -s -- "$src" "$dest"; then
        printf 'Unchanged: %s\n' "$dest"
        continue
    fi
    printf 'Copy: %s -> %s\n' "$src" "$dest"
    if [[ -e $dest || -L $dest ]]; then
        printf 'Backup: %s -> %s/%s\n' "$dest" "$backup_dir" "$name"
    fi
    $apply || continue
    mkdir -p -- "$(dirname -- "$dest")"
    # Prepare the new file before moving the old one, then rename into place.
    temp_file=$(mktemp "$(dirname -- "$dest")/.my-zsh-config.XXXXXX")
    trap '[[ -z ${temp_file:-} ]] || rm -f -- "$temp_file"' EXIT
    cp -- "$src" "$temp_file"
    chmod 644 -- "$temp_file"
    had_backup=false
    if [[ -e $dest || -L $dest ]]; then
        mkdir -p -- "$backup_dir"
        chmod 700 -- "$backup_dir"
        printf '%s\t%s\n' "$name" "$dest" >> "$backup_dir/restore-map.tsv"
        mv -- "$dest" "$backup_dir/$name"
        had_backup=true
    fi
    if ! mv -- "$temp_file" "$dest"; then
        $had_backup && mv -- "$backup_dir/$name" "$dest"
        printf 'Failed to install %s; restored its previous destination when present.\n' "$dest" >&2
        exit 1
    fi
    temp_file=
done

if $apply; then
    [[ ! -d $backup_dir ]] || printf '\nBackups and destination map: %s\n' "$backup_dir"
    printf '\nConfiguration installed. Open a new terminal or run: exec zsh\n'
else
    printf '\nPreview only. Re-run with --apply to make these changes.\n'
fi
