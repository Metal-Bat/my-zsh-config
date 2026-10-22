#!/usr/bin/env bash
# Internal step of ../install.sh. Upstream installers never edit shell files.
set -euo pipefail
apply=false
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        -h|--help) printf 'Usage: scripts/install-runtimes.sh [--apply | --dry-run]\nInstall missing mise/Rust tooling and the global usage helper.\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
: "${HOME:?Set HOME to the account receiving the installation}"
cargo_dir=${CARGO_HOME:-$HOME/.cargo}
export PATH="$HOME/.local/bin:$cargo_dir/bin:$PATH"
printf 'Keep working mise/Rust installations; install missing tools for %s.\n' "$HOME"
printf 'mise: official standalone installer -> %s/.local/bin/mise\n' "$HOME"
printf 'Rust: official rustup minimal stable profile -> %s\n' "$cargo_dir"
printf 'Install usage from the deployed global mise config; add no language runtimes to mise.\n'
$apply || exit 0
((EUID != 0)) || { printf 'Run this step as your normal user, without sudo.\n' >&2; exit 1; }
for cmd in curl sh; do command -v "$cmd" >/dev/null || { printf 'Missing prerequisite: %s\n' "$cmd" >&2; exit 1; }; done
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
fetch() { curl --proto '=https' --tlsv1.2 --fail --location --retry 3 "$1" --output "$2"; }

mise_bin=$(type -P mise || true)
if [[ -n $mise_bin ]] && "$mise_bin" --version >/dev/null 2>&1; then
    printf 'Keep mise: %s\n' "$mise_bin"
else
    # Do not overwrite an existing broken/custom file without preserving it.
    if [[ -e $HOME/.local/bin/mise || -L $HOME/.local/bin/mise ]]; then
        printf 'Existing mise executable does not run: %s/.local/bin/mise\nRepair it before rerunning setup.\n' "$HOME" >&2
        exit 1
    fi
    fetch https://mise.run "$work/mise-install.sh"
    MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh "$work/mise-install.sh"
    mise_bin="$HOME/.local/bin/mise"
    "$mise_bin" --version
fi

rustup_bin=$(type -P rustup || true)
if [[ -z $rustup_bin ]] && command -v cargo >/dev/null && command -v rustc >/dev/null &&
   cargo --version >/dev/null 2>&1 && rustc --version >/dev/null 2>&1; then
    printf 'Keep working system Rust/Cargo; no second Rust manager is installed.\n'
else
    if [[ -z $rustup_bin ]]; then
        fetch https://sh.rustup.rs "$work/rustup-init.sh"
        sh "$work/rustup-init.sh" -y --no-modify-path --profile minimal --default-toolchain stable
        rustup_bin="$cargo_dir/bin/rustup"
    fi
    (
        cd -- "$HOME"
        if ! "$rustup_bin" show active-toolchain >/dev/null 2>&1; then
            "$rustup_bin" default stable
        fi
        # These components support Rust editing and diagnostics. Existing
        # components/toolchains are retained; no rustup update is performed.
        "$rustup_bin" component add rust-src rustfmt clippy rust-analyzer
        cargo --version
        rustc --version
    )
fi

config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
[[ -r $config_dir/mise/config.toml ]] || {
    printf 'Deploy config/mise/config.toml first; the main installer does this automatically.\n' >&2
    exit 1
}
(
    cd -- "$HOME"
    "$mise_bin" install usage
    usage_bin=$("$mise_bin" which usage)
    "$usage_bin" --version
)
