# Tool catalog and practical examples

The versions below are the owner's **2026-10-22 `cargo install --list`
snapshot**. They are not a claim that each is the newest release. The
[manifest](../manifests/cargo-tools.txt) is the installer's machine-readable
inventory and retains every reported crate and executable.

## Choose the tool for the job

| Task | Start with | Why keep the others? |
| --- | --- | --- |
| Command history | Atuin | Zsh substring search remains useful on Up/Down; avoid another Ctrl-R owner |
| Find a directory | zoxide `z` / `zi` | fzf's Alt-C is a direct filesystem picker |
| Search files or text | `fdfind`, `rg`, fzf | Television adds configurable interactive channels |
| Read a file | `bat` / `batcat` | Plain `cat` stays available for pipelines |
| List files | `lsd` and `l` | `tre` shows hierarchy; `eza` is another deliberate alternative |
| Diagnose disk usage | `dust` for an overview; `dua i` to explore | Their interfaces solve slightly different tasks |
| Diagnose processes | `btm` | htop or Debian btop are alternatives; choose the one you prefer |
| Inspect structured data | `jq`, `csvlens`, `xsv`, `htmlq` | JSON, CSV and HTML require different query tools |
| Remember a command | `tldr` for examples; navi for reusable recipes | navi's shell widget inserts commands for review |
| Maintain the workstation | Each package manager directly | Topgrade can coordinate them after reviewing a dry run |

## Complete Cargo inventory

Each project link leads to its upstream usage reference. The **crate name** is
what Cargo installs; the **command** is what you type. They are often different.

