#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
apply=false
snapshot=false
usage() {
    cat <<'EOF'
Usage: scripts/install-cargo.sh [--apply | --dry-run] [--snapshot]

Install all 27 recorded crates, including exa, btop, and RTK from its Git repo.
Keep already installed crates with their binaries present; retry missing tools.
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
inventory=
if $apply; then inventory=$("$cargo_bin" install --list); fi
failed=()
count=0
total=$(awk -F'|' '!/^#/ && NF >= 4 {n++} END {print n+0}' "$repo_dir/manifests/cargo-tools.txt")
while IFS='|' read -r profile crate version executables; do
    [[ -z $profile || $profile == \#* ]] && continue
    case "$profile" in
        core|extra|git|legacy) ;;
        *) printf 'Unknown manifest profile: %s\n' "$profile" >&2; exit 1 ;;
    esac
    [[ $crate =~ ^[a-z0-9][a-z0-9_-]*$ && $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
        printf 'Invalid Cargo manifest row: %s\n' "$crate" >&2; exit 1;
    }
    count=$((count + 1))
    IFS=',' read -r -a bins <<< "$executables"
    installed_header=$(printf '%s\n' "$inventory" | awk -v name="$crate" '$1 == name && $2 ~ /^v/ {print; exit}')
    installed_version=${installed_header#"$crate v"}
    installed_version=${installed_version%%[ :]*}
    missing_bins=()
    blocked=false
    # Cargo's own inventory distinguishes crate names from executable names.
    # A missing executable is repaired even when Cargo still records its crate.
    installed=false
    if ! $snapshot && [[ -n $installed_header ]]; then
        installed=true
        for bin in "${bins[@]}"; do
            target="${CARGO_INSTALL_ROOT:-${CARGO_HOME:-$HOME/.cargo}}/bin/$bin"
            if [[ ! -x $target ]]; then
                installed=false
                if [[ -e $target || -L $target ]]; then
                    printf 'Existing Cargo path is not executable: %s\nRepair this path before retrying.\n' "$target" >&2
                    blocked=true
                else
                    missing_bins+=("$bin")
                fi
            fi
        done
    fi
    if $blocked; then failed+=("$crate"); continue; fi
    if $installed; then
        printf '[%s/%s] Keep installed Cargo crate: %s\n' "$count" "$total" "$crate"
        continue
    fi
    printf '[%s/%s] Installing Cargo crate: %s (%s)\n' "$count" "$total" "$crate" "$executables"
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
    elif [[ -n $installed_header ]]; then
        # Keep surviving executables at the same crate version during repair.
        args+=(--version "=$installed_version")
    fi
    # Installing only absent targets avoids Cargo treating a partially missing
    # multi-binary crate as up-to-date. Never force-replace surviving files.
    for bin in "${missing_bins[@]}"; do args+=(--bin "$bin"); done
    args+=("$crate")
    printf '%q ' "$cargo_bin" "${args[@]}"
    printf '\n'
    if $apply; then
        if ! "$cargo_bin" "${args[@]}"; then
            failed+=("$crate")
            continue
        fi
        for bin in "${bins[@]}"; do
            target="${CARGO_INSTALL_ROOT:-${CARGO_HOME:-$HOME/.cargo}}/bin/$bin"
            if [[ ! -x $target ]]; then
                printf 'Cargo returned success but an expected executable is missing: %s\n' "$target" >&2
                failed+=("$crate")
                break
            fi
        done
    fi
done < "$repo_dir/manifests/cargo-tools.txt"
if ((${#failed[@]})); then
    printf '\nFailed crates (the rest of the collection was attempted):\n' >&2
    printf '  %s\n' "${failed[@]}" >&2
    exit 1
fi
if ! $apply; then printf '\nPreview only. Add --apply to install.\n'; fi
