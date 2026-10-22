#!/usr/bin/env bash
# Read-only report: no config sourcing, installs, network calls or login changes.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
strict=false
for arg in "$@"; do
    case "$arg" in
        --strict) strict=true ;;
        -h|--help) printf 'Usage: scripts/doctor.sh [--strict]\nRead-only report; --strict requires the complete installed collection.\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
export PATH="/opt/nvim-linux-x86_64/bin:$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${GOBIN:-${GOPATH:-$HOME/.go}/bin}:/usr/games:$PATH"
failures=0
warnings=0
ok() { printf 'OK    %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }
missing() { if $strict; then fail "$*"; else warn "$*"; fi; }
check_command() {
    local name=$1 level=${2:-optional} found
    found=$(command -v "$name" || true)
    if [[ -n $found ]]; then ok "$name: $found"
    elif [[ $level == required ]]; then fail "$name is missing"
    else missing "$name is not on this process's PATH"
    fi
}

printf 'Shell and selected commands\n'
for cmd in zsh git; do check_command "$cmd" required; done
for cmd in mise atuin zoxide fzf navi cargo rustc tldr tree-sitter nvim kitty kitten sherlock yt-dlp python3 java javac go node npm tsc gh docker kubectl helm repo thefuck; do
    check_command "$cmd"
done
if command -v zsh >/dev/null; then
    if zsh -n "$repo_dir/.zshrc"; then ok 'Repository .zshrc syntax'; else fail 'Repository .zshrc syntax'; fi
fi

printf '\nConfiguration and plugins\n'
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
for file in "${ZDOTDIR:-$HOME}/.zshrc" "$config_dir/mise/config.toml" "$config_dir/kitty/kitty.conf"; do
    if [[ -r $file ]]; then ok "$file"; else missing "Missing configuration: $file"; fi
done
zsh_dir=${ZSH:-$HOME/.oh-my-zsh}
custom_dir=${ZSH_CUSTOM:-$zsh_dir/custom}
if [[ -r $zsh_dir/oh-my-zsh.sh ]]; then ok 'Oh My Zsh'; else missing 'Oh My Zsh missing; fallback prompt will be used'; fi
while IFS='|' read -r profile relative url; do
    [[ $profile == core ]] || continue
    if [[ -d $custom_dir/$relative ]]; then ok "$relative"; else missing "Missing $relative"; fi
done < "$repo_dir/manifests/plugins.txt"
if [[ -r $custom_dir/plugins/colorize/colorize.plugin.zsh && ! -r $custom_dir/plugins/colors/colors.plugin.zsh ]]; then
    missing 'Custom colorize needs zpm-zsh/colors first; run scripts/install-plugins.sh --apply. The shared config skips incomplete colorize.'
fi
if [[ -d $custom_dir/plugins/ssh-connect && ! -r $custom_dir/plugins/ssh-connect/listbox/listbox.sh ]]; then
    missing 'ssh-connect listbox submodule is missing'
fi
if [[ -d $custom_dir/plugins/gitignore && ! -r $custom_dir/plugins/gitignore/templates/Python.gitignore ]]; then
    missing 'Offline gitignore templates submodule is missing'
fi

if $strict; then
    printf '\nFull package and Cargo inventory\n'
    while IFS= read -r pkg || [[ -n $pkg ]]; do
        [[ -z $pkg || $pkg == \#* ]] && continue
        status=$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)
        if [[ $status == 'install ok installed' ]]; then ok "APT: $pkg"; else fail "APT package is missing: $pkg"; fi
    done < "$repo_dir/manifests/apt-packages.txt"
    while IFS='|' read -r profile crate version executables; do
        [[ -z $profile || $profile == \#* ]] && continue
        IFS=',' read -r -a bins <<< "$executables"
        for bin in "${bins[@]}"; do
            installed_bin="${CARGO_INSTALL_ROOT:-${CARGO_HOME:-$HOME/.cargo}}/bin/$bin"
            if [[ -x $installed_bin ]]; then ok "Cargo $crate: $bin"; else fail "Missing Cargo executable: $installed_bin"; fi
        done
    done < "$repo_dir/manifests/cargo-tools.txt"
fi

printf '\nEnvironment checks\n'
if [[ -n ${VIRTUAL_ENV:-} ]]; then warn "An active virtual environment is inherited: $VIRTUAL_ENV"; fi
case ":$PATH:" in *'/.pyenv/'*) warn 'PATH still contains pyenv; inspect old startup files' ;; esac
case ":$PATH:" in *'/.nvm/'*) warn 'PATH still contains NVM; inspect old startup files' ;; esac
case ":$PATH:" in *'/mise/shims:'*) warn 'PATH still contains mise shims; check old exports' ;; esac
case ":$PATH:" in *'/.platformio/penv/bin:'*) warn 'PlatformIO Python is on PATH; inspect its priority without deleting the environment' ;; esac
if [[ -x /opt/nvim-linux-x86_64/bin/nvim ]]; then
    if [[ $(command -v nvim || true) == /opt/nvim-linux-x86_64/bin/nvim ]]; then
        ok 'Neovim resolves to the intended /opt installation'
    else
        warn 'The /opt Neovim exists, but another nvim wins; restart Zsh and check type -a nvim'
    fi
else
    missing 'Neovim /opt archive installation is absent; see docs/neovim.md'
fi
if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
    ok 'Debian fdfind is installed; see docs/neovim.md if a plugin specifically requires fd'
fi
if command -v fc-match >/dev/null; then
    font=$(fc-match 'MesloLGS NF' --format '%{family}\n' 2>/dev/null || true)
    if [[ $font == *'MesloLGS NF'* ]]; then ok 'MesloLGS NF font found'; else missing 'MesloLGS NF not found; see docs/kitty.md'; fi
fi

printf '\n%s failure(s), %s warning(s).\n' "$failures" "$warnings"
printf 'For live mise resolution run: mise doctor && mise config ls && mise ls --current\n'
((failures == 0))
