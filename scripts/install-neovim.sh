#!/usr/bin/env bash
# Official Neovim binary plus a fresh, fully bootstrapped LazyVim starter.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
apply=false
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        -h|--help) printf 'Usage: scripts/install-neovim.sh [--apply | --dry-run]\nKeep working Neovim/configs; install and bootstrap missing standard nvim setup.\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
: "${HOME:?Set HOME to the account receiving the editor configuration}"
nvim_target=/opt/nvim-linux-x86_64
nvim_bin="$nvim_target/bin/nvim"
config_root=${XDG_CONFIG_HOME:-$HOME/.config}
data_root=${XDG_DATA_HOME:-$HOME/.local/share}
state_root=${XDG_STATE_HOME:-$HOME/.local/state}
nvim_config="$config_root/nvim"
marker="$nvim_config/.my-zsh-config-bootstrap"
printf 'Keep working %s; otherwise install the verified official stable Linux x86_64 archive.\n' "$nvim_bin"
printf 'Keep existing %s; a fresh starter enables Java, TypeScript/JavaScript, Python, Go, and Rust.\n' "$nvim_config"
printf 'For a fresh starter, wait for plugin, language-server, formatter, and parser installation.\n'
$apply || exit 0
((EUID != 0)) || { printf 'Run this step as your normal user. It uses sudo only for /opt.\n' >&2; exit 1; }
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
    printf 'This setup targets Linux x86_64. No Neovim files were changed.\n' >&2; exit 1;
}
for cmd in curl python3 git sudo timeout; do command -v "$cmd" >/dev/null || { printf 'Missing prerequisite: %s\n' "$cmd" >&2; exit 1; }; done
export PATH="$nvim_target/bin:$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${GOBIN:-$HOME/.go/bin}:$PATH"
sudo_cmd=(sudo)
[[ ${MYZSH_NONINTERACTIVE:-0} != 1 ]] || sudo_cmd+=(-n)
work=$(mktemp -d)
system_stage=
user_stage=
cleanup() {
    [[ -z ${system_stage:-} ]] || "${sudo_cmd[@]}" rm -rf -- "$system_stage"
    [[ -z ${user_stage:-} ]] || rm -rf -- "$user_stage"
    rm -rf -- "$work"
}
trap cleanup EXIT
fetch() { curl --proto '=https' --tlsv1.2 --fail --location --retry 3 "$1" --output "$2"; }

if [[ -x $nvim_bin ]] && "$nvim_bin" --version >/dev/null 2>&1; then
    printf 'Keep working Neovim: %s\n' "$nvim_bin"
else
    fetch https://api.github.com/repos/neovim/neovim/releases/latest "$work/release.json"
    python3 - "$work/release.json" > "$work/asset.txt" <<'PY'
import json, re, sys
release = json.load(open(sys.argv[1], encoding="utf-8"))
tag = release.get("tag_name", "")
if release.get("draft") or release.get("prerelease") or not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
    raise SystemExit("Neovim API did not return a stable release tag")
name = "nvim-linux-x86_64.tar.gz"
matches = [a for a in release.get("assets", []) if a.get("name") == name]
if len(matches) != 1:
    raise SystemExit("Stable release is missing its Linux x86_64 archive")
asset = matches[0]
url = f"https://github.com/neovim/neovim/releases/download/{tag}/{name}"
digest = asset.get("digest", "")
if asset.get("browser_download_url") != url or not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
    raise SystemExit("Release asset URL or SHA-256 metadata is missing/invalid; refusing an unchecked install")
print(tag)
print(url)
print(digest.removeprefix("sha256:"))
PY
    mapfile -t asset < "$work/asset.txt"
    fetch "${asset[1]}" "$work/nvim.tar.gz"
    python3 - "$work/nvim.tar.gz" "${asset[2]}" "$work/extracted" <<'PY'
import hashlib, pathlib, posixpath, sys, tarfile
archive, expected, destination = sys.argv[1:]
with open(archive, "rb") as stream:
    actual = hashlib.file_digest(stream, "sha256").hexdigest()
if actual != expected:
    raise SystemExit("Neovim archive SHA-256 does not match release metadata")
prefix = "nvim-linux-x86_64"
def inside(name):
    path = pathlib.PurePosixPath(name)
    return not path.is_absolute() and ".." not in path.parts and bool(path.parts) and path.parts[0] == prefix
with tarfile.open(archive, "r:gz") as source:
    for entry in source.getmembers():
        if not inside(entry.name) or not (entry.isfile() or entry.isdir() or entry.issym() or entry.islnk()):
            raise SystemExit(f"Unsafe Neovim archive entry: {entry.name}")
        if entry.issym() or entry.islnk():
            target = entry.linkname if entry.islnk() else posixpath.join(posixpath.dirname(entry.name), entry.linkname)
            if not inside(posixpath.normpath(target)):
                raise SystemExit(f"Unsafe Neovim archive link: {entry.name}")
    if not hasattr(tarfile, "data_filter"):
        raise SystemExit("Python needs tarfile's data extraction filter; use the supported current Debian Python")
    source.extractall(destination, filter="data")
