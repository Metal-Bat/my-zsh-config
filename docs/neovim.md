# Neovim in /opt, with LazyVim

[Back to the setup guide](../README.md)

This setup uses the upstream **Neovim Linux x86_64 archive** at
`/opt/nvim-linux-x86_64` and **LazyVim** for editor configuration. The shared
Zsh config gives that installation's `bin` directory priority when it exists.

Your personal LazyVim files were not part of the upload. The instructions below
install the official starter for a new user. An existing working LazyVim setup
can stay in place; installing the shell configuration does not require replacing
the editor configuration.

## 1. Check an existing installation first

```bash
command -v nvim
nvim --version
```

For this setup, `command -v nvim` should show
`/opt/nvim-linux-x86_64/bin/nvim`. If it does, and your installed version meets
LazyVim's requirements, skip to the editor configuration section.

The [current LazyVim requirements](https://www.lazyvim.org/) include Neovim
**0.11.2 or newer with LuaJIT**, Git **2.19 or newer**, a C compiler,
`tree-sitter-cli`, and `curl`. A Nerd Font supplies icons. `ripgrep`, `fd`, `fzf`,
and `lazygit` support additional navigation and Git features. Requirements can
change as the starter follows upstream updates; recheck them before an upgrade.

## 2. Install supporting programs

```bash
sudo apt update
sudo apt install git curl ca-certificates build-essential tar gzip unzip \
  ripgrep fd-find fzf
cargo install --locked tree-sitter-cli
```

The Cargo tool list already includes `tree-sitter-cli`; skip that install if it
is present and compatible. For clipboard access, Debian users can install
`wl-clipboard` on Wayland or `xclip` on X11. `lazygit` is optional; check its
availability in your Debian release before installing it.

Debian names the `fd` executable `fdfind`. If an editor plugin specifically
requires `fd`, create a user-local executable link only when `fd` is absent:

```bash
bash <<'BASH'
set -euo pipefail
if ! type -P fd >/dev/null && type -P fdfind >/dev/null; then
  mkdir -p "$HOME/.local/bin"
  if [ ! -e "$HOME/.local/bin/fd" ] && [ ! -L "$HOME/.local/bin/fd" ]; then
    ln -s "$(type -P fdfind)" "$HOME/.local/bin/fd"
  fi
fi
BASH
```

An alias such as `alias fd=fdfind` does not help programs that execute `fd`
directly. This repository adds `~/.local/bin` and Cargo's `bin` to the shell
PATH, so launch a fresh shell after installing its Zsh configuration.

## 3. Install the upstream Neovim archive

This section is for **Linux x86_64/amd64**. Check `uname -m`; ARM systems need
the corresponding upstream ARM archive and an adjusted install path.

The following block uses the latest stable release. For a repeatable version,
change `nvim_release=latest` to a specific tag from
[Neovim releases](https://github.com/neovim/neovim/releases), such as
`nvim_release=v0.12.6` (a verified release when this guide was updated).
Review the release notes before updating an installation you rely on.

Close existing Neovim sessions, then paste the complete block into Bash or
Zsh. It runs in Bash, downloads and checks the executable before changing
`/opt`, stages the replacement, and keeps an existing installation as a backup.

```bash
bash <<'BASH'
set -euo pipefail
if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
  printf '%s\n' 'This block is for Linux x86_64. Select the correct upstream archive.' >&2
  exit 1
fi

nvim_release=latest
nvim_archive=nvim-linux-x86_64.tar.gz
if [[ $nvim_release == latest ]]; then
  nvim_url="https://github.com/neovim/neovim/releases/latest/download/$nvim_archive"
else
  nvim_url="https://github.com/neovim/neovim/releases/download/$nvim_release/$nvim_archive"
fi

nvim_work=$(mktemp -d)
trap 'rm -rf -- "$nvim_work"' EXIT
curl --fail --location --retry 3 "$nvim_url" --output "$nvim_work/$nvim_archive"
tar -xzf "$nvim_work/$nvim_archive" -C "$nvim_work"
"$nvim_work/nvim-linux-x86_64/bin/nvim" --version

sudo install -d -m 0755 /opt
nvim_stage=$(sudo mktemp -d /opt/nvim-install.XXXXXXXX)
printf 'Staging replacement in %s\n' "$nvim_stage"
sudo cp -a -- "$nvim_work/nvim-linux-x86_64/." "$nvim_stage/"
sudo chown -R root:root "$nvim_stage"
sudo chmod 0755 "$nvim_stage"

nvim_target=/opt/nvim-linux-x86_64
nvim_backup=
if [[ -e $nvim_target || -L $nvim_target ]]; then
  nvim_backup="${nvim_target}.backup.$(date +%Y%m%d-%H%M%S).$$"
  sudo mv -T -- "$nvim_target" "$nvim_backup"
  printf 'Previous installation: %s\n' "$nvim_backup"
fi

if ! sudo mv -T -- "$nvim_stage" "$nvim_target"; then
  if [[ -n $nvim_backup && ! -e $nvim_target && ! -L $nvim_target ]]; then
    sudo mv -T -- "$nvim_backup" "$nvim_target"
  fi
  printf 'Installation failed. Inspect the staging directory: %s\n' "$nvim_stage" >&2
  exit 1
fi

"$nvim_target/bin/nvim" --version
BASH
```

This is an adaptation of the
[official Neovim Linux installation](https://github.com/neovim/neovim/blob/master/INSTALL.md#linux),
with staging and backups added. A failed staging operation leaves the original
installation in place; the printed `/opt/nvim-install.*` directory may need
manual cleanup after inspecting the failure. The archive is downloaded from
the official HTTPS release URL; this block does not perform a separate
checksum/signature verification.

The shell configuration already handles the PATH. Open a new Zsh terminal and
check again:

```bash
type -a nvim
nvim --version
```

If your terminal still selects `/usr/bin/nvim`, run `rehash` in Zsh and inspect
`print -l -- $path`. The `/opt/nvim-linux-x86_64/bin` entry must come before the
system directory. An explicit alias or function can also override PATH;
`type -a nvim` exposes those.

## 4. Keep your current LazyVim, or install the starter

If LazyVim already works, skip the backup and clone commands. Open `nvim` and
run `:LazyHealth` instead.

If `NVIM_APPNAME` is set, Neovim uses a different application directory. Either
adapt the paths below for that app name or run `unset NVIM_APPNAME` for the
standard `nvim` setup described here. Inside the editor,
`:echo stdpath('config')` shows the configuration directory actually in use.

For a fresh starter, first close Neovim. The following optional backup block
moves any existing config, data, state, and cache directories to timestamped
neighbors. It honors XDG directory overrides and works in Bash or Zsh.
Keep the printed backup paths if you may want to restore your previous setup.

```bash
(
  set -eu
  nvim_stamp="$(date +%Y%m%d-%H%M%S).$$"
  for nvim_dir in \
    "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" \
    "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
  do
    if [ -e "$nvim_dir" ] || [ -L "$nvim_dir" ]; then
      nvim_backup="$nvim_dir.backup.$nvim_stamp"
      if [ -e "$nvim_backup" ] || [ -L "$nvim_backup" ]; then
        printf 'Backup already exists: %s\n' "$nvim_backup" >&2
        exit 1
      fi
      mv -- "$nvim_dir" "$nvim_backup"
      printf 'Backed up to %s\n' "$nvim_backup"
    fi
  done
)
```

Now clone the starter. This separate step refuses to replace an existing path:

```bash
(
  set -eu
  nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  if [ -e "$nvim_config" ] || [ -L "$nvim_config" ]; then
    printf 'Already exists; keep it or back it up first: %s\n' "$nvim_config" >&2
    exit 1
  fi
  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
  git clone https://github.com/LazyVim/starter "$nvim_config"
) && nvim
```

Allow the first launch to download plugins. Run `:LazyHealth` afterward and
follow any relevant missing-dependency messages. These steps follow the
[official LazyVim starter workflow](https://www.lazyvim.org/installation).
The starter's Git metadata is retained here so its origin is visible. If you
turn this into your own dotfiles repository, deliberately remove or replace
that upstream Git metadata before pushing your configuration elsewhere.

## 5. Plugins, extras, and language tools

Type commands beginning with `:` **inside Neovim**, then press Enter.

| Command | Purpose |
|---|---|
| `:LazyExtras` | Browse curated language and feature bundles |
| `:Lazy` | Inspect plugins and their installation/update status |
| `:Lazy sync` | Install missing plugins, remove unused ones, and update plugins |
| `:LazyHealth` | Load LazyVim plugins and check the setup |
| `:checkhealth` | Neovim's general health report |
| `:Mason` | Browse external language servers, formatters, and debugging tools |
| `:MasonLog` | Inspect external-tool installation failures |

For “install something from the LazyVim store,” start with **`:LazyExtras`**.
Enable the relevant language or feature there, follow the on-screen prompts,
and restart when requested. For example, search for Go, Python, or TypeScript
support rather than installing unrelated plugins individually.

The responsibilities are separate:

- **LazyVim extras** configure a coherent editor feature or language setup.
- **lazy.nvim**, opened by `:Lazy`, manages Neovim plugins.
- **Mason**, opened by `:Mason`, manages external editor tools. Installing a
  program does not by itself guarantee that the editor is configured to use it.

See [LazyVim extras](https://www.lazyvim.org/extras),
[lazy.nvim commands](https://lazy.folke.io/usage), and
[Mason's documentation](https://github.com/mason-org/mason.nvim).

Some Mason tools need Node/npm, Go, Rust, or Python tooling. Install only the
runtimes your chosen tools require. When using a project-specific mise runtime,
enter that project before starting `nvim` so the editor inherits its PATH.
Python remains outside mise in this repository's supplied mise configuration.
Mason manages its own tools under Neovim's data directory and can add their bin
directory to Neovim's environment; that is separate from the terminal's global
runtime selection.

## 6. Where to customize LazyVim

These paths are relative to `~/.config/nvim`, or your XDG config equivalent:

| File or directory | Put this here |
|---|---|
| `lua/config/options.lua` | Editor options such as indentation and line numbers |
| `lua/config/keymaps.lua` | Your global keyboard shortcuts |
| `lua/config/autocmds.lua` | Commands triggered by editor events |
| `lua/plugins/*.lua` | Plugin specifications and plugin option overrides |
| `lazy-lock.json` | Plugin versions recorded by lazy.nvim |

Do not edit downloaded plugin files under `~/.local/share/nvim/lazy`: express
changes in your configuration so updates can preserve them. LazyVim
[loads these configuration files](https://www.lazyvim.org/configuration) at the
appropriate time. Read [plugin configuration](https://www.lazyvim.org/configuration/plugins)
before adding or replacing a plugin.

For your first session, `i` enters insert mode, Escape returns to normal mode,
`:w` saves, and `:q` quits. Press Space in normal mode to discover LazyVim's
leader-key menu. The [keymap reference](https://www.lazyvim.org/keymaps) lists
the current defaults.

## 7. Updates, checks, and recovery

Update the components through the manager that owns them:

| Component | Update path |
|---|---|
| Neovim under `/opt` | Repeat the archive procedure after reading release notes |
| LazyVim and Neovim plugins | `:Lazy`, or `:Lazy update` |
| Mason-installed tools | Use `:Mason`; inspect the selected tool's available actions |
| Cargo `tree-sitter-cli` | The repository's Cargo update workflow |
| APT dependencies | Your normal APT update/upgrade workflow |

After changing versions, run `:LazyHealth` and open a real project. Check that
file finding, search, syntax highlighting, language diagnostics, formatting,
and clipboard work for the languages you actually use.

For troubleshooting, start with:

```bash
type -a nvim tree-sitter rg fdfind fd
nvim --version
tree-sitter --version
```

Inside Neovim:

```vim
:LazyHealth
:checkhealth mason
:MasonLog
:echo stdpath('config')
:echo exepath('nvim')
```

If a Neovim archive update fails, keep the old `/opt/nvim-linux-x86_64.backup.*`
directory. Close the editor, move the new target aside, and move the selected
backup back to `/opt/nvim-linux-x86_64`. For a starter reset, restore the matching
config/data/state/cache backups as a set after moving the newly created
directories aside. The shell installer does not delete these editor backups.
