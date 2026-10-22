# Shell guide

[Back to the README](../README.md)

The shared [`.zshrc`](../.zshrc) is the entry point. It works with a partial
installation: missing commands, plugins and personal files are skipped. That lets
you install the essentials first and add the larger tool collection later.

## Startup order

| Stage | What happens | Why it is in this position |
| --- | --- | --- |
| Instant prompt | Load the existing Powerlevel10k cache when present | Display the prompt while the rest of the setup loads |
| Paths | Add local binaries, Cargo, Go, Neovim and Flatpak | Integrations can find their executables when they initialize |
| Basics | Configure history, Emacs editing and a fallback prompt | A working interactive shell does not depend on Oh My Zsh |
| Oh My Zsh | Load installed plugin candidates and the available theme | Supply completion and familiar command shortcuts |
| Command colors | Load zpm's colors dependency before its custom colorize plugin | Preserve the original command coloring without the plugin-name collision |
| Aliases | Set portable shortcuts after Oh My Zsh | Repository shortcuts have predictable final definitions |
| Integrations | Initialize fzf, zoxide, mise, Atuin and Navi once each | Keep each shortcut and hook under one integration |
| Personal setup | Load `~/.p10k.zsh` and `~/.config/zsh/local.zsh` if present | Preserve your prompt and machine-specific preferences |
| Highlighting | Load fast-syntax-highlighting last | See widgets and bindings registered earlier |

The configuration is for **interactive Zsh**. Non-interactive commands do not
normally read `.zshrc`; scripts should set their own required environment.

Without Oh My Zsh, completion initializes with `compinit -i`. Zsh still checks
completion-file ownership and directory permissions, but excludes insecure
entries without prompting. This also lets an interactive shell initialize when
its input is a pipe, as in CI. To inspect the default system completion paths:

```zsh
zsh -f -c 'autoload -Uz compaudit; compaudit'
```

If a completion is missing because its directory was excluded, review the
reported ownership and permissions before using it. The fallback does not use
`compinit -u`, which would accept insecure paths.

## Paths and programs

The shell adds the following locations. Nonexistent directories are harmless and
do not trigger downloads or installations.

| Location | Purpose |
| --- | --- |
| `~/.local/bin` | User-installed commands, including a standalone mise installation |
| `${CARGO_HOME:-~/.cargo}/bin` | Rustup and Cargo-installed tools |
| `${GOBIN:-$GOPATH/bin}` | Installed Go commands; this setup defaults `GOPATH` to `~/.go` |
| `/opt/nvim-linux-x86_64/bin` | Your Neovim installation; added at the front only when `nvim` is executable |
| `/var/lib/flatpak/exports/bin` | System Flatpak launchers |
| `~/.local/share/flatpak/exports/bin` | User Flatpak launchers |

`typeset -U path PATH` keeps the first occurrence of each directory. Existing
`GOPATH`, `GOBIN` and `CARGO_HOME` choices are respected. An inherited active
`VIRTUAL_ENV` keeps its `bin` directory first; this configuration does not
deactivate environments that you opened deliberately. Mise may add a selected
project tool directory when you enter a configured project; see [mise.md](mise.md).

The first matching executable in `PATH` wins. For example, Cargo's `btop` can
shadow `/usr/bin/btop` if you installed both. Check what will execute with:

```zsh
type -a python python3 node go cargo nvim btop mise
print -rl -- $path
```

The former implicit `~/.cargo/env` and `~/.local/bin/env` sources are replaced by
explicit path entries. No assumptions about those installer-generated files are
needed. The configuration does not initialize pyenv or NVM. It also does not
rewrite an inherited `PATH` to remove stale entries from another startup file;
the migration section in the README explains how to inspect those.

## Keyboard shortcuts

