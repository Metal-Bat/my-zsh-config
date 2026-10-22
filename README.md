# My Debian KDE development terminal

A documented Zsh, Kitty and Neovim setup for a Debian development workstation.
Built around **Oh My Zsh + Powerlevel10k**, **Atuin**, **zoxide**, **fzf**,
**navi**, and **mise with project-specific runtimes**.

The goal is a terminal you can understand, reproduce and maintain. Each package
has an installation owner, each integration has one job, and optional tools can
be added gradually. The owner's workflow covers **Java, TypeScript, JavaScript,
Python, Go and Rust**.

## What you get

| Component | What it does | Configuration / guide |
| --- | --- | --- |
| Zsh + Oh My Zsh | Completion, useful aliases, suggestions and one syntax highlighter | [`.zshrc`](.zshrc) · [Shell guide](docs/shell.md) |
| Powerlevel10k | Interactive prompt and locally generated prompt settings | [Shell guide](docs/shell.md) |
| Atuin | Searchable shell history on **Ctrl-R** | [Tool guide](docs/tools.md) |
| zoxide | Jump to frequently visited directories with `z` and `zi` | [Shell guide](docs/shell.md) |
| fzf + navi | Fuzzy file selection and searchable command recipes | [Tool guide](docs/tools.md) |
| mise | Global `usage`; language runtimes chosen in individual projects; Python disabled | [Exact config](config/mise/config.toml) · [mise guide](docs/mise.md) |
| Kitty + kitten | MesloLGS NF, transparent background, rounded powerline tabs and cursor trails | [Config](config/kitty/kitty.conf) · [Kitty guide](docs/kitty.md) |
| Neovim + LazyVim | `/opt/nvim-linux-x86_64` installation and an explained starter setup | [Neovim guide](docs/neovim.md) |
| Developer utilities | APT package lists and the complete 27-package Cargo inventory | [Tool catalog](docs/tools.md) · [Manifests](manifests/) |

**Target:** Debian with KDE Plasma, primarily Linux x86_64. The package lists
reflect the owner's Debian Sid environment; availability varies by release.
The scripts check local APT candidates instead of adding another distribution's
repositories. A working Debian installation is assumed; optional desktop and
container setup is in [the installation guide](docs/installation.md).

## Start here

- **New installation:** follow the numbered steps below.
- **Already using these tools:** review the configuration diff, then use step 5.
- **Want to understand a command?** Open the [tool catalog](docs/tools.md).
- **Want more developer plugins?** Read the [optional recommendations](docs/plugin-recommendations.md).
- **Something behaves differently?** Use [diagnostics and recovery](docs/maintenance.md).

All four installers **preview by default**. `--apply` runs the displayed
operation. Run them as your normal account; only the APT installer invokes
`sudo` when needed. Packages, plugins and configuration copies are separate
steps so you can see exactly what changes.

### 1. Get the repository

```bash
sudo apt update
sudo apt install git curl ca-certificates
mkdir -p "$HOME/src"
git clone https://github.com/Metal-Bat/my-zsh-config.git "$HOME/src/my-zsh-config"
cd "$HOME/src/my-zsh-config"
```

For an existing checkout, use that checkout instead of cloning over it. When
reviewing an unmerged pull request, check out its branch first.

### 2. Install the Debian packages

```bash
./scripts/install-apt.sh
./scripts/install-apt.sh --apply
```

The [core list](manifests/apt-core.txt) includes Zsh, Kitty, zoxide, fzf, lsd,
bat, ripgrep, build dependencies, **Sherlock and yt-dlp from APT**, and FFmpeg
for downloader post-processing. It does not install Python applications through
pyenv, pip or Cargo.

Optional workstation tools include Go, HTTPie, tmux, Ansible, kubectx and the
fortune/cowsay utilities:

```bash
./scripts/install-apt.sh --extras
./scripts/install-apt.sh --extras --apply
```