| Crate · recorded version | Command(s) | Purpose and first use |
| --- | --- | --- |
| [atuin](https://github.com/atuinsh/atuin) · 18.24.1 | `atuin` | Search shell history with context; press **Ctrl-R** or run `atuin search` |
| [bandwhich](https://github.com/imsnif/bandwhich) · 0.23.1 | `bandwhich` | Live network usage by process/connection; `sudo "$(command -v bandwhich)"` |
| [bottom](https://github.com/ClementTsang/bottom) · 0.14.9 | `btm` | Interactive CPU, memory, disk and process monitor; run `btm` |
| [btop](https://crates.io/crates/btop) · 0.1.0 | `btop` | Recorded Cargo package; verify provenance before reproducing it; see the note below |
| [cargo-update](https://github.com/nabijaczleweli/cargo-update) · 22.1.1 | `cargo-install-update`, `cargo-install-update-config` | Update Cargo-installed applications; `cargo install-update -a` performs updates |
| [csvlens](https://github.com/YS-L/csvlens) · 0.15.1 | `csvlens` | Browse and search CSV interactively; `csvlens data.csv` |
| [du-dust](https://github.com/bootandy/dust) · 1.2.6 | `dust` | Readable directory-size overview; `dust .` |
| [dua-cli](https://github.com/Byron/dua-cli) · 2.46.0 | `dua` | Explore disk usage interactively; `dua i` |
| [eva](https://github.com/oppiliappan/eva) · 0.3.1 | `eva` | Calculator REPL; run `eva`, then enter expressions |
| [exa](https://github.com/ogham/exa) · 0.10.1 | `exa` | Older enhanced file listing; `exa -la`; opt-in legacy entry |
| [git-cliff](https://git-cliff.org/docs/) · 2.14.2 | `git-cliff`, `git-cliff-completions`, `git-cliff-mangen` | Generate changelogs from Git history; `git cliff` previews output |
| [htmlq](https://github.com/mgdm/htmlq) · 0.4.0 | `htmlq` | Query HTML with CSS selectors; `htmlq --text title < index.html` |
| [jql](https://github.com/yamafaktory/jql) · 9.0.3 | `jql` | JSON querying with its own query language; `jql '"name"' data.json` |
| [linutil_tui](https://github.com/ChrisTitusTech/linutil) · 26.7.17 | `linutil` | Menu-driven Linux utilities; run `linutil` and inspect a task before applying it |
| [rtk](https://github.com/rtk-ai/rtk) · 1.0.1 | `rtk` | Compact output for supported development commands; `rtk git status` |
| [navi](https://github.com/denisidoro/navi) · 2.24.0 | `navi` | Searchable command recipes; **Ctrl-Space** or **Ctrl-G** uses the shell widget |
| [spacer](https://github.com/samwho/spacer) · 0.5.0 | `spacer` | Mark pauses in streaming output; `journalctl -f \| spacer` |
| [television](https://github.com/alexpasmantier/television) · 0.15.9 | `tv` | Interactive fuzzy finder with configurable channels; start with `tv` |
| [tlrc](https://github.com/tldr-pages/tlrc) · 1.13.1 | `tldr` | Concise command examples; `tldr tar`, `tldr git-rebase` |
| [toipe](https://github.com/Samyak2/toipe) · 0.5.0 | `randomword`, `toipe` | Terminal typing practice; run `toipe` |
| [tokei](https://github.com/XAMPPRocky/tokei) · 15.0.0 | `tokei` | Count code by language; `tokei .` |
| [topgrade](https://github.com/topgrade-rs/topgrade) · 17.14.1 | `topgrade` | Coordinate installed updaters; inspect `topgrade --dry-run` first |
| [tre-command](https://github.com/dduan/tre) · 0.4.0 | `tre` | Directory tree display; `tre .` |
| [tree-sitter-cli](https://tree-sitter.github.io/tree-sitter/) · 0.27.1 | `tree-sitter` | Parser tooling used by editor workflows; verify `tree-sitter --version` |
| [wallust](https://explosion-mental.codeberg.page/wallust/) · 3.5.1 | `wallust` | Generate terminal palettes from images; inspect `wallust --help` and configure templates when wanted |
| [xplr](https://xplr.dev/) · 1.1.2 | `xplr` | Keyboard-driven terminal file explorer; run `xplr` |
| [xsv](https://github.com/BurntSushi/xsv) · 0.13.0 | `xsv` | CSV transformations and summaries; `xsv headers data.csv` |

Some tools perform changes after you select an operation: `dua i` and `xplr`
include file operations; `linutil` can perform system tasks; Topgrade updates
software. The shell configuration does not launch any of them automatically.

## Shell productivity

### Atuin: one history search owner

Press **Ctrl-R** in an interactive shell. Atuin initializes after fzf so its
history binding takes precedence. Up/Down remain available to substring search,
and the supplied Atuin flags leave its AI keybinding disabled.

To bring existing shell history into Atuin deliberately:

```zsh
atuin import auto
```

Atuin's existing settings remain your own. This repository does not create an
account, log in, enable synchronization, or include a history database. See
[Atuin's documentation](https://docs.atuin.sh/) for history settings and optional
sync. Use a fresh shell after changing history integrations.

### zoxide: visit once, jump later

```zsh
cd "$HOME/src/my-zsh-config"
cd "$HOME"
z my-zsh
zi
```

The jump database learns from visited directories. The OMZ `z` plugin is omitted
so it does not compete with zoxide for the `z` command. Source:
[zoxide](https://github.com/ajeetdsouza/zoxide).

### fzf and Television

| Binding / command | Behavior |
| --- | --- |
| Ctrl-T | Insert a selected file path into the current command |
| Alt-C | Select a directory to change into |
| Ctrl-R | Atuin when installed; fzf's history widget can serve as the fallback |
| `tv` | Open Television explicitly; no extra keybinding is imposed |

Keeping Television manual avoids assigning several tools to the same key.
Its channels can later cover project files or other command output. Sources:
[fzf shell integration](https://github.com/junegunn/fzf#shell-integration),
[Television](https://github.com/alexpasmantier/television).

### navi: reusable commands

The native shell widget is enabled when both `navi` and `fzf` are installed.
Use Ctrl-Space or Ctrl-G, choose a recipe, fill any variables, then inspect the
inserted command before pressing Enter. Running `navi` directly has its own
selection/execution behavior; the widget is the integration intended here.

Start with `navi --help` and the
[official cheatsheet syntax](https://github.com/denisidoro/navi/blob/master/docs/cheatsheet_syntax.md)
to add recipes you actually use, such as a Go test command or a Kubernetes log
query. This repo does not ship private server names or credentials in recipes.

### tldr and command discovery

```zsh
tldr --update
tldr tar
tldr cargo
tldr git-rebase
```

`tlrc` is the package, `tldr` is the binary. The first command refreshes its
local page cache. `man COMMAND` remains useful for full option details.

## Practical development examples

### Inspect a project

```zsh
z my-project
tre .
tokei .
rg --line-number 'TODO|FIXME' .
fdfind '\.go$'
bat go.mod
```

The Debian package supplies `fdfind`; use `fd` only if you have configured that
name. `bat` is a shell alias to `batcat` when needed. Source:
[fd](https://github.com/sharkdp/fd), [bat](https://github.com/sharkdp/bat).

### Inspect an API response or report

Given an existing response file and CSV export:

```zsh
jq '.items[0]' response.json
jql '"name"' object-with-name.json
csvlens report.csv
xsv headers report.csv
xsv stats report.csv
htmlq --text title < page.html
```

`jq` and `jql` use different query languages. Do not pass a jq expression to jql
and expect identical behavior. CSVlens is convenient for exploration; xsv is
useful for a repeatable pipeline. `xsv` is retained because it is in the owner's
inventory, even though its upstream repository is archived.

### Understand a slow machine or application

```zsh
btm
dust .
dua i
ports
mylocalip
sudo "$(command -v bandwhich)"
```

The explicit `bandwhich` path matters because a root shell's PATH may not include
`~/.cargo/bin`. `ports` uses `ss`; identifying processes owned by other accounts
may require appropriate privileges. `mylocalip` displays local IPv4 addresses;
`myip` queries an external service for the public egress IP.

For a stream of logs:

```zsh
journalctl -f | spacer
```

Spacers make time gaps visible without requiring a full log analysis tool.

### Prepare a changelog

Inside a Git repository:

```zsh
git cliff
git cliff --output CHANGELOG.md
```

The first command previews. The second writes a file. Add a project-specific
`cliff.toml` when you want your own grouping and release format; see
[git-cliff configuration](https://git-cliff.org/docs/configuration/).

### Download media through APT's yt-dlp

```zsh
yt-dlp --version
yt-dlp --list-formats 'https://example.com/video'
yd 'https://example.com/video'
```

Replace the example URL with a supported media page. `yd` is only an alias for
`yt-dlp`. FFmpeg is useful for merging separate audio/video streams and
post-processing. Update APT-managed yt-dlp through APT. Source:
[yt-dlp usage](https://github.com/yt-dlp/yt-dlp#usage-and-options).

### Sherlock through APT

```zsh
sherlock --help
sherlock your-own-username
```

This checks username availability/presence according to Sherlock's supported
sites; there is no pyenv wrapper. It is a separate tool from the unrelated
`python3-sherlock` locking library. Sources:
[Sherlock](https://github.com/sherlock-project/sherlock),
[Debian package](https://packages.debian.org/sid/sherlock).

## Overlapping and older tools

### exa, eza and lsd

The inventory preserves `exa` 0.10.1. Its upstream says it is unmaintained and
points to [eza](https://github.com/eza-community/eza). The core shell uses `lsd`;
APT extras include `eza` for people who prefer it. You do not need all three.
`exa` is included only with `--legacy`, and nothing automatically uninstalls it.
Source: [exa's upstream status](https://github.com/ogham/exa).

### The Cargo btop entry

Your snapshot says `btop v0.1.0` from Cargo. That name and version alone do not
establish that it is the same implementation as the usual C++ btop resource
monitor. The installer preserves the observed crate behind `--legacy`, rather
than silently treating the two as interchangeable.

For the conventional btop monitor, Debian provides
[`btop`](https://packages.debian.org/sid/btop):

```bash
sudo apt install btop
```

If both exist, inspect the paths before choosing which to keep:

```zsh
type -a btop
cargo install --list
/usr/bin/btop --version
```

The setup gives Cargo's bin directory early PATH priority; simply installing
APT btop will not make it win over an existing Cargo `btop` binary. An explicit
`/usr/bin/btop` invocation selects Debian's copy. No removal is automated.

### xsv

[xsv's repository](https://github.com/BurntSushi/xsv) is archived. It remains in
`--all` to preserve the owner's CSV workflow, with this status documented.
Do not assume ongoing upstream fixes. Replacing it would be a separate choice,
not an invisible alias in the shared shell config.

## What is intentionally personal

Tool installation does not imply a fully configured tool. The supplied material
did not include your Atuin settings/history, navi cheatsheets, Television
channels, wallust templates, xplr Lua customization or Topgrade configuration.
This repository documents their use and installs their commands, but does not
invent those personal settings. Add files explicitly when you want to share
and maintain them.
