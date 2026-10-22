# Maintenance, diagnosis and recovery

Run commands from the repository checkout unless an absolute path is shown.
Keep one package manager responsible for each executable.

## Update by owner

| Component | Routine update |
| --- | --- |
| Debian packages, Sherlock and yt-dlp | `sudo apt update`, review available changes, then `sudo apt upgrade` |
| Dotfiles checkout | `git pull --ff-only`, inspect the diff, preview `./install.sh`, then apply the chosen config |
| Oh My Zsh and managed external plugins | `./scripts/install-plugins.sh --extras --update`, then add `--apply` |
| Standalone mise | Supplied self-update setting; explicit `mise self-update` also exists |
| Global `usage` | `mise upgrade usage` from home |
| Project tools | Review that project's configuration and update deliberately within it |
| Rust toolchains | `rustup update` |
| Cargo utilities | `cargo install-update -a` when `cargo-update` is installed |
| Git-sourced RTK | Re-run its explicit Git installation command to choose the intended branch or commit |
| Neovim archive | Follow the staged replacement and backup procedure in [neovim.md](neovim.md) |
| LazyVim plugins | Open `:Lazy` and review updates; keep your `lazy-lock.json` in your own config repository |

The full-auto-update OMZ plugin is not part of this setup. Updates are explicit
so you can see failures and inspect changes. This does not disable a project's
own updater if you independently configured one.

### Topgrade

Topgrade is useful for reviewing many update sources together:

```bash
topgrade --dry-run
```