If a package has no candidate, the script reports all missing packages and
stops before the install transaction. See [release differences](docs/installation.md#debian-package-availability).

### 3. Install Oh My Zsh and the shell plugins

```bash
./scripts/install-plugins.sh
./scripts/install-plugins.sh --apply
```

This installs Oh My Zsh, Powerlevel10k, autosuggestions, history substring
search, alias hints, terminal color support and fast syntax highlighting.
It also installs the original `zpm-zsh/colorize` command-coloring plugin with
its required `zpm-zsh/colors` dependency; the shell loads that dependency first.
Existing directories are kept. It does not replace `.zshrc` or change your
login shell.

For the additional Docker, Git Flow and SSH helpers from the owner's setup:

```bash
./scripts/install-plugins.sh --extras --apply
```

The [plugin manifest](manifests/plugins.txt) gives every repository its correct
installation directory; names such as `zsh-you-should-use` must be installed as
`you-should-use` for the selected OMZ plugin name to match.

### 4. Install mise, Rust and the desired Cargo tools

Skip installers for tools already present. These are the official standalone
bootstrap commands; their upstream behavior is described in the
[mise guide](docs/mise.md) and [installation guide](docs/installation.md).

```bash
curl -fsSL https://mise.run | sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path
```

The supplied Zsh config adds the relevant executable directories. The Cargo
installer also finds a new Rust installation before you restart the shell:

```bash
./scripts/install-cargo.sh
./scripts/install-cargo.sh --apply
```

The default Cargo selection is `atuin`, `navi`, `tlrc` (the `tldr` command) and
`tree-sitter-cli`. To include the standalone development utilities:

```bash
./scripts/install-cargo.sh --all
./scripts/install-cargo.sh --all --apply
```

Use `--snapshot` to request the versions you see in the
[recorded inventory](manifests/cargo-tools.txt). Without it, the script requests
current releases. RTK is installed from `rtk-ai/rtk`, with the exact recorded
commit used in snapshot mode. `--legacy` separately opts into `exa` and the
recorded Cargo `btop` crate; read their [notes](docs/tools.md#overlapping-and-older-tools)
first. Nothing removes your currently installed tools.

### 5. Install the three configuration files

Review the preview and, on an existing machine, compare your local config first:

```bash
diff -u "$HOME/.zshrc" .zshrc
./install.sh
./install.sh --apply
```

`diff` returns status 1 when files differ; that is normal. On a new account,
skip it if `.zshrc` does not exist.

| Repository file | Default destination |
| --- | --- |
| `.zshrc` | `~/.zshrc` (or `$ZDOTDIR/.zshrc`) |
| `config/mise/config.toml` | `~/.config/mise/config.toml` |
| `config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |

`XDG_CONFIG_HOME` and `XDG_STATE_HOME` are respected. Changed files and existing
symlinks are moved into a timestamped backup with a destination map under
`~/.local/state/my-zsh-config/backups/`. Identical regular files are skipped.
Each replacement is prepared before it is moved into place; this is not a
single transaction across all three files. Recovery is documented
[in the maintenance guide](docs/maintenance.md#restore-a-configuration-backup).

**Copies are intentional.** Kitty's theme/font tools can edit its local config,
and local edits should not unexpectedly modify your Git checkout. To deploy
only one component, use `./install.sh --only zsh --apply` (also `mise` or `kitty`).

Your existing `~/.p10k.zsh`, Kitty `current-theme.conf`, private overrides and
Neovim configuration are preserved. Add personal shell settings using
[the local override example](config/zsh/local.zsh.example).

### 6. Finish the first-run setup

Open a new Zsh session:

```bash
exec zsh
```

Then run these in the new shell:

```zsh
cd "$HOME"
mise install usage
mise ls --current
p10k configure
"$HOME/src/my-zsh-config/scripts/doctor.sh"
```

Install MesloLGS NF and choose a Kitty theme using the [Kitty guide](docs/kitty.md).
Install or verify Neovim and LazyVim using the [Neovim guide](docs/neovim.md).
The original Kitty color file and the owner's personal LazyVim files were not
part of this snapshot, so those guides explain how to choose a theme and set
up the upstream starter.

To make Zsh your login shell, once you are happy with it:

```bash
chsh -s "$(command -v zsh)"
```

Log out and back in. `exec zsh` changes the current terminal immediately; `chsh`
changes the login default.

### 7. Try the daily workflow

| Need | Try |
| --- | --- |
| Find an earlier command | **Ctrl-R** for Atuin |
| Jump to a familiar project | `z project-name`; `zi` for interactive selection |
| Find a file | **Ctrl-T**; `rg 'pattern' .`; `fdfind filename` |
| Find a command recipe | **Ctrl-Space** or **Ctrl-G** for navi |
| Inspect files | `l`; `bat filename`; `tre .` |
| Check disk or processes | `dust .`; `dua i`; `btm` |
| Inspect CSV | `csvlens data.csv`; `xsv headers data.csv` |
| Read concise command examples | `tldr tar` |
| Open the editor | `nvim`; then `:LazyExtras` for curated features |
| Choose a project runtime | Follow the [explicit project setup](docs/mise.md#3-choose-a-project-deliberately) |
| Inspect the environment | `type -a python3 node go`; `mise ls --current` |

Tools in the full Cargo selection will be unavailable until you install them.
See the catalog for what each command changes and which package provides it.

## How this differs from the earlier configuration

- pyenv initialization and absolute aliases into old pyenv environments are removed.
- mise is activated once; the OMZ `mise` plugin is not also loaded.
- Global mise manages only `usage`; `disable_tools = ["python"]` is retained.
- Cargo/local executable directories are ready before tool integrations run.
- `/opt/nvim-linux-x86_64/bin` takes priority when that Neovim exists.
- Atuin owns Ctrl-R, zoxide owns `z`, and one highlighter loads after the widgets.
- Missing optional tools and plugin files are guarded so a partial install can start.
- Sherlock and yt-dlp use normal APT executables; `yd` is a convenience alias for `yt-dlp`.
- Personal application launchers and machine-specific shell code belong in local overrides.
- Plugins update explicitly; shell startup does not run package installation scripts.

## Repository map

| Location | Role |
| --- | --- |
| `.zshrc` | Commented shell configuration, kept in one readable file |
| `config/` | mise, Kitty and private-override examples |
| `manifests/` | Explicit APT, Cargo and third-party plugin inventories |
| `scripts/` | Package/plugin installers and read-only diagnostics |
| `install.sh` | Preview, back up and copy the three configs |
| `docs/` | Detailed setup, usage, recommendations and recovery |
| `tests/smoke.sh` | Isolated startup and installer regression checks |
| `.github/workflows/check.yml` | Runs the checks for pushes and pull requests |

## Keep it healthy

```bash
git pull --ff-only
./install.sh
./scripts/doctor.sh
bash tests/smoke.sh
```

After inspecting a changed config, apply the selected component. Package updates
remain with the package manager that installed each tool. Read
[maintenance](docs/maintenance.md) before using a broad updater such as Topgrade.

This is a tested configuration baseline, not a claim that every terminal,
distribution package version or optional plugin combination behaves identically.
The checks cover the repository's shell and installer behavior; an actual KDE
session is still needed to assess fonts, transparency and interactive UI.
