# What the installer does

[Back to the README](../README.md)

The normal installation is **`./install.sh`** from the repository checkout.
It applies the complete personal setup. The scripts and manifests are split
into readable parts so you can inspect, debug, and maintain that one workflow.

## Before running it

Use an existing **Debian 13 or Sid workstation on Linux x86_64**, with a working
network, Git, and a normal user account allowed to run `sudo`. The top-level
installer checks that target before applying the setup. Package names follow
the owner's Debian Sid environment and are also available in Debian 13.

Run the installer as your normal account, without prefixing it with `sudo`.
It uses `sudo` for package installation and system changes, while user tools,
Git checkouts, fonts, and dotfiles stay with your account.

```bash
git clone https://github.com/Metal-Bat/my-zsh-config.git
cd my-zsh-config
./install.sh
```

If Git is not yet installed, install it through your existing Debian package
sources first. There is no desktop replacement step: your existing KDE or
other desktop remains the host for this terminal setup.

## The complete stack

| Part | Installer responsibility | Installation owner afterward |
|---|---|---|
| Debian programs | Install the complete [APT manifest](../manifests/apt-packages.txt) | APT |
| Rust and Cargo | Bootstrap the toolchain when missing | rustup for its toolchain |
| Cargo applications | Install missing entries from the complete 27-crate inventory | Cargo / cargo-update |
| mise | Prepare the mise executable and global `usage` tool | Standalone mise and its supplied self-update setting |
| Development CLIs | Prepare kubectl, Helm, and the Google Repo launcher when needed | The source used by [the development-tool helper](../scripts/install-dev-tools.sh) |
| Shell framework | Install Oh My Zsh, Powerlevel10k, and the external plugin collection | Managed Git checkouts |
| Fonts | Install the four MesloLGS NF font faces for your user | Font files / the font helper |
| Neovim | Prepare the upstream archive under `/opt/nvim-linux-x86_64` | Neovim release archive |
| LazyVim | Bootstrap a new editor setup when one is absent; preserve existing configuration | lazy.nvim / LazyVim |
| Shared configs | Copy Zsh, mise, and Kitty settings, backing up replaced destinations | This repository |
| Login shell | Set your account's login shell to Zsh | The system account database |
| Docker | Configure the Debian Docker service and your Docker group membership | APT / systemd / system account groups |

The stage order is visible directly in [`install.sh`](../install.sh).
The default workflow includes the full recorded collection.

## Progress, logs, and reruns

