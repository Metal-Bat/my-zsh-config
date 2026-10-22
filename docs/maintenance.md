# Maintenance, diagnosis, and recovery

[Back to the README](../README.md)

Run commands from the repository checkout unless another path is shown. The
main installer is `./install.sh`; it applies the complete setup and can be run
again after a failed stage is fixed. Routine updates remain with the component
that owns each program.

## Update by owner

| Component | Routine update |
|---|---|
| Debian programs, Sherlock, yt-dlp, Docker, and language packages | `sudo apt update`, review changes, then `sudo apt upgrade` |
| Repository and complete setup | `git pull --ff-only`, review the changes, then `./install.sh` |
| Shared configs only | `./scripts/install-config.sh` previews; `./scripts/install-config.sh --apply` deploys with backups |
| Oh My Zsh and managed external plugins | `./scripts/install-plugins.sh --update`, then add `--apply` |
| `colors` / `colorize` dependency pair | Keep both managed checkouts and the current Zsh load order; repair instructions below |
| Standalone mise | Its configured self-update feature; `mise self-update` for a deliberate update |
| Global `usage` | `mise upgrade usage` from home |
| Project tools | Review that project's config and update within it |
| Rust toolchains | `rustup update` |
| Cargo applications | `cargo install-update -a` with the installed cargo-update utility |
| Git-sourced RTK | Deliberately reinstall/update from the intended upstream Git branch or commit |
| kubectl, Helm, and Repo | Inspect `type -a` first; maintain the existing installation through its owner, or follow the upstream release/verification process used by `install-dev-tools.sh` |
| Neovim archive | Follow the replacement/backup procedure in [neovim.md](neovim.md) |
| LazyVim and editor plugins | Review `:Lazy`; keep `lazy-lock.json` with your personal editor config |

The normal installer fills missing Cargo entries; it is not a request to
force-upgrade or downgrade every already installed crate. `cargo install-update`
is the separate application-update operation.

The historical full-auto-update plugin is included in the installed collection
but is not loaded at shell startup. Managed updates check the checkout's origin
and local modifications before fast-forwarding. If a checkout is skipped, inspect
its changes or fork deliberately; do not discard them just to make an updater
succeed.

### Topgrade

The complete tool collection includes Topgrade. Review its proposal with:

```bash
topgrade --dry-run
```

