# Erfan's terminal

[![Configuration checks](https://github.com/Metal-Bat/my-zsh-config/actions/workflows/check.yml/badge.svg)](https://github.com/Metal-Bat/my-zsh-config/actions/workflows/check.yml)

**My Debian/KDE development setup, installed with one command.**

Zsh · Oh My Zsh · Powerlevel10k · Kitty · LazyVim · mise · 27 Cargo utilities

This is the terminal setup I use for **Java, TypeScript, JavaScript, Python,
Go, and Rust**. It includes the tools, shell plugins, fonts, shortcuts, editor
bootstrap, and configuration that make up that environment. The code and the
catalog explain what gets installed and how to use it.

## Install

Clone the repository, enter it, and run the installer as your normal account:

```bash
git clone https://github.com/Metal-Bat/my-zsh-config.git
cd my-zsh-config
./install.sh
```

**`./install.sh` performs the full installation.** It installs the complete
package and plugin collection, all 27 recorded Cargo tools, mise, the Rust
bootstrap when needed, Neovim/LazyVim, MesloLGS NF, and the shared configs.
It also sets Zsh as your login shell and configures the Debian Docker service
and your account's Docker group membership. Privileged steps use `sudo`;
run the script without `sudo` so user tools and dotfiles belong to your account.

The terminal shows a ten-stage progress bar, an animated activity indicator,
and the current download or build. The percentage counts completed stages;
long Cargo builds can stay on one stage for a while. Detailed output is saved in
`~/.local/state/my-zsh-config/install-logs/` (or your `XDG_STATE_HOME` equivalent).
Cargo builds and editor downloads can take a while. If a stage fails, the
installer reports it and its log; follow [diagnosis and recovery](docs/maintenance.md).

**Target:** an existing **Debian 13 or Sid workstation on Linux x86_64**, with a
working network and `sudo`. The package names reflect my Debian Sid setup.
This installs the terminal/development stack; it does not reinstall Debian or
KDE, change your APT repositories, or configure your private accounts.

After installation, **log out and back in** for the login-shell and group
changes. Open Kitty and start exploring. Docker group membership gives your
account root-level control through Docker; that access is part of this
personal workstation setup. [Docker documents that permission model here.](https://docs.docker.com/engine/install/linux-postinstall/)

## What makes the setup useful

| Part | What you get | Learn more |
|---|---|---|
| **Zsh + Oh My Zsh** | Completion, useful aliases, Vi editing, suggestions, history navigation, and syntax highlighting | [Shell guide](docs/shell.md) |
| **Powerlevel10k** | A configurable prompt with your local prompt settings preserved | [Prompt setup](docs/shell.md) |
| **Atuin** | Search commands with context on **Ctrl-R** | [History workflow](docs/tools.md#atuin-one-history-search-owner) |
| **zoxide** | Jump to familiar directories with `z` or select one with `zi` | [Navigation](docs/tools.md#zoxide-visit-once-jump-later) |
| **fzf + navi + Television** | Pick files, search command recipes, and browse fuzzy-finder channels | [Tool catalog](docs/tools.md) |
| **mise** | Project-specific runtimes; only `usage` is global; Python stays outside mise | [Exact behavior](docs/mise.md) |
| **Kitty + kitten** | MesloLGS NF, 85% opacity, rounded powerline tabs, cursor trails, image and diff helpers | [Kitty guide](docs/kitty.md) |
| **Neovim + LazyVim** | Neovim under `/opt/nvim-linux-x86_64`, with a starter for a new setup | [Editor guide](docs/neovim.md) |
| **APT tools** | Sherlock, yt-dlp, Docker, language/build dependencies, CLI utilities, and the other recorded Debian tools | [Install inventory](manifests/apt-packages.txt) |
| **Cargo tools** | All 27 tools from my recorded inventory, including the less obvious crate-to-command names | [Full catalog](docs/tools.md#complete-cargo-inventory) |

The installer keeps existing Cargo installations and installs missing crates
from their current releases. The recorded version column is a reference to my
original inventory, not a forced downgrade. RTK comes from its upstream Git
repository. [Installation details](docs/installation.md) explain ownership,
version behavior, destinations, and system changes.

## Your first ten minutes

### Find, jump, and discover

| Want to… | Try |
|---|---|
| Find a command you ran before | **Ctrl-R** |
| Search history matching what you have started typing | **Up / Down** |
| Jump to a project you have visited | `z project-name` |
| Choose a remembered directory | `zi` |
| Insert a file path | **Ctrl-T** |
| Pick a directory from the filesystem | **Alt-C** |
| Find a reusable command recipe | **Ctrl-Space** or **Ctrl-G** |
| Discover the aliases in this shell | `als`; `als docker`; `als git` |
| Read short command examples | `tldr tar`; `tldr cargo` |

The shell uses **Vi editing**: Escape enters command mode; `i` returns to
insertion. The [keybinding guide](docs/shell.md#keyboard-shortcuts) explains how
history search and the interactive pickers fit those modes.

### Explore a project

```zsh
l
tre .
tokei .
rg --line-number 'TODO|FIXME' .
bat README.md
nvim
```

`l` is the detailed `lsd` view. `tre` shows directories, `tokei` counts code,
`rg` searches text, and `bat` reads it with highlighting. In Neovim, use
**`:LazyExtras`** to explore editor features. Your existing personal LazyVim
configuration is preserved; a fresh account receives the documented starter.

### Inspect a machine or a report

```zsh
btm
dust .
dua i
csvlens report.csv
xsv headers report.csv
```

The programs are installed by the main installer. Replace example filenames
with your own. The [catalog](docs/tools.md) explains every utility, including
network inspection, JSON/HTML queries, changelogs, downloading, and maintenance.

### Use Kitty's built-in helpers

```zsh
kitten themes
kitten choose-fonts
kitten diff before.txt after.txt
kitten icat picture.png
```

The font files are installed for you. Theme and font selection are personal
customization commands. **Ctrl+Shift+T** creates a tab; **Ctrl+Shift+Enter**
creates a pane; **Ctrl+Shift+L** cycles layouts.

## Runtime behavior: system by default, projects when chosen

The global mise configuration is deliberately small:

```toml
[tools]
usage = "latest"

[settings]
not_found_system_fallback = true
disable_tools = ["python"]
activate_shims = false
not_found_auto_install = false

[settings.self_update]
auto = true
```

There are no global mise language versions. Your normal system tools remain
available outside configured projects. Declare a runtime in a project's mise
configuration when that project needs one. Python is disabled in mise; use
system Python and explicitly activated virtual environments. An inherited
virtual environment remains active until you deactivate it.

The [mise guide](docs/mise.md) explains the important limitation:
`activate_shims = false` does not disable normal project PATH activation.
It also shows how to diagnose stale pyenv, NVM, or PlatformIO paths inherited
from another startup file.

## Included plugins, with their overlaps handled

The installed collection follows my supplied plugin list, including `aliases`,
`emoji-clock`, `gh`, `gitignore`, `lol`, `pass`, `repo`, `ssh-agent`, `tmux`,
`tt`, `vi-mode`, and the older external helpers. The
[plugin manifest](manifests/plugins.txt) records the third-party repositories;
[the shell guide](docs/shell.md) explains which integrations run and why some
redundant wrappers are kept installed without being loaded.

Atuin owns Ctrl-R, zoxide owns `z`, mise is initialized once, and one syntax
highlighter runs after the widgets. The collected plugins do not all compete
for those same jobs.

The original **`zpm-zsh/colorize` needs `zpm-zsh/colors`**. Both are installed,
and the dependency loads first. This fixes the missing dependency behind the
`bad math expression: illegal character: ^[` failure. See
[colorize and its dependency](docs/shell.md#colorize-and-its-dependency).

Want to expand the setup later? [Future plugin ideas](docs/plugin-recommendations.md)
mark what is already included and explain other choices for the languages I
use. Unselected suggestions are not silently added to the installer.

## Files you may want to personalize

| File | What belongs there |
|---|---|
| `~/.config/zsh/local.zsh` | Personal aliases, environment values, and machine paths |
| `~/.config/zsh/plugins.zsh` | Additional plugin names and options needed before OMZ starts |
| `~/.p10k.zsh` | Prompt design; use `p10k configure` |
| `~/.config/kitty/current-theme.conf` | Your selected Kitty colors |
| `~/.config/kitty/local.conf` | Local Kitty overrides |
| `~/.config/nvim/` | Your actual LazyVim customization |

XDG directory overrides are respected where documented. Existing prompt,
theme, and editor configuration files are preserved. The original theme and
personal LazyVim files were not supplied with the source configs, so a fresh
installation provides a documented starting point rather than claiming to
reproduce an unseen theme or editor configuration.

The shared Zsh, mise, and Kitty configs are installed as **copies**, with
changed destinations backed up. Kitty's customization commands can then edit
its local copy without modifying your checkout. Backup locations and recovery
steps are in [maintenance](docs/maintenance.md#restore-a-configuration-backup).

## Read the setup from the code

| Location | What to inspect |
|---|---|
| [`install.sh`](install.sh) | The complete installation flow and stage ordering |
| [`manifests/apt-packages.txt`](manifests/apt-packages.txt) | Every APT package requested |
| [`manifests/cargo-tools.txt`](manifests/cargo-tools.txt) | All 27 crates, observed versions, and executable names |
| [`manifests/plugins.txt`](manifests/plugins.txt) | Third-party plugin sources and install directories |
| [`.zshrc`](.zshrc) | PATH, plugin loading, aliases, widgets, and local overrides |
| [`config/`](config/) | mise, Kitty, and customization examples |
| [`scripts/`](scripts/) | The component installers, config deployment, and doctor |
| [`docs/`](docs/) | Installation details, daily usage, maintenance, and future ideas |
| [`tests/smoke.sh`](tests/smoke.sh) | Isolated shell/installer regression checks |

The helper names follow their jobs: `install-apt.sh`, `install-runtimes.sh`,
`install-cargo.sh`, `install-dev-tools.sh`, `install-plugins.sh`,
`install-fonts.sh`, `install-neovim.sh`, and `install-config.sh` prepare the
components; `finish-setup.sh` handles the prompt preset and account/service
setup. The main installer coordinates them, so a new installation uses the
single command above.

## Maintenance

```bash
git pull --ff-only
./install.sh
./scripts/doctor.sh
```

Re-running the installer completes missing setup and deploys current shared
configs with backups. Routine software updates still belong to each tool's
package manager; see the [maintenance table](docs/maintenance.md#update-by-owner).
For a config-only maintenance operation, use
`./scripts/install-config.sh --apply`.

The repository checks exercise shell loading and installer behavior in
controlled environments. They do not establish that every Cargo build,
network download, editor plugin, and KDE graphical feature works on every
machine. Use the installer logs, the doctor, and the application health checks
on the target workstation.