The main script displays a progress bar for completed stages, a live activity
indicator, and the current operation. It saves detailed output
under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config/install-logs/TIMESTAMP-PID/
```

Cargo compilation can make a stage take much longer than a package download.
A failure is reported with the relevant log. Read that error before retrying;
for example, an unavailable APT package and a crate compilation error need
different fixes. See [maintenance](maintenance.md) for the recovery workflow.

The installer can be run again after fixing a problem. Existing Cargo tools
and personal configuration are handled according to the component rules below;
this is not a transaction that rolls back every already completed package or
service operation if a later step fails.

For diagnostics, `./install.sh --dry-run` shows the planned work without
applying it. This is a diagnostic interface; the ordinary installation command
remains `./install.sh`.

## Debian package ownership

The complete list is [manifests/apt-packages.txt](../manifests/apt-packages.txt).
It includes the shell, terminal, language/build dependencies, container tools,
and the recorded workstation utilities. Exact package names keep the install
reviewable: there are no wildcard package names and no automatic APT repository
changes.

The installer checks the local package candidates. If a package is unavailable,
inspect the release and sources you already use:

```bash
cat /etc/os-release
apt-cache policy sherlock yt-dlp kitty
```

A package present in Sid may be absent from an older release. Resolve that
specific difference in your own manifest or distribution setup; the installer
does not pull in another distribution's repositories to bypass it.

The Fuck is supplied by Debian's `thefuck` package. The Google **Repo** launcher
uses its verified upstream download when missing, because Debian places its
`repo` package in `contrib`, which is not enabled on every installation.
This keeps the setup independent of an APT source change. See
[Debian's package listing](https://packages.debian.org/trixie/repo) and
[Android's Repo installation instructions](https://source.android.com/docs/setup/start/requirements#install-repo).

### Sherlock and yt-dlp come from APT

The packages are **`sherlock`**, **`yt-dlp`**, and **`ffmpeg`**. There is no pyenv
installation, Python-application bootstrap, or alias into a deleted pyenv
environment. The supplied config uses `yt-dlp`; it does not silently redefine
`youtube-dl`.

```zsh
sherlock --help
yt-dlp --version
```

[`python3-sherlock`](https://packages.debian.org/sid/python3-sherlock) is a
different Python library. The intended packages are
[Debian Sherlock](https://packages.debian.org/sid/sherlock) and
[Debian yt-dlp](https://packages.debian.org/sid/yt-dlp).

### Debian command names

| Package | Command to recognize |
|---|---|
| `bat` | Usually `batcat`; the shell adds `bat` as an alias when appropriate |
| `fd-find` | `fdfind`; the final setup step adds `~/.local/bin/fd` when `fd` is absent |
| `kitty` | Both `kitty` and `kitten` |
| `golang-go` | `go` |
| `fortune-mod` | `fortune`, commonly under `/usr/games` |

A Zsh alias is a shell convenience, not a new executable for another program.
Use `type -a COMMAND` to see what the shell resolves.

### Upstream development CLIs

[`install-dev-tools.sh`](../scripts/install-dev-tools.sh) prepares missing
`kubectl`, `helm`, and `repo` commands under `~/.local/bin`. Existing working
commands are preserved. Kubernetes and Helm use their official release
downloads; the Repo launcher is checked against its detached signature with
the signing key documented by Android, in a temporary keyring.

These commands do not create a cluster, install charts, or check out Android
source. They supply the CLIs used by the shell plugins. Your Kubernetes context
and project manifests remain personal. Upstream references:
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/),
[Helm](https://helm.sh/docs/intro/install/), and
[Repo](https://source.android.com/docs/setup/start/requirements#install-repo).

## Cargo: all 27 tools, without forced downgrades

The [Cargo manifest](../manifests/cargo-tools.txt) preserves every crate from
the owner's `cargo install --list` output, including `exa`, Cargo `btop`, `xsv`,
and the Git-sourced RTK entry. The [catalog](tools.md#complete-cargo-inventory)
explains each executable.

The main installer keeps already installed Cargo crates and installs missing
ones from current releases. Recorded versions describe the observed setup;
they are not the default version constraints. This avoids replacing a working
local version solely to match an old inventory. The component helper has
additional diagnostic/reproduction options, described by its `--help`.

Crates are installed as the normal user. Common native build dependencies come
from APT. If a crate needs another library or a newer compiler, its log contains
the specific build failure. All entries remain part of the requested install;
a failure is reported rather than silently removing that tool from the list.

`--locked` uses a package's dependency lockfile where one is published. It does
not pin the package's own version or make the whole workstation identical at
the byte level. [Cargo documents that distinction.](https://doc.rust-lang.org/cargo/commands/cargo-install.html)

RTK is installed from [rtk-ai/rtk](https://github.com/rtk-ai/rtk), using its
`master` branch for a missing installation in the normal flow. The observed
1.0.1 version came from commit
[`4ef8730cf3a0dea11c8d64a9b90bc0616fe52100`](https://github.com/rtk-ai/rtk/commit/4ef8730cf3a0dea11c8d64a9b90bc0616fe52100).
It is not substituted with an unrelated registry crate sharing the name.

The older or overlapping tools are intentionally retained. In particular,
Cargo's `btop` can shadow Debian's executable, and `exa` and `xsv` have archived
or unmaintained upstream histories. Their [catalog notes](tools.md#overlapping-and-older-tools)
explain the implications without changing the recorded collection.

## Oh My Zsh and the plugin collection

[`scripts/install-plugins.sh`](../scripts/install-plugins.sh) installs the
framework and every external repository in the plugin manifest. Built-in OMZ
plugins arrive with the framework. Directory names follow the actual plugin
names, which can differ from repository basenames.

Defaults are `~/.oh-my-zsh` and `~/.oh-my-zsh/custom`; consistent `ZSH` and
`ZSH_CUSTOM` overrides are supported. Existing directories are preserved. A
maintenance update uses expected-origin checks, clean-worktree checks, and
fast-forward-only pulls.

The full collection is installed while redundant integrations have explicit
loading decisions. The [shell guide](shell.md) records those decisions for
history search, zoxide, mise, Navi, highlighters, and automatic updates. That
keeps the user's tools available while avoiding multiple integrations claiming
the same command or key.

**Colorize dependency:** the original `zpm-zsh/colorize` plugin depends on
`zpm-zsh/colors`. Both are in the managed collection, and `colors` loads first.
If an older installation produced `bad math expression: illegal character: ^[`,
use the current plugin installer and Zsh configuration together; see
[colorize and its dependency](shell.md#colorize-and-its-dependency).

## Runtime and editor behavior

The supplied mise config is copied exactly: only `usage` is global; Python is
disabled in mise; shims and command-not-found auto-installs are disabled. Normal
project activation still works. The system language packages are available
outside declared project overrides. Read [mise.md](mise.md) for examples.

On a fresh setup, rustup owns the Rust toolchain used by the Cargo applications.
An existing working system Rust/Cargo installation is preserved. The Rust
bootstrap leaves startup-file management to this repository. The
[official Rust installation](https://www.rust-lang.org/tools/install) and
[rustup overrides](https://rust-lang.github.io/rustup/overrides.html) describe
how project toolchain selection works.

The [runtime](../scripts/install-runtimes.sh),
[font](../scripts/install-fonts.sh), and
[Neovim](../scripts/install-neovim.sh) helpers contain the component bootstrap
commands. The [Neovim guide](neovim.md) explains `/opt/nvim-linux-x86_64`, LazyVim, and
language features. Existing personal Neovim configuration is preserved. For a
new configuration, the installer prepares the documented starter; language
servers, formatters, and editor plugins still have their own health checks.
An existing `~/.p10k.zsh` and Kitty theme are also retained. The unseen personal
LazyVim files and theme were not supplied, so their exact contents are not
invented by the installer.

## System changes at the end

Zsh becomes the account's login shell. The installer configures Docker's
service and adds the normal account to the Docker group. **Log out and back in**
to pick up those account changes; `exec zsh` alone does not refresh supplementary
groups.

[`finish-setup.sh`](../scripts/finish-setup.sh) also prepares the upstream lean
Powerlevel10k preset when no prompt exists, creates the account's SSH directory
when needed, and supplies the `fd` compatibility link. Existing prompt settings
and SSH keys remain personal. The VSCode plugin integrates an existing `code`
command; this setup does not claim to install the VSCode desktop application.

Docker group access gives root-level control through the Docker daemon. This
is a deliberate part of the personal workstation setup. See
[Docker's post-installation documentation](https://docs.docker.com/engine/install/linux-postinstall/).
The Debian packages are used together; do not combine them with conflicting
upstream Docker engine packages without resolving that packaging choice first.

Private credentials are outside this repository: GitHub login, SSH keys,
password-store contents, Kubernetes kubeconfig, and Atuin accounts remain yours.
Installing their commands does not create those accounts or import secrets.

## Configuration destinations and backups

| Source | Default destination |
|---|---|
| `.zshrc` | `~/.zshrc`, or `$ZDOTDIR/.zshrc` |
| `config/mise/config.toml` | `${XDG_CONFIG_HOME:-~/.config}/mise/config.toml` |
| `config/kitty/kitty.conf` | `${XDG_CONFIG_HOME:-~/.config}/kitty/kitty.conf` |

The actual scripts use fully expanded `$HOME` paths. Changed files and existing
symlinks are backed up under
`${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config/backups/`; a destination map
records where each backup belongs. Identical regular files are skipped.

The deployment helper is [`scripts/install-config.sh`](../scripts/install-config.sh).
For later config-only work, preview it or apply the files explicitly:

```bash
./scripts/install-config.sh
./scripts/install-config.sh --apply
```

Use its `--only zsh`, `--only mise`, or `--only kitty` option for a targeted
repair. These are maintenance operations; first-time installation uses the
main command. [Recovery instructions](maintenance.md#restore-a-configuration-backup)
explain how to restore a previous copy.