Then use `topgrade` when you want that set of updates. It can invoke many package
managers and applications, so its configuration determines what runs. It is not
started by `.zshrc`. See [upstream configuration](https://github.com/topgrade-rs/topgrade).

## An installation stage failed

Read the error and log path printed by the installer. Per-run logs live under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config/install-logs/TIMESTAMP-PID/
```

List the log files from a working shell:

```bash
rg --files "${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config/install-logs"
```

Open the relevant file with `less` or `batcat`. Resolve the specific failure,
then run `./install.sh` again. Successful earlier package/service operations
remain in place; the installer is not a whole-system rollback mechanism.

| Failure | Useful next check |
|---|---|
| APT package has no candidate | `apt-cache policy PACKAGE`; check your Debian release and existing sources |
| APT reports broken dependencies | Resolve that APT error before retrying the stack installation |
| Cargo compilation fails | Read the named crate's compiler/library error; check `rustc --version` |
| A download or clone fails | Check the URL/error and network; retry after resolving connectivity |
| A Git checkout is preserved/skipped | Inspect its origin and `git status` before choosing to update it |
| Font/editor stage fails | Read its stage log, then use the corresponding [Kitty](kitty.md) or [Neovim](neovim.md) guide |
| Docker permissions still fail after setup | Log out and back in; inspect `id` and the Docker service |

The main `./install.sh --dry-run` option is available when you want to inspect
planned work. Component helpers also expose `--help` for a targeted diagnosis.

## Read-only diagnostics

```bash
./scripts/doctor.sh
```

The doctor reports command paths, shell syntax, installed configs, plugin
locations, likely stale runtime-manager paths, Neovim selection, and font
availability. Read its status messages and exit code; it is a diagnosis tool,
not another installer.

For the live interactive shell:

```zsh
type -a python python3 node npm java go rustc cargo nvim mise
printf 'VIRTUAL_ENV=%s\n' "${VIRTUAL_ENV-}"
print -rl -- $path
mise config ls
mise ls --current
mise doctor
bindkey -M viins '^R'
bindkey -M viins '^ '
```

`python` need not exist on Debian; inspect `python3`. A missing entry in `type -a`
is diagnostic output, not evidence that every other part of the setup failed.

## Troubleshooting

| Symptom | Check and fix |
|---|---|
| Plain prompt | Check the Oh My Zsh/Powerlevel10k paths; start a fresh Zsh; use `p10k configure` |
| Old pyenv or NVM still wins | Inspect inherited PATH and startup files; remove the obsolete initialization you identify |
| PlatformIO Python wins | Find where `penv/bin` entered PATH; preserve PlatformIO's own environment; see [mise diagnosis](mise.md) |
| Runtime changes outside the selected project | Inspect `mise config ls`; check global and parent-directory declarations |
| Project runtime is missing | Run `mise install` in that project; command-not-found does not auto-install it |
| Ctrl-R opens the wrong UI | Start a new shell; check the binding in `viins`/`vicmd`; remove duplicate personal bindings |
| Ctrl-Space is intercepted | Use Navi's Ctrl-G shortcut or customize a binding in `local.zsh` |
| A plugin appears missing | Compare its manifest directory and `.plugin.zsh` filename; check the shell guide's load policy |
| `colorize` prints `bad math expression: illegal character: ^[` | Install its `zpm-zsh/colors` dependency and deploy the current Zsh config as described below |
| `tldr` opens a pager | Check whether an old `lol` alias remains in this shell; use a fresh session with the current config |
| `tt` fails with date options | The current config supplies a GNU-date implementation for Debian; inspect `type tt` and start a fresh shell |
| `bat` works in Zsh but an editor cannot execute it | Shell aliases are not binaries; configure that program for `batcat` or a deliberate executable wrapper |
| `/usr/bin/nvim` wins | Confirm `/opt/nvim-linux-x86_64/bin/nvim` exists, then inspect `type -a nvim` |
| Missing prompt/editor icons | Confirm MesloLGS NF is installed and selected in Kitty |
| Kitty colors differ from another machine | Choose a theme or provide your own `current-theme.conf`; the original palette was not supplied |
| Alias reminder messages | `you-should-use` is offering shortcuts; see [shell customization](shell.md) |
| GitHub, SSH, Kubernetes, or pass needs credentials | Supply your own account/key/config; the installer only prepares the tools |

### Repair the colorize dependency

The original custom `zpm-zsh/colorize` requires `zpm-zsh/colors` loaded first.
An older clone can exist while the dependency is missing. Repair both the
checkout collection and the shell load order:

```bash
./scripts/install-plugins.sh --apply
./scripts/install-config.sh --only zsh --apply
exec zsh
```

The manifest contains both repositories. See
[colorize and its dependency](shell.md#colorize-and-its-dependency) for the
specific load behavior. This repair is retained from the directly published
colorize fix.

Prefer a fresh terminal or `exec zsh` to repeatedly sourcing `.zshrc`: an old
session can retain functions, aliases, and widgets from a previous config.
`exec zsh` still inherits its parent environment. Log out/back in when a desktop
session injected a stale PATH, and after changing your login shell or groups.

## Restore a configuration backup

Configuration deployment prints its backup directory. By default it is below:

```text
~/.local/state/my-zsh-config/backups/TIMESTAMP-PID/
```

The directory contains the old destinations replaced in that run, named
`zsh`, `mise`, and `kitty`. `restore-map.tsv` records their original paths.
An absent component backup means that run had no previous file to preserve.
Use the directory actually printed by your installation:

```bash
backup_dir="$HOME/.local/state/my-zsh-config/backups/REPLACE-WITH-THE-PRINTED-DIRECTORY"
cat "$backup_dir/restore-map.tsv"
```

For the default Zsh destination, first preserve your current copy, then restore
the selected backup:

```bash
mv -- "$HOME/.zshrc" "$HOME/.zshrc.before-restore.$(date -u +%Y%m%dT%H%M%SZ)"
cp -a -- "$backup_dir/zsh" "$HOME/.zshrc"
exec zsh
```

Use the map's actual destination if `ZDOTDIR` or XDG locations differ. A saved
symlink should be restored as a symlink, and its target must still exist.
Restoring one component does not require restoring the others. With no previous
backup, move the newly installed config aside to return to that program's
default behavior.

Restoring dotfiles does not uninstall APT/Cargo programs, change your account
shell, remove Docker group access, or reverse service configuration. Those are
separate operations with their own system tools.

## Keep personal customization easy to preserve

| Personal content | Location |
|---|---|
| Aliases, environment, and machine paths | `~/.config/zsh/local.zsh` |
| Extra plugin selections/startup options | `~/.config/zsh/plugins.zsh` |
| Prompt design | `~/.p10k.zsh` |
| Kitty palette/local overrides | `~/.config/kitty/current-theme.conf` and `local.conf` |
| LazyVim configuration | `~/.config/nvim`, preferably versioned in your own repo |

Use your XDG equivalents where applicable. Compare direct edits to installed
shared files before a future deployment: the installer backs up changed files,
but it does not merge their contents. The local override paths keep those
personal edits independent of shared updates.

## Repository checks and practical verification

```bash
bash tests/smoke.sh
```

The regression runner uses temporary homes and controlled command doubles to
check shell loading, deployment/backups, idempotence, and installer behavior.
Its exact assertions are visible in the test file. A passing local test does
not demonstrate a completed live APT transaction, all 27 Cargo compilations,
every download, or a graphical KDE session.

On your workstation, follow installation with the doctor, `:LazyHealth` inside
Neovim, a real project build, and a quick check of Kitty fonts/shortcuts. Those
checks exercise the environment you will actually use.
