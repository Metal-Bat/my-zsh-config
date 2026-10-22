#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
apply=false
all=false
legacy=false
snapshot=false
usage() {
    cat <<'EOF'
Usage: scripts/install-cargo.sh [--apply | --dry-run] [--all] [--legacy] [--snapshot]

Default: atuin, navi, tlrc and tree-sitter-cli (the shell/editor integrations).
--all: add the other recorded tools, including RTK from its upstream Git repo.
--legacy: also include exa and the owner's btop Cargo crate; read docs/tools.md.
--snapshot: request the recorded crate versions and exact recorded RTK commit.
Without --snapshot, install current releases and RTK's master branch.
--locked uses a package's dependency lockfile; it does not pin its own version.
Preview by default. No --force and no sudo; binary collisions remain errors.
EOF
}
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        --all) all=true ;;
        --legacy) legacy=true ;;
        --snapshot) snapshot=true ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
if $apply; then
    # Honor a custom CARGO_HOME; a freshly installed rustup need not be on PATH yet.
    cargo_bin=$(command -v cargo || true)
    [[ -n $cargo_bin ]] || cargo_bin="${CARGO_HOME:-$HOME/.cargo}/bin/cargo"
    [[ -x $cargo_bin ]] || { printf 'Install Rust/Cargo first; see docs/installation.md.\n' >&2; exit 1; }
else
    cargo_bin=cargo
fi
failed=()
while IFS='|' read -r profile crate version executables; do
    [[ -z $profile || $profile == \#* ]] && continue
    case "$profile" in
        core) ;;
        extra|git) $all || continue ;;
        legacy) $legacy || continue ;;
        *) printf 'Unknown manifest profile: %s\n' "$profile" >&2; exit 1 ;;
    esac
    args=(install --locked)
    if [[ $profile == git ]]; then
        args+=(--git https://github.com/rtk-ai/rtk)
        if $snapshot; then
            args+=(--rev 4ef8730cf3a0dea11c8d64a9b90bc0616fe52100)
        else
            args+=(--branch master)
        fi
    elif $snapshot; then
        args+=(--version "=$version")
    fi
    args+=("$crate")
    printf '%q ' "$cargo_bin" "${args[@]}"
    printf '\n'
    if $apply; then
        if ! "$cargo_bin" "${args[@]}"; then failed+=("$crate"); fi
    fi
done < "$repo_dir/manifests/cargo-tools.txt"
if ((${#failed[@]})); then
    printf '\nFailed crates (other selected installs were attempted):\n' >&2
    printf '  %s\n' "${failed[@]}" >&2
    exit 1
fi
if ! $apply; then printf '\nPreview only. Add --apply to install.\n'; fi