| Key | Behavior | Required component |
| --- | --- | --- |
| `Tab` | Command, path and argument completion | Zsh / Oh My Zsh |
| `Ctrl-R` | Search recorded command history in Atuin | Atuin; otherwise fzf history search when available |
| `Up` / `Down` | Search history for the text already typed | zsh-history-substring-search |
| `Right` at the end of the line | Accept the displayed history suggestion | zsh-autosuggestions |
| `Ctrl-T` | Select files and insert their paths | fzf |
| `Alt-C` | Select a directory and change into it | fzf |
| `Ctrl-G` | Insert a command from an interactive cheatsheet | Navi and fzf |
| `Ctrl-Space` | Same Navi widget, preserving the original shortcut | Navi and fzf; the desktop must pass this key through |
| `Esc` twice | Prefix the current command with `sudo` | Oh My Zsh `sudo` plugin |

For example, type `docker`, then press `Up` to cycle through matching history.
Press `Ctrl-R` for a larger searchable history view. Type `nvim **` and press
`Tab` for fzf path completion.

Atuin loads after fzf so that it owns `Ctrl-R`. Its initialization uses
`--disable-up-arrow --disable-ai`, leaving arrow keys and the `?` character alone.
Navi's native widget inserts the selected command into the editable command line;
review it and press Enter when ready.

The default editing mode is Emacs. To choose Vi mode, put `bindkey -v` in the
personal override file. Integrations may expose different bindings in Vi insert
and command modes; check them with `bindkey -M viins` and `bindkey -M vicmd`.

## Command shortcuts

Aliases that need a command are defined only if that command is available when
the shell starts. After installing a missing tool, run `exec zsh`.

| Command | Meaning | Example / detail |
| --- | --- | --- |
| `l` | Detailed listing with permissions, user, group, inode, date and name | Uses `lsd` when available; otherwise `ls -Alh` |
| `ll` | Long listing | `ll ~/Downloads` |
| `la` | List entries including hidden ones | `la` |
| `bat` | Debian's `batcat` command | Defined only when `batcat` exists and a native `bat` executable does not |
| `yd` | APT-installed `yt-dlp` | `yd 'https://example.com/video'` |
| `kctx` | `kubectx` | Switch Kubernetes context |
| `kns` | `kubens` | Switch Kubernetes namespace |
| `ports` | `ss -tulpn` | Listening TCP/UDP sockets; process details can require privileges |
| `mnt` | `findmnt --real` | Show real filesystems without parsing formatted `mount` output |
| `untar` | `tar -xzvf` | Extract a `.tar.gz`; for other archives use `tar -xf` or OMZ's `extract` |
| `www` | Python HTTP server on `127.0.0.1` | `www 8000`; serves the current directory for local preview |
| `now`, `nowtime` | Current time | `HH:MM:SS` |
| `nowdate` | Current date | `DD-MM-YYYY` |
| `mylocalip` | Brief IPv4 addresses by interface | Uses `ip -brief -4 address show` |
| `myip` | Public address reported by ipify | HTTPS with a 5-second connection timeout and 10-second overall timeout |
| `wttr` | Weather report | Defaults to Tehran; `wttr Berlin` or `wttr 'Salt Lake City'` |
| `today_fortune` | Random fortune | Adds the `boxes` nuke frame when `boxes` is installed |

`www` binds to localhost explicitly. If you want other machines on your LAN to
reach the server, run the deliberate command:

```zsh
python3 -m http.server 8000 --bind 0.0.0.0
```

The public-IP and weather commands make network requests when invoked. They do
not run at shell startup. Decorative output remains easy to add when you have
installed the optional fun tools:

```zsh
myip | cowsay -n -f ghostbusters | lolcat
mylocalip | cowsay -n -f ghostbusters | lolcat
```

`sherlock` and `yt-dlp` are normal APT-provided commands; there are no aliases
pointing into deleted Python environments. `youtube-dl` is a different command
name and is not silently redefined. In this repository, `yd` selects `yt-dlp`.

## Included Oh My Zsh functionality

