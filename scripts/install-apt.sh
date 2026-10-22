#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
apply=false
yes=false
usage() { printf 'Usage: %s [--apply | --dry-run] [--yes]\nInstall the complete Debian package manifest. Preview by default.\n' "$0"; }
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        --yes) yes=true ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
files=("$repo_dir/manifests/apt-packages.txt")
packages=()
for file in "${files[@]}"; do
    while IFS= read -r pkg || [[ -n $pkg ]]; do
        [[ -z $pkg || $pkg == \#* ]] && continue
        [[ $pkg =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || { printf 'Invalid package in %s: %s\n' "$file" "$pkg" >&2; exit 1; }
        packages+=("$pkg")
    done < "$file"
done
printf 'Packages (%s):\n' "${#packages[@]}"
printf '  %s\n' "${packages[@]}"
if ! $apply; then
    printf '\nPreview only. --apply runs apt-get update, checks candidates, then apt-get install.\n'
    exit 0
fi
command -v apt-get >/dev/null || { printf 'This installer requires a Debian-family APT system.\n' >&2; exit 1; }
sudo_cmd=()
if ((EUID != 0)); then
    command -v sudo >/dev/null || { printf 'Install sudo or ask your administrator to install the listed packages.\n' >&2; exit 1; }
    sudo_cmd=(sudo)
    [[ ${MYZSH_NONINTERACTIVE:-0} != 1 ]] || sudo_cmd+=(-n)
fi
"${sudo_cmd[@]}" apt-get update
missing=()
for pkg in "${packages[@]}"; do
    candidate=$(LC_ALL=C apt-cache policy "$pkg" | awk '/Candidate:/ {print $2; exit}')
    [[ -n $candidate && $candidate != '(none)' ]] || missing+=("$pkg")
done
if ((${#missing[@]})); then
    printf '\nNo APT candidate in your configured repositories:\n' >&2
    printf '  %s\n' "${missing[@]}" >&2
    printf 'No packages were installed. Check your Debian release and docs/installation.md.\n' >&2
    exit 1
fi
# No distribution upgrade or removals. Existing conffiles stay in place.
# The top-level installer supplies --yes after its visible sudo prompt.
args=(install --no-remove --no-upgrade -o Dpkg::Use-Pty=0)
if $yes; then
    args+=(-y -o Dpkg::Options::=--force-confold)
    "${sudo_cmd[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get "${args[@]}" "${packages[@]}"
else
    "${sudo_cmd[@]}" apt-get "${args[@]}" "${packages[@]}"
fi
