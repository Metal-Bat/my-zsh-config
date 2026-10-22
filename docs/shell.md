# Shell guide

[Back to the README](../README.md)

The shared [`.zshrc`](../.zshrc) is the entry point for the complete personal
setup. The one-command installer supplies the whole plugin collection; you do
not choose a plugin profile. The shell also tolerates an interrupted or partial
installation: missing commands, plugins and personal files are skipped.

## Startup order

| Stage | What happens | Why it is in this position |
| --- | --- | --- |
| Login quote | Print a local hacker quote in a login shell attached to a terminal | Display intentional output before Powerlevel10k captures startup output |
| Instant prompt | Load the existing Powerlevel10k cache when present | Display the prompt while the rest of the setup loads |
| Paths | Add local binaries, Cargo, Go, Neovim and Flatpak | Integrations can find their executables when they initialize |
| Basics | Configure history, Vi editing and a fallback prompt | A working interactive shell does not depend on Oh My Zsh |
| Oh My Zsh | Load installed plugin candidates and the available theme | Supply completion and familiar command shortcuts |
| Command colors | Load zpm's colors dependency before its custom colorize plugin | Preserve the original command coloring without the plugin-name collision |
| Aliases | Set personal shortcuts after Oh My Zsh | Repository shortcuts have predictable final definitions |
| Integrations | Initialize fzf, zoxide, mise, Atuin and Navi once each | Keep each shortcut and hook under one integration |
| Personal setup | Load the personal Powerlevel10k profile and `~/.config/zsh/local.zsh` if present | Preserve your prompt and machine-specific preferences |
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
| `/usr/games` | Debian's fortune/cowsay tools, when this directory exists |

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

**Vi editing is the default**, matching the supplied configuration. A new command
line starts in insert mode. Press `Esc` to enter command mode, then use normal Vi
motions such as `h`, `l`, `w`, `b`, `0` and `$`; press `i` or `a` to resume typing.
The `vi-mode` plugin also supports `vv` in command mode to edit the command line
in `$EDITOR`, which defaults to Neovim when it is installed.

| Key | Behavior | Required component |
| --- | --- | --- |
| `Tab` | Command, path and argument completion | Zsh / Oh My Zsh |
| `Ctrl-R` | Search recorded command history, in both Vi modes and the Emacs map | Atuin; otherwise fzf history search when available |
| `/` in Vi command mode | Open Atuin history search | Atuin's native Vi integration |
| `Up` / `Down`, `Ctrl-P` / `Ctrl-N` | Search history for the text already typed, in both Vi modes | zsh-history-substring-search |
| `k` / `j` in Vi command mode | The same substring history navigation | zsh-history-substring-search |
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
These flags are supported by the supplied Atuin **18.24.1**. The shell explicitly
binds `Ctrl-R` in Vi command mode too, where Atuin normally binds only `/`.
Navi's native widget inserts the selected command into the editable command line;
review it and press Enter when ready. `Ctrl-G` and `Ctrl-Space` are assigned in
both Vi keymaps and in the Emacs keymap.

To choose Emacs editing instead, put `bindkey -e` in the personal override file.
Inspect final bindings with `bindkey -M viins` and `bindkey -M vicmd` (or
`bindkey -M emacs`). Changes in `local.zsh` run after the shared bindings.

## Command shortcuts

Aliases that need a command are defined only if that command is available when
the shell starts. After installing a missing tool, run `exec zsh`.