Inspect the proposed commands and Topgrade's configuration before running
`topgrade`. It can invoke several package managers and external programs; it is
not run by `.zshrc`, and it is not a replacement for knowing which manager owns
a particular binary. See [upstream configuration](https://github.com/topgrade-rs/topgrade).

## Start with read-only diagnostics

```bash
./scripts/doctor.sh
```

It checks command paths, required shell syntax, installed configs, expected
plugin directories, likely stale version-manager paths, the `/opt` Neovim
selection and MesloLGS NF. Missing optional tools produce warnings. Missing
Zsh/Git or invalid repository shell syntax produce failure status. The report
does not source your personal config or run package/network operations.

For the live interactive shell:

```zsh
type -a python python3 node npm java go rustc cargo nvim mise
printf 'VIRTUAL_ENV=%s\n' "${VIRTUAL_ENV-}"
printf '%s\n' "${path[@]}"
mise config ls
mise ls --current
mise doctor
bindkey '^R'
bindkey '^ '
```

`python` need not exist on Debian; check `python3`. A missing command in `type -a`
is diagnostic output, not proof that the rest of the setup failed.

## Troubleshooting

| Symptom | Check and fix |
| --- | --- |
| Shell starts but uses a plain prompt | Confirm Oh My Zsh and Powerlevel10k paths; run the plugin installer, open a new terminal, run `p10k configure` |
| Old pyenv or NVM still wins | Inspect startup files and inherited `PATH`; remove the obsolete initialization you identify, then start a clean login session |
| PlatformIO Python wins | Inspect where `penv/bin` enters `PATH`; keep PlatformIO's own environment intact; see [mise diagnosis](mise.md#5-diagnose-the-command-that-actually-runs) |
| Runtime changes outside the intended project | Check `mise config ls` and its source paths; remove runtime declarations from a global or broad parent config |
| Correct project config, missing runtime | Run `mise install` there; typing a missing command does not auto-install it |
| Ctrl-R opens the wrong history UI | Use a new shell; `bindkey '^R'` should show Atuin when installed; remove personal duplicate history bindings |
| Ctrl-Space is intercepted | Use navi's Ctrl-G binding, or choose another binding in `local.zsh` |
| A plugin name is missing | Compare `manifests/plugins.txt`, its directory name and the `.plugin.zsh` file; install the intended plugin |
| Custom `colorize` reports `bad math expression: illegal character: ^[` | The old `zpm-zsh/colorize` install needs `zpm-zsh/colors` loaded first. Run `./scripts/install-plugins.sh --apply`, deploy the updated Zsh config with `./install.sh --only zsh --apply`, then start a fresh shell. See [colorize dependencies](shell.md#colorize-and-its-dependency). |
| `bat` works in shell but an editor cannot find it | A Zsh alias is not an executable; configure the editor to use `batcat` or provide an intentional user-local wrapper |
| `/usr/bin/nvim` wins over `/opt` | Verify `/opt/nvim-linux-x86_64/bin/nvim` exists and is executable; restart and run `type -a nvim` |
| Missing icons / square boxes | Install all MesloLGS NF faces; confirm Kitty font selection and Nerd Font compatibility |
| Kitty colors differ | The theme is local; run `kitten themes` or supply your own `current-theme.conf` |
| “Found existing alias …” messages | That is `you-should-use` giving alias hints; see the disable example in [shell.md](shell.md) |
| Cargo build fails | Read the failing crate's compiler/library requirement; update rustup or add its documented development library; the installer names failures |
| APT script says a package is unavailable | Inspect `apt-cache policy`; use packages appropriate to your Debian release |

The quickest clean comparison is a fresh terminal. Repeatedly sourcing `.zshrc`
inside the same session can leave hooks and aliases from the old config, even
when the replacement is correct. Prefer `exec zsh` after deploying it. That
still inherits the parent environment; log out/back in when diagnosing a PATH
injected by the desktop session itself.

## Restore a configuration backup

The installer prints the exact backup directory it used. Backups default to:

```text
~/.local/state/my-zsh-config/backups/TIMESTAMP-PID/
```

Inside are only the destinations replaced in that run, named `zsh`, `mise`, and
`kitty`. `restore-map.tsv` maps each backup name to its original destination.
An absent backup means there was no previous file for that component.

Inspect the directory before restoring:

```bash
backup_dir="$HOME/.local/state/my-zsh-config/backups/REPLACE-WITH-THE-PRINTED-DIRECTORY"
cat "$backup_dir/restore-map.tsv"
```

For a regular-file backup of Zsh, restore to the exact destination shown in the
map (the default is shown here):

```bash
cp -a -- "$backup_dir/zsh" "$HOME/.zshrc"
exec zsh
```

If the saved object is a symlink, preserve it as a symlink when restoring, and
ensure its original target still exists. To avoid replacing a current local
change without a copy, move the current destination to a new name first:

```bash
mv -- "$HOME/.zshrc" "$HOME/.zshrc.before-restore.$(date -u +%Y%m%dT%H%M%SZ)"
cp -a -- "$backup_dir/zsh" "$HOME/.zshrc"
```

Use the map's paths if you customized `ZDOTDIR` or XDG variables. Restoring one
component does not require restoring the others. For a first install with no
backup, move the new file aside to let the program use its defaults.

## Keep personal changes out of the shared config

- Shell aliases, environment variables and machine paths: `~/.config/zsh/local.zsh`.
- Additional OMZ plugin selections: `~/.config/zsh/plugins.zsh`.
- Prompt design: `~/.p10k.zsh`, produced by `p10k configure`.
- Kitty colors and local options: `~/.config/kitty/current-theme.conf` and `local.conf`.
- Actual LazyVim customization: your own `~/.config/nvim`, preferably versioned separately.

If you edit an installed copy directly, compare it before applying an updated
repository version; the installer backs it up, but does not merge its contents.

## Repository checks

```bash
bash tests/smoke.sh
```

The test runner uses temporary homes and isolated config paths. It exercises
startup without optional dependencies, configuration-copy safety, backups,
idempotence and representative installer failure paths. GitHub Actions runs the
same entry point. It does not install the full Cargo catalog or launch a KDE
desktop; application-level integration should be checked on the target machine.
