# Installation details

Start with the ordered steps in the [README](../README.md). This page explains
package ownership, optional desktop/container setup and how to reproduce the
owner's tool selection without changing unrelated system settings.

## Installation owners

| Owner | Installs and updates |
| --- | --- |
| Debian APT | Shell/terminal dependencies, Sherlock, yt-dlp, FFmpeg, lsd, bat, fzf, ripgrep, zoxide and optional desktop tools |
| Git checkouts | Oh My Zsh, Powerlevel10k and external OMZ plugins |
| Standalone mise | The mise executable; the supplied config enables its self-update feature |
| mise per project | Only runtimes explicitly declared in that project's applicable configuration |
| rustup | Rust compiler/toolchains and Cargo |
| Cargo | The terminal utilities listed in `manifests/cargo-tools.txt` |
| Neovim release archive | `/opt/nvim-linux-x86_64` |
| LazyVim / lazy.nvim | Neovim plugins and curated extras |
| Mason, when configured | Editor tools such as language servers and formatters |

A plugin named `golang`, `rust`, `npm` or `mvn` adds shell conveniences; it does
not install the corresponding runtime. Avoid installing the same executable
through several owners without a reason, because the first path wins.

## Debian package availability

The package manifests target the owner's Debian environment. A package existing
in Sid does not guarantee it exists in your stable release. The APT installer
updates package indexes, checks every selected package's candidate, and stops
before installation if one is unavailable. It never rewrites APT sources.

Inspect a missing package:

```bash
cat /etc/os-release
apt-cache policy sherlock yt-dlp kitty
```

Sherlock's package is **`sherlock`**, not `python3-sherlock` (a different Python
library). The media downloader used by this configuration is **`yt-dlp`**. The
older phrase “yt-dl” is interpreted this way because the supplied shell already
uses the yt-dlp plugin. No `youtube-dl` compatibility alias is forced.

```bash
sudo apt install sherlock yt-dlp ffmpeg
sherlock --help
yt-dlp --version
```