| Command | Meaning | Example / detail |
| --- | --- | --- |
| `ls` | `lsd --group-directories-first` | Personal colorful listing; use `command ls` for the system command |
| `l` | Detailed listing with permissions, user, group, inode, date and name | Uses `lsd` when available; otherwise `ls -Alh` |
| `ll` | Long listing | `ll ~/Downloads` |
| `la` | List entries including hidden ones | `la` |
| `tree` | An `lsd` tree, two levels deep | `tree ~/Projects`; use `lsd --tree --depth=4` to change depth |
| `bat` | Debian's `batcat` command | Defined only when `batcat` exists and a native `bat` executable does not |
| `cat` | `bat` / `batcat` with paging disabled | A syntax-colored file view without opening a pager |
| `rcat` | `command cat` | Original byte-oriented command; also available as `command cat` |
| `yd`, `y` | APT-installed `yt-dlp` | `yd 'https://example.com/video'`; `y` comes from the requested plugin |
| `kctx` | `kubectx` | Switch Kubernetes context |
| `kns` | `kubens` | Switch Kubernetes namespace |
| `ports` | `ss -tulpn` | Listening TCP/UDP sockets; process details can require privileges |
| `mnt` | `findmnt --real` | Show real filesystems without parsing formatted `mount` output |
| `untar` | `tar -xzvf` | Extract a `.tar.gz`; for other archives use `tar -xf` or OMZ's `extract` |
| `www` | Python HTTP server on `127.0.0.1` | `www 8000`; serves the current directory for local preview |
| `now`, `nowtime` | Current time | `HH:MM:SS` |
| `nowdate` | Current date | `DD-MM-YYYY` |
| `tt` | Convert dates and Unix timestamps using GNU date | `tt`, `tt 1571222561`, `tt '2019-10-16 18:41:00'`; uses the local timezone |
| `mylocalip` | Brief IPv4 addresses by interface | Uses `ip -brief -4 address show`; adds cowsay/lolcat decoration at a terminal |
| `myip` | Public address reported by ipify | HTTPS with a 5-second connection timeout and 10-second overall timeout; same terminal decoration |
| `wttr` | Weather report | Defaults to Tehran; `wttr Berlin` or `wttr 'Salt Lake City'` |
| `today_fortune` | Random fortune | Adds the `boxes` nuke frame when `boxes` is installed |
| `hacker_quote` | Print one of the quote plugin's local quotes on demand | No network request |

The colorful `cat` and `ls` aliases apply to interactive shell commands. Some
options differ from GNU `cat` and `ls`; use `command cat`, `command ls` or `rcat`
when you need their original behavior. `bat` remains available with its normal
pager behavior; only the `cat` alias includes `--paging=never`. The shell does not
replace `MANPAGER` with the bat wrapper, so `colored-man-pages` remains the manual
page integration.

`www` binds to localhost explicitly. If you want other machines on your LAN to
reach the server, run the deliberate command:

```zsh
python3 -m http.server 8000 --bind 0.0.0.0
```

The public-IP and weather commands make network requests when invoked. They do
not run at shell startup. `myip` and `mylocalip` retain the Ghostbusters cowsay
art and lolcat colors when their output goes to a terminal and those commands
are available. There is no artificial animation delay. Redirected output and
command substitution stay plain, so these remain useful in other commands:

```zsh
myip                     # Decorated terminal view.
public_ip=$(myip)         # Plain address.
mylocalip > addresses.txt # Plain interface list.
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
| `aliases` | A searchable cheatsheet of currently defined aliases | `als`, `als git`, `als --groups`; uses system Python 3 |
| `ansible` | Ansible completion and shortcuts | Complete playbook and inventory commands |
| `colored-man-pages` | Color in supported manual-page pagers | `man tar` |
| `debian` | Debian/APT shortcuts | Consult `alias` for the installed OMZ version's aliases |
| `dirhistory` | Directory-history navigation | Move back through visited working directories |
| `docker` | Docker completion and aliases | Complete `docker` subcommands |
| `docker-compose` | Compose completion and aliases | Use modern `docker compose` after Docker is installed |
| `emoji` | Emoji-related helpers | Insert emoji from the shell |
| `emoji-clock` | Current time as a clock emoji, rounded to half-hour increments | `emoji-clock` |
| `encode64` | Base64 helpers | `encode64 text`, `decode64 encoded-text` |
| `extract` | Select the extractor for an archive | `extract archive.zip` |
| `gh` | GitHub CLI completion | `gh pr list`; authentication is a separate user action |
| `git` | Git aliases and completion | `gst`, `gco`, `gl`, `gp` |
| `golang` | Go aliases/completion | Work with the Go toolchain selected by PATH |
| `helm` | Helm completion | Complete Helm commands when installed |
| `history` | History helpers | Inspect shell history |
| `httpie` | HTTPie completion | `http GET https://example.com` |
| `jsontools` | JSON formatting helpers | `pp_json < data.json` |
| `kubectl` | Kubernetes completion and aliases | Complete `kubectl` arguments |
| `lol` | Catspeak aliases | `plz` for `pwd`, `icanhas` for `mkdir`; its `tldr=less` alias is removed so the installed tldr client wins |
| `man` | Manual-page integration | Look up command documentation |
| `pass` | Completion for the GPG-backed password manager | `pass ls`; configure your own key/store before storing passwords |
| `repo` | Android/Google Repo aliases and completion | `rst` for `repo status`, `rs` for `repo sync` in a configured checkout |
| `ssh` | SSH integration when provided by the installed OMZ version | Complete SSH-related commands |
| `ssh-agent` | Reuse a working agent or start one when needed | Quiet startup with lazy key loading; no passphrase prompt just from opening a shell |
| `sudo` | Add sudo to the command line | Press `Esc` twice |
| `tldr` | Completion for the tldr client | `tldr tar` |
| `thefuck` | Correction helper integration | `fuck` after a mistyped command, when installed |
| `tmux` | Terminal-multiplexer shortcuts | `ts work`, `tl`, `ta work`; the plugin does not autostart tmux |
| `tt` | Timestamp/date conversion | The repository supplies a GNU-date implementation because the upstream function uses BSD-date flags |
| `vscode` | VS Code convenience command | `vsc .` |
| `vi-mode` | Vi editing, command-line editor and clipboard integration | `Esc` switches mode; `vv` opens the line in `$EDITOR` |
| `web-search` | Search-engine helpers | `google zsh completion` |

The names `gitignore`, `hacker-quotes` and `yt-dlp` use the external repositories
listed below. `gitignore` deliberately uses local GitHub templates rather than
the differently implemented bundled OMZ plugin.