print("Verified Neovim SHA-256 and archive paths")
PY
    "$work/extracted/nvim-linux-x86_64/bin/nvim" --version
    "${sudo_cmd[@]}" install -d -m 0755 /opt
    system_stage=$("${sudo_cmd[@]}" mktemp -d /opt/.my-zsh-nvim.XXXXXXXX)
    "${sudo_cmd[@]}" cp -a -- "$work/extracted/nvim-linux-x86_64/." "$system_stage/"
    "${sudo_cmd[@]}" chown -R root:root "$system_stage"
    "${sudo_cmd[@]}" chmod 0755 "$system_stage"
    backup=
    if [[ -e $nvim_target || -L $nvim_target ]]; then
        backup="$nvim_target.backup.$(date -u +%Y%m%dT%H%M%SZ).$$"
        "${sudo_cmd[@]}" mv -T -- "$nvim_target" "$backup"
    fi
    if ! "${sudo_cmd[@]}" mv -T -- "$system_stage" "$nvim_target"; then
        [[ -z $backup ]] || "${sudo_cmd[@]}" mv -T -- "$backup" "$nvim_target"
        printf 'Neovim replacement failed; previous destination restored when present.\n' >&2
        exit 1
    fi
    system_stage=
    [[ -z $backup ]] || printf 'Previous nonworking Neovim installation: %s\n' "$backup"
    printf 'Installed Neovim %s\n' "${asset[0]}"
fi

# A marker only permits retrying a starter created by this installer. Ordinary
# existing configs (including symlinks) are never modified or run headlessly.
if [[ -e $nvim_config || -L $nvim_config ]]; then
    if [[ ! -L $nvim_config && -f $marker && $(cat "$marker") == 'my-zsh-config:pending:v1' ]]; then
        printf 'Resume incomplete LazyVim bootstrap: %s\n' "$nvim_config"
    else
        printf 'Keep existing Neovim configuration: %s\n' "$nvim_config"
        exit 0
    fi
else
    # Check before cloning: a working but old Neovim binary is preserved.
    "$nvim_bin" --headless -u NONE -i NONE -n \
        -c 'lua if vim.fn.has("nvim-0.11.2") == 0 or not jit then vim.cmd("cquit 1") else vim.cmd("qa!") end' || {
        printf 'Existing Neovim is too old for LazyVim (need >=0.11.2 with LuaJIT). It was preserved.\n' >&2; exit 1;
    }
    mkdir -p -- "$config_root"
    user_stage=$(mktemp -d "$config_root/.nvim-starter.XXXXXXXX")
    git clone --depth=1 -- https://github.com/LazyVim/starter.git "$user_stage/nvim"
    [[ -r $user_stage/nvim/init.lua && -r $user_stage/nvim/lua/config/lazy.lua ]] || {
        printf 'Downloaded LazyVim starter has an unexpected layout.\n' >&2; exit 1;
    }
    cat > "$user_stage/nvim/lazyvim.json" <<'JSON'
{
  "extras": [
    "lazyvim.plugins.extras.lang.java",
    "lazyvim.plugins.extras.lang.typescript",
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.go",
    "lazyvim.plugins.extras.lang.rust"
  ],
  "install_version": 8,
  "version": 8
}
JSON
    cat >> "$user_stage/nvim/lua/config/options.lua" <<'LUA'

-- The language servers installed by the terminal setup.
vim.g.lazyvim_ts_lsp = "vtsls"
vim.g.lazyvim_python_lsp = "pyright"
LUA
    printf 'my-zsh-config:pending:v1\n' > "$user_stage/nvim/.my-zsh-config-bootstrap"
    # Do not replace a config created concurrently while the clone was running.
    [[ ! -e $nvim_config && ! -L $nvim_config ]] || { printf 'Neovim config appeared during setup; preserving it.\n' >&2; exit 1; }
    mv -T -- "$user_stage/nvim" "$nvim_config"
    rm -rf -- "$user_stage"
    user_stage=
fi

# Bootstrap lazy.nvim explicitly so an initial clone failure cannot leave the
# upstream starter waiting for a keypress in a headless process.
lazy_dir="$data_root/nvim/lazy/lazy.nvim"
if [[ ! -e $lazy_dir && ! -L $lazy_dir ]]; then
    mkdir -p -- "$(dirname -- "$lazy_dir")"
    user_stage=$(mktemp -d "$(dirname -- "$lazy_dir")/.lazy-bootstrap.XXXXXXXX")
    # Keep remote branch metadata: stable is a tag, and a depth-1 tag clone
    # omits origin/HEAD, which lazy.nvim needs when writing its lockfile.
    git clone --filter=blob:none --branch=stable -- \
        https://github.com/folke/lazy.nvim.git "$user_stage/lazy.nvim"
    [[ ! -e $lazy_dir && ! -L $lazy_dir ]] || { printf 'lazy.nvim appeared during setup; preserving it.\n' >&2; exit 1; }
    mv -T -- "$user_stage/lazy.nvim" "$lazy_dir"
    rm -rf -- "$user_stage"
    user_stage=
fi
[[ -r $lazy_dir/lua/lazy/init.lua ]] || { printf 'Existing lazy.nvim directory is incomplete: %s\n' "$lazy_dir" >&2; exit 1; }
log_dir="$state_root/my-zsh-config/logs"
mkdir -p -- "$log_dir"
log_file="$log_dir/lazyvim-bootstrap-$(date -u +%Y%m%dT%H%M%SZ)-$$.log"
printf 'Bootstrapping editor tools; detailed log: %s\n' "$log_file"
if ! env -u VIMINIT -u EXINIT NVIM_APPNAME=nvim \
    MYZSH_BOOTSTRAP_LUA="$repo_dir/scripts/bootstrap-lazyvim.lua" \
    timeout --foreground 30m "$nvim_bin" --headless -i NONE \
    -c 'lua dofile(vim.env.MYZSH_BOOTSTRAP_LUA)' 2>&1 | tee "$log_file"; then
    printf 'LazyVim bootstrap failed or timed out. Rerun ./install.sh to resume. Log: %s\n' "$log_file" >&2
    exit 1
fi
printf 'my-zsh-config:ready:v1\n' > "$marker"
printf 'LazyVim plugins, requested language tools, and parsers are installed.\n'