These plugin candidates come with [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins).
The loader checks that each one exists, which also tolerates differences between
Oh My Zsh versions. Installing a plugin is separate from installing its command:
for example, the Docker plugin does not install the Docker daemon.

| Plugin | What it contributes | Typical use |
| --- | --- | --- |
| `ansible` | Ansible completion and shortcuts | Complete playbook and inventory commands |
| `colored-man-pages` | Color in supported manual-page pagers | `man tar` |
| `debian` | Debian/APT shortcuts | Consult `alias` for the installed OMZ version's aliases |
| `dirhistory` | Directory-history navigation | Move back through visited working directories |
| `docker` | Docker completion and aliases | Complete `docker` subcommands |
| `docker-compose` | Compose completion and aliases | Use modern `docker compose` after Docker is installed |
| `emoji` | Emoji-related helpers | Insert emoji from the shell |
| `encode64` | Base64 helpers | `encode64 text`, `decode64 encoded-text` |
| `extract` | Select the extractor for an archive | `extract archive.zip` |
| `git` | Git aliases and completion | `gst`, `gco`, `gl`, `gp` |
| `golang` | Go aliases/completion | Work with the Go toolchain selected by PATH |
| `helm` | Helm completion | Complete Helm commands when installed |
| `history` | History helpers | Inspect shell history |
| `httpie` | HTTPie completion | `http GET https://example.com` |
| `jsontools` | JSON formatting helpers | `pp_json < data.json` |
| `kubectl` | Kubernetes completion and aliases | Complete `kubectl` arguments |
| `man` | Manual-page integration | Look up command documentation |
| `ssh` | SSH integration when provided by the installed OMZ version | Complete SSH-related commands |
| `sudo` | Add sudo to the command line | Press `Esc` twice |
| `tldr` | Completion for the tldr client | `tldr tar` |
| `thefuck` | Correction helper integration | `fuck` after a mistyped command, when installed |
| `vscode` | VS Code convenience command | `vsc .` |
| `web-search` | Search-engine helpers | `google zsh completion` |

See a particular plugin's README in
`~/.oh-my-zsh/plugins/PLUGIN/README.md` for its full alias list. The repository
does not copy that changing upstream alias list into another maintenance burden.

## Third-party plugins

The installer uses explicit directory names. A repository named
`zsh-you-should-use` must be installed as `you-should-use` for Oh My Zsh to find
`you-should-use.plugin.zsh`; guessing directory names from Git URLs caused
failures in the previous installer example.