The SSH-agent plugin honors a live inherited `SSH_AUTH_SOCK`. Its `lazy` setting
does not pre-load keys; run `ssh-add ~/.ssh/id_ed25519` deliberately when needed,
or configure OpenSSH's `AddKeysToAgent` setting yourself. The installer creates
`~/.ssh` if absent; the shell skips agent startup when that directory or the
OpenSSH commands are missing.

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
| `docker-helpers` | [unixorn/docker-helpers.zshplugin](https://github.com/unixorn/docker-helpers.zshplugin) | Additional Docker helper commands |
| `git-flow-completion` | [bobthecow/git-flow-completion](https://github.com/bobthecow/git-flow-completion) | Git Flow completion |
| `ssh-connect` | [gko/ssh-connect](https://github.com/gko/ssh-connect) | Interactive SSH host chooser; its script is sourced directly |
| `gitignore` | [voronkovich/gitignore.plugin.zsh](https://github.com/voronkovich/gitignore.plugin.zsh) | `gi` prints local templates, `gia` / `gii` append them, `gie` edits the ignore file |
| `hacker-quotes` | [oldratlee/hacker-quotes](https://github.com/oldratlee/hacker-quotes) | A local quote on interactive login, before instant prompt; also available through `hacker_quote` |
| `yt-dlp` | [clavelm/yt-dlp-omz-plugin](https://github.com/clavelm/yt-dlp-omz-plugin) | `y` shortcut for yt-dlp; `yd` is also kept |

Powerlevel10k is installed separately under `custom/themes/powerlevel10k` from
[romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k). The remaining
installed checkouts and their deliberately consolidated integrations are listed
in the next section.

All entries in [the plugin manifest](../manifests/plugins.txt) are included in the
normal installer. `ssh-connect` requires its `listbox` Git submodule, and the
custom `gitignore` plugin requires its `templates` submodule. The installer clones
both recursively and repairs these known missing submodules in an unchanged
checkout from the expected origin. `.zshrc` skips an incomplete SSH helper
quietly. The OMZ `thefuck` and `tmux` plugins are also skipped when their commands
are missing, avoiding their otherwise noisy installation reminders.

For local ignore templates, try:

```zsh
gi Go Python          # Print combined templates; no file is changed.
gia Go Python         # Append templates to the current repository's .gitignore.
gie                   # Open that .gitignore in $EDITOR.
```

`hacker-quotes` uses upstream's login-only default, prints at most once per shell,
and does not run when stdout is redirected. The regular Kitty shell can still request a quote with
`hacker_quote`; this does not require a web service or a quote package.

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

Both custom plugins are included in the complete installation. Run the helper
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

## Installed wrappers and consolidated integrations

The installer keeps the external plugins from both supplied configurations,
including the checkouts below. **Installed does not mean loaded twice.** Features
that share a keybinding, history hook or pager have one active implementation.

| Installed checkout | Active behavior | Why the wrapper stays inactive |
| --- | --- | --- |
| [joshskidmore/zsh-fzf-history-search](https://github.com/joshskidmore/zsh-fzf-history-search) | Atuin owns `Ctrl-R`; native fzf supplies file selection and directory navigation | A second history wrapper would overwrite the same keybinding |
| [larkery/zsh-histdb](https://github.com/larkery/zsh-histdb) | Atuin records searchable history; the normal Zsh history file remains | Do not add another history database and execution hook by default |
| [icatalina/zsh-navi-plugin](https://github.com/icatalina/zsh-navi-plugin) | `navi widget zsh`, bound to `Ctrl-G` and `Ctrl-Space` in all supported keymaps | Navi ships its own integration |
| [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | fast-syntax-highlighting loads last | Both plugins would wrap and color the same line-editor widgets |
| [fdellwing/zsh-bat](https://github.com/fdellwing/zsh-bat) | Explicit `cat` / `rcat` shortcuts, with `--paging=never` for `cat` | The wrapper also replaces `MANPAGER`; manual pages keep `colored-man-pages` |
| [wintermi/zsh-lsd](https://github.com/wintermi/zsh-lsd) | Explicit `ls`, `l`, `ll`, `la` and `tree` shortcuts | Keep the exact personal command mappings together in `.zshrc` |
| [Pilaton/OhMyZsh-full-autoupdate](https://github.com/Pilaton/OhMyZsh-full-autoupdate) | Deliberate updates through the repository installer | Its startup hook can print a banner and pull many repositories as a terminal opens, without the installer's clean-tree and expected-origin checks |

The bundled OMZ `mise`, `z` and `zsh-interactive-cd` plugins are available with the
framework but not enabled: manual `mise activate zsh`, zoxide's `z` / `zi`, and
native fzf `Alt-C` / `cd **<Tab>` already supply those integrations. Television
remains available as `tv`; no extra keybinding steals a shortcut from the shell.

Use one explicit command when you want framework and plugin updates:

```bash
./scripts/install-plugins.sh --apply --update
```

The helper fast-forwards only clean Git checkouts with the expected origin,
reports directories it preserves, and initializes required submodules. Ordinary
shell startup does not fetch plugins or run a full system update.

Pyenv hooks and environment-specific command paths have been removed to match
the requested move to mise and APT-provided tools. NVM hooks are also absent so
Node has one runtime manager. Existing NVM installations and old history
databases are not deleted. Invoke an old environment deliberately when a legacy
project still requires it.

## Personal changes

To add Oh My Zsh plugins without editing the shared list, create
`~/.config/zsh/plugins.zsh` (or `$XDG_CONFIG_HOME/zsh/plugins.zsh`) containing:

```zsh
MYZSH_EXTRA_PLUGINS=(magic-enter copypath copyfile)
```

This optional file is read **before** plugin discovery and Oh My Zsh startup.
Names are deduplicated and unavailable plugins are skipped. See
[plugin recommendations](plugin-recommendations.md) for what these extras do and
which ones suit particular workflows. These are examples for a later personal
choice, not additional defaults. Reserved integration names are filtered here:
`mise`, `z`, both highlighters, the superseded wrappers listed above,
`zsh-interactive-cd`, `hacker-quotes`, `colors` and `colorize`. Changing the owner
of one of those features requires changing its explicit integration in `.zshrc`,
rather than adding a duplicate through this hook. The color plugins retain the
dependency-aware loading described above.

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

Your original `~/.p10k.zsh` was not supplied with these dotfiles. The complete
installer uses Powerlevel10k's upstream lean configuration as a starting point
only when that file is absent; it preserves any existing personal profile.
`p10k configure` lets you choose a different appearance afterward.
When `ZDOTDIR` is set, the shell prefers `$ZDOTDIR/.p10k.zsh` and falls back to
`~/.p10k.zsh`, matching the installer's configuration location.

The shared configuration deduplicates PATH and its main hook arrays, reuses a
live SSH agent, and avoids repeating the login quote when sourced again. For
changes to the plugin collection, start a fresh shell so removed plugins cannot
leave old widgets or functions behind:

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
| Arrow keys do not search substrings | Check installation of `zsh-history-substring-search`; inspect `bindkey -M viins '^[[A'` and `bindkey -M vicmd '^[[A'` |
| `tldr` opens a pager | `alias tldr` reveals a later override; this setup removes the `lol` plugin's `tldr=less` alias |
| `cat` or `ls` behaves differently from GNU tools | Use `command cat`, `rcat` or `command ls`; inspect `alias cat ls` for the personal shortcuts |
| `gi Python` cannot find a template | Run `./scripts/install-plugins.sh --apply` to initialize the gitignore template submodule |
| `ssh-agent` asks for keys at startup | Check your private overrides; the shared plugin settings use `lazy yes`, `quiet yes` and `honor-existing yes` |
| `Ctrl-Space` does nothing | Try `Ctrl-G`; check the KDE/input-method shortcut assigned to Ctrl-Space |
| `nvim` opens the distribution's version | Check `/opt/nvim-linux-x86_64/bin/nvim` exists and `type -a nvim` |
| Python still points into PlatformIO or an old environment | Check `VIRTUAL_ENV`, `type -a python3`, `.zshenv`, `.zprofile` and the terminal's parent environment |
| A function seems to have changed | `whence -v NAME` and `functions NAME` show its final definition; inspect your local override |

## Upstream references

- [Zsh completion initialization and security checks](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit)
- [Oh My Zsh plugin directory](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins)
- [Oh My Zsh Vi-mode integration](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode)
- [Oh My Zsh SSH-agent settings](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/ssh-agent)
- [Powerlevel10k setup and font instructions](https://github.com/romkatv/powerlevel10k)
- [Atuin initialization flags](https://docs.atuin.sh/main/reference/init/)
- [Atuin v18.24.1 flag definitions](https://github.com/atuinsh/atuin/blob/v18.24.1/crates/atuin/src/command/client/init.rs)
- [fzf shell integration](https://github.com/junegunn/fzf#setting-up-shell-integration)
- [Navi's Zsh widget](https://github.com/denisidoro/navi/blob/master/shell/navi.plugin.zsh)
- [Zsh history substring search and keybindings](https://github.com/zsh-users/zsh-history-substring-search)
- [wttr.in location syntax](https://github.com/chubin/wttr.in#usage)