On a release without a candidate, install the available core packages individually
or deliberately adjust your own manifest. Stay with the repositories appropriate
to that release; do not add Sid just to satisfy this list. These are the official
Debian entries for [Sherlock](https://packages.debian.org/sid/sherlock),
[yt-dlp](https://packages.debian.org/sid/yt-dlp), and
[the unrelated python3-sherlock](https://packages.debian.org/sid/python3-sherlock).

### Debian executable names

| APT package | Executable | This repository's treatment |
| --- | --- | --- |
| `bat` | Usually `batcat` on Debian | Add shell alias `bat=batcat` only when `bat` itself is absent |
| `fd-find` | `fdfind` | Document the name; an optional `fd` symlink is explained in the Neovim guide |
| `fortune-mod` | `fortune`, often in `/usr/games` | Optional; guarded shell helper |
| `kitty` | `kitty` and `kitten` | Both come from the terminal package |
| `golang-go` | `go` | Optional normal system Go, outside project mise overrides |

Aliases affect interactive Zsh. They are not new executables for editors or
scripts. Use `command -v NAME` and `type -a NAME` when diagnosing a mismatch.

## Rust and Cargo

The standard [Rust installer](https://www.rust-lang.org/tools/install) supplies
rustup, Cargo and the compiler. `--no-modify-path` leaves startup-file changes to
this repository's config:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path
"${CARGO_HOME:-$HOME/.cargo}/bin/rustup" show
"${CARGO_HOME:-$HOME/.cargo}/bin/cargo" --version
```

Run the repository scripts as your account, without `sudo`. Core packages such
as `build-essential`, `pkg-config` and `libssl-dev` supply common build
requirements. Individual crates may need additional libraries or a newer Rust
release; their build errors identify the missing requirement.

### Choose the Cargo scope

| Command suffix | Selection |
| --- | --- |
| No selection flags | Atuin, navi, tlrc and tree-sitter-cli |
| `--all` | Core plus standalone utilities and RTK |
| `--legacy` | Also select recorded Cargo `btop` and `exa`; independent of `--all` |
| `--snapshot` | Use the owner's recorded package versions; RTK uses the verified commit |
| `--apply` | Execute the selection rather than preview it |

For example, preview the complete observed inventory:

```bash
./scripts/install-cargo.sh --all --legacy --snapshot
```

Then add `--apply` if that is the selection you want. A snapshot preserves the
observed versions; it is not evidence that all 27 crates have been rebuilt on
every current compiler. The installer reports failures while attempting the
other selected packages, and exits nonzero if anything failed.

`--locked` asks Cargo to use the crate's published dependency lockfile, when
present. It does **not** pin the selected crate version and does not make an
entire machine byte-for-byte reproducible. Source:
[Cargo install reference](https://doc.rust-lang.org/cargo/commands/cargo-install.html).

The RTK entry intentionally uses its [upstream Git repository](https://github.com/rtk-ai/rtk),
not an unrelated crate with the same name. The reported short commit `4ef8730c`
resolves to `4ef8730cf3a0dea11c8d64a9b90bc0616fe52100`, the upstream 1.0.1 release
commit. See [that commit](https://github.com/rtk-ai/rtk/commit/4ef8730cf3a0dea11c8d64a9b90bc0616fe52100).

## Oh My Zsh and plugin installation

The plugin installer clones the [Oh My Zsh framework](https://github.com/ohmyzsh/ohmyzsh)
directly. This avoids its interactive installer replacing your shell config or
changing the login shell during this step.

```bash
./scripts/install-plugins.sh --apply
```

`ZSH` and `ZSH_CUSTOM` can select nondefault locations, provided the same
variables are available in your future Zsh sessions. Defaults are
`~/.oh-my-zsh` and `~/.oh-my-zsh/custom`.

Existing directories are preserved. `--update` updates only clean checkouts
whose origin matches the manifest, using a fast-forward pull. A fork or local
modification is reported and left for you to manage:

```bash
./scripts/install-plugins.sh --extras --update
./scripts/install-plugins.sh --extras --update --apply
```

Only the listed plugins are managed. Built-in OMZ plugins arrive with Oh My
Zsh and need no extra clone. See the [shell catalog](shell.md) and
[optional recommendations](plugin-recommendations.md).

## Optional: Debian and KDE Plasma

If you already use KDE, skip this section. The terminal configuration does not
require reinstalling your desktop. On a fresh Debian installation, select KDE
Plasma in the installer, or add Debian's desktop task later:

```bash
sudo apt update
sudo apt install task-kde-desktop
```

Log into a Plasma session after installation. Read the
[Debian KDE documentation](https://wiki.debian.org/KDE) for desktop-specific
choices. Fonts, Kitty transparency and clipboard behavior are covered in the
[Kitty guide](kitty.md).

## Optional: Docker and Compose

Container tools are deliberately outside the core APT manifest: installing a
Docker engine changes system services and requires choosing an installation
source. For a Debian release with the current Debian packages available:

```bash
apt-cache policy docker.io docker-cli docker-compose
sudo apt install docker.io docker-cli docker-compose
sudo systemctl enable --now docker
sudo docker run --rm hello-world
docker compose version
```

Debian Sid's `docker-compose` package provides modern `docker compose`.
Check your release's package before assuming the same on an older Debian
installation. See [Debian docker.io](https://packages.debian.org/sid/docker.io)
and [Debian Compose](https://packages.debian.org/sid/docker-compose).

If you want Docker's upstream packages instead, follow
[Docker's Debian instructions](https://docs.docker.com/engine/install/debian/)
as a separate installation choice. Do not mix the upstream and Debian engine
packages. There is no `docker*` wildcard install, manually downloaded Compose
binary, or socket-permission change in this repository.

Optional access without `sudo`:

```bash
sudo usermod -aG docker "$USER"
```

Log out and back in. The Docker group grants root-level control of the host;
choose it only when that matches how you use the machine. This is why the
installer does not add you automatically. Source:
[Docker post-installation guide](https://docs.docker.com/engine/install/linux-postinstall/).

## Optional: Kubernetes and Helm

The OMZ `kubectl` and `helm` plugins do not install either executable. Follow
their official installation instructions for the desired release and source:

- [kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Helm installation](https://helm.sh/docs/intro/install/)
- [kubectx and kubens](https://github.com/ahmetb/kubectx)

The optional Debian package list includes `kubectx` where available. This
configuration defines `kctx` and `kns` only when their commands exist. Cluster
credentials and kubeconfig are personal and are not supplied by the repository.

## Languages and editor setup

Use [mise's project guide](mise.md) for explicit project versions and
[Neovim/LazyVim](neovim.md) for editor tools. Ordinary system Python and deliberate
virtual environments stay independent from mise. Rustup remains the owner of
the Rust toolchain used by these Cargo utilities. You can use `rust-toolchain.toml`
in a Rust project without globally replacing Rust through another manager;
see [rustup overrides](https://rust-lang.github.io/rustup/overrides.html).
