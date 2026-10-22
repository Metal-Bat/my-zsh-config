#!/usr/bin/env bash
# Install the four MesloLGS NF faces linked by Powerlevel10k.
set -euo pipefail
apply=false
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        -h|--help) printf 'Usage: scripts/install-fonts.sh [--apply | --dry-run]\nInstall missing MesloLGS NF fonts for the current user.\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
: "${HOME:?Set HOME to the account receiving the fonts}"
font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/MesloLGS-NF"
faces=(Regular Bold Italic 'Bold Italic')
printf 'Install the four MesloLGS NF faces in %s; keep existing valid faces.\n' "$font_dir"
$apply || exit 0
((EUID != 0)) || { printf 'Install user fonts as your normal user, without sudo.\n' >&2; exit 1; }
for cmd in curl fc-scan fc-cache fc-match; do command -v "$cmd" >/dev/null || { printf 'Missing prerequisite: %s\n' "$cmd" >&2; exit 1; }; done
work=$(mktemp -d)
temp_file=
trap '[[ -z ${temp_file:-} ]] || rm -f -- "$temp_file"; rm -rf -- "$work"' EXIT
valid_font() {
    [[ -f $1 ]] && [[ $(fc-scan --format '%{family}' "$1" 2>/dev/null) == *'MesloLGS NF'* ]]
}
missing=()
for face in "${faces[@]}"; do
    filename="MesloLGS NF $face.ttf"
    if valid_font "$font_dir/$filename"; then
        printf 'Keep font: %s\n' "$font_dir/$filename"
        continue
    fi
    [[ ! -d $font_dir/$filename ]] || { printf 'Refusing font directory destination: %s\n' "$font_dir/$filename" >&2; exit 1; }
    encoded_face=${face// /%20}
    curl --proto '=https' --tlsv1.2 --fail --location --retry 3 \
        "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20${encoded_face}.ttf" \
        --output "$work/$filename"
    valid_font "$work/$filename" || { printf 'Invalid font download: %s\n' "$filename" >&2; exit 1; }
    missing+=("$filename")
done
# Validate every download before replacing any installed font.
if ((${#missing[@]})); then
    mkdir -p -- "$font_dir"
    backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config/backups/fonts-$(date -u +%Y%m%dT%H%M%SZ)-$$"
    for filename in "${missing[@]}"; do
        dest="$font_dir/$filename"
        temp_file=$(mktemp "$font_dir/.font.XXXXXX")
        install -m 0644 -- "$work/$filename" "$temp_file"
        backup=
        if [[ -e $dest || -L $dest ]]; then
            mkdir -p -- "$backup_dir"
            chmod 700 -- "$backup_dir"
            backup="$backup_dir/$filename"
            mv -- "$dest" "$backup"
            printf 'Font backup: %s\n' "$backup"
        fi
        if ! mv -- "$temp_file" "$dest"; then
            [[ -z $backup ]] || mv -- "$backup" "$dest"
            printf 'Failed to install font: %s\n' "$dest" >&2
            exit 1
        fi
        temp_file=
    done
fi
fc-cache -f "$font_dir"
fc-match --format '%{family}\n' 'MesloLGS NF'