| Directory | Upstream | Purpose |
| --- | --- | --- |
| `colors` | [zpm-zsh/colors](https://github.com/zpm-zsh/colors) | Supply the associative color map required by the custom colorize plugin |
| `colorize` | [zpm-zsh/colorize](https://github.com/zpm-zsh/colorize) | Color settings for GCC, grep and less, plus command aliases; loaded after its colors dependency |
| `zsh-autosuggestions` | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Suggest previous commands as you type |
| `zsh-history-substring-search` | [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Up/Down substring search |
| `you-should-use` | [MichaelAquilina/zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) | Remind you when a matching alias exists |
| `zsh-256color` | [chrissicool/zsh-256color](https://github.com/chrissicool/zsh-256color) | Terminal color-support adjustments |
| `fast-syntax-highlighting` | [zdharma-continuum/fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Highlight the command line; sourced once, last |
| `docker-helpers` (extra) | [unixorn/docker-helpers.zshplugin](https://github.com/unixorn/docker-helpers.zshplugin) | Additional Docker helper commands |
| `git-flow-completion` (extra) | [bobthecow/git-flow-completion](https://github.com/bobthecow/git-flow-completion) | Git Flow completion |
| `ssh-connect` (extra) | [gko/ssh-connect](https://github.com/gko/ssh-connect) | Interactive SSH host chooser; its script is sourced directly |

The optional extras load only when installed. Use
`scripts/install-plugins.sh --extras` to include them in the installation plan.
The `ssh-connect` helper also needs its upstream `listbox` Git submodule. The
installer clones submodules and repairs an ordinary clone missing that dependency
when you add `--apply`; `.zshrc` skips an incomplete helper quietly. The OMZ
`thefuck` plugin is also skipped when its executable is missing, avoiding its
otherwise noisy installation reminder.

### Colorize and its dependency

The original setup installed **zpm-zsh/colorize** in
`~/.oh-my-zsh/custom/plugins/colorize`. It configures command colors and aliases;
it requires **zpm-zsh/colors** to be loaded first. The old installation example
omitted that dependency. Without its associative array `c`, expressions such as
`${c[bold]}` can be interpreted as arithmetic and produce the startup error
`bad math expression: illegal character: ^[` when a color variable contains an
escape character.

Oh My Zsh also ships an unrelated **bundled colorize** plugin. That one provides
`ccat` and `cless` for syntax-colored file viewing with Pygments or Chroma. The
custom plugin normally shadows it, so a plain `colorize` entry in `plugins=(...)`
does not tell you which feature will load.

This configuration handles the distinction explicitly:

1. When the custom colorize file exists, load the custom `colors` dependency
   first and verify that `c` is an associative array before loading colorize.
2. If the dependency is missing, skip that component quietly; `scripts/doctor.sh`
   reports the incomplete installation. No package is fetched during startup.
3. When `NO_COLOR` is nonempty or `CLICOLOR=0`, skip the custom color plugins.
4. When no custom colorize file exists, use the bundled plugin by its exact path
   as a compatibility fallback. Only this fallback supplies `ccat` and `cless`.

Both custom plugins are included in the core installation plan. Run the installer
to supply the missing dependency while preserving existing checkouts:

```bash
./scripts/install-plugins.sh --apply
exec zsh
```

`colors` and `colorize` are reserved in the plugin selection hook; adding them to
`MYZSH_EXTRA_PLUGINS` does not load a second copy. Do not create an empty `c` array
as a workaround: the dependency supplies the actual named color values. For
ordinary syntax-colored file viewing, use `bat` (Debian's `batcat`).

See the upstream [custom colorize dependency instructions](https://github.com/zpm-zsh/colorize#how-to-install),
[colors load-order instructions](https://github.com/zpm-zsh/colors#installation),
and [bundled OMZ colorize documentation](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colorize).

## Why several old plugins disappeared

| Previous setup | Current choice | Reason |
| --- | --- | --- |
| Manual mise initialization plus the OMZ mise plugin | One manual `mise activate zsh` | The plugin initializes mise itself, so loading both duplicates integration |
| `z` plus zoxide | zoxide's `z` and `zi` | One directory-jump database and command owner |
| Two syntax highlighters | fast-syntax-highlighting | Avoid two components highlighting and wrapping the same editing widgets |
| Atuin, fzf-history-search and histdb | Atuin, with the normal Zsh history file retained | One searchable history integration; fewer competing keybindings/hooks |
| zsh-navi-plugin plus a manual binding | `navi widget zsh` | Navi ships its own maintained integration |
| zsh-bat and zsh-lsd wrappers | Small explicit aliases | Command mappings remain visible in `.zshrc` |
| zsh-interactive-cd | fzf `Alt-C` and `cd **<Tab>` | Reuse the existing fzf integration |
| Pyenv paths and environment-specific aliases | APT commands and project-scoped mise | Match the updated installation model |
| NVM startup hooks | Project-scoped mise for Node when requested | Avoid a second runtime manager changing the shell's Node selection |
| Hacker quotes / full automatic plugin updates | On-demand fun tools and explicit updates | Keep ordinary shell startup quiet and predictable |

Old history databases are not deleted. Existing NVM installations are not
uninstalled; their startup hooks simply are not part of this shared setup. If
you still need a legacy project, invoke its environment deliberately or keep
your own override until you migrate it.

## Personal changes

To add Oh My Zsh plugins without editing the shared list, create
`~/.config/zsh/plugins.zsh` (or `$XDG_CONFIG_HOME/zsh/plugins.zsh`) containing:

```zsh
MYZSH_EXTRA_PLUGINS=(magic-enter copybuffer copypath copyfile)
```

This optional file is read **before** plugin discovery and Oh My Zsh startup.
Names are deduplicated and unavailable plugins are skipped. See
[plugin recommendations](plugin-recommendations.md) for what these extras do and
which ones suit particular workflows. Do not add `mise`, `z`, another history
integration or another syntax highlighter without also adjusting the existing
integration that handles the same job.
The names `colors` and `colorize` are handled by the explicit dependency-aware
loader described above and are excluded from this generic selection hook.

For aliases, settings and keybindings that apply **after** the shared setup,
use the separate `local.zsh` file below.

Copy [the example](../config/zsh/local.zsh.example) if you need a starting point:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
cp -n config/zsh/local.zsh.example "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh"
```

Edit that file for personal aliases, an alternate `WEATHER_CITY`, private script
paths or a trusted JetBrains options file. It is sourced after the common setup
and before highlighting. Use `~/.p10k.zsh` for Powerlevel10k appearance:

```zsh
p10k configure
```

Your original `~/.p10k.zsh` was not supplied with these dotfiles, so no replacement
prompt profile is invented or installed. Powerlevel10k can guide you through
creating one when you run the command above.

Restart instead of repeatedly sourcing `.zshrc`, because third-party widgets
and hooks are not all designed for repeated initialization in one process:

```zsh
exec zsh
```

## Troubleshooting

| Symptom | Check |
| --- | --- |
| A command or alias is missing | `type -a COMMAND`; install its package and start a new shell |
| The shell looks plain | Check the Oh My Zsh and Powerlevel10k directories; run the plugin installer |
| Alias reminders are noisy | Remove `you-should-use` from the candidates in `.zshrc`, then `exec zsh` |
| `Ctrl-R` opens fzf instead of Atuin | `type -a atuin`; make sure the Cargo bin directory is in PATH |
| `atuin init` rejects `--disable-ai` | Update the Atuin installation to the current supported release; this setup uses the supplied modern Atuin version |
| Arrow keys do not search substrings | Check installation of `zsh-history-substring-search`; inspect `bindkey '^[[A'` |
| `Ctrl-Space` does nothing | Try `Ctrl-G`; check the KDE/input-method shortcut assigned to Ctrl-Space |
| `nvim` opens the distribution's version | Check `/opt/nvim-linux-x86_64/bin/nvim` exists and `type -a nvim` |
| Python still points into PlatformIO or an old environment | Check `VIRTUAL_ENV`, `type -a python3`, `.zshenv`, `.zprofile` and the terminal's parent environment |
| A function seems to have changed | `whence -v NAME` and `functions NAME` show its final definition; inspect your local override |

## Upstream references

- [Zsh completion initialization and security checks](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit)
- [Oh My Zsh plugin directory](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins)
- [Powerlevel10k setup and font instructions](https://github.com/romkatv/powerlevel10k)
- [Atuin initialization flags](https://docs.atuin.sh/main/reference/init/)
- [Atuin v18.24.1 flag definitions](https://github.com/atuinsh/atuin/blob/v18.24.1/crates/atuin/src/command/client/init.rs)
- [fzf shell integration](https://github.com/junegunn/fzf#setting-up-shell-integration)
- [Navi's Zsh widget](https://github.com/denisidoro/navi/blob/master/shell/navi.plugin.zsh)
- [Zsh history substring search and keybindings](https://github.com/zsh-users/zsh-history-substring-search)
- [wttr.in location syntax](https://github.com/chubin/wttr.in#usage)
