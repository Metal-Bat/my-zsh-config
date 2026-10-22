# Optional plugins for everyday development

[Back to the README](../README.md) · [Shell configuration](shell.md)

These are suggestions for a Java, TypeScript, JavaScript, Python, Go, and Rust
workflow on Debian/KDE. **They are not enabled or installed by this update.**
Choose the ones you find useful, then add them yourself.

For a first round, my picks are **`aliases`**, **`copybuffer`**, and
**`auto-notify`**: learn the shortcuts you already have, copy a command while
editing it, and receive a desktop notification when a long build finishes.
If you want only plugins bundled with Oh My Zsh, choose `magic-enter` instead
of `auto-notify`.

## At a glance

| Pick | Where it helps | Try this after enabling it |
|---|---|---|
| `aliases` | Discover Git, Docker, Go, and Kubernetes shortcuts | `als docker` |
| `copybuffer`, `copypath`, `copyfile` | Move commands, paths, and config text into another app | Ctrl+O; `copypath`; `copyfile compose.yaml` |
| `magic-enter` | See repository status or directory contents quickly | Press Enter on an empty prompt |
| `auto-notify` (external) | Know when builds/tests finish while using another window | Run a normally long `cargo build` or `go test ./...` |
| `rust` | Complete Rust compiler and toolchain commands | Type `cargo `, then Tab |
| `mvn` / `gradle` | Java completion and project-wrapper convenience | `mvnt`; `gradle test` |
| `npm` | JS/TS project scripts and completion | `npmrd`; `npmrb`; `npmt` |
| `python` | Explicit Python commands and virtual environments | `mkv .venv` to create/activate; `vrun .venv` to activate it later |
| `gitignore` | Start a repository's ignore rules from known templates | `gi go,linux,vim` |

The existing configuration already includes `git`, `golang`, `docker`,
`docker-compose`, `kubectl`, `helm`, and `jsontools`. Those remain the foundation;
the suggestions above add different conveniences.

## How to enable your choices

This repository loads an optional file **before Oh My Zsh starts**:

```text
~/.config/zsh/plugins.zsh
```

With `XDG_CONFIG_HOME` set, the location is `$XDG_CONFIG_HOME/zsh/plugins.zsh`.
Create or edit it:

```zsh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
nvim "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.zsh"
```

For example, to try just two bundled plugins, put this in the file:

```zsh
MYZSH_EXTRA_PLUGINS=(aliases copybuffer)
```

Keep one array and add your chosen names to it. Names are separated by spaces,
with no commas. This adds to the repository's shared plugin list. A plugin that
is not installed is skipped; `auto-notify` needs the separate clone below.

Open a new terminal, or run `exec zsh`, after editing. Inspect loaded names with
`print -rl -- $plugins`. Removing a name from your extra array and starting a
fresh shell disables that optional plugin.

Put plugin options needed at startup in `plugins.zsh` too. Use `local.zsh` for
aliases and keybindings you want to apply after the shared configuration.

## 1. aliases: a searchable cheatsheet for your actual shell

You already load many useful shortcuts. This plugin makes them discoverable:

```zsh
als
als git
als docker
als kubectl
als --groups
```

The current command is **`als`**. It groups the aliases available in your
session and can filter by a keyword. It complements `you-should-use`: one
lets you explore deliberately; the other reminds you while you work.

It uses `python3` from PATH, so your system Python is sufficient. It does not
require pyenv or a mise-managed interpreter.

Source: [Oh My Zsh aliases](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/aliases/README.md)
and [implementation](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/aliases/aliases.plugin.zsh).

## 2. Clipboard helpers: especially useful with a desktop editor or browser

Enable any of these independently:

| Plugin | What is copied | Example |
|---|---|---|
| `copybuffer` | The command you are currently editing | Type a long `kubectl` command and press Ctrl+O before executing it |
| `copypath` | An absolute path | `copypath ./src/main.go`, or `copypath` for the current directory |
| `copyfile` | A file's contents | `copyfile compose.yaml` |

For KDE **Wayland**, install the clipboard helper:

```bash
sudo apt install wl-clipboard
```

For an **X11** session, install `xclip` instead:

```bash
sudo apt install xclip
```

`printf '%s\n' "$XDG_SESSION_TYPE"` usually identifies the session type.
Oh My Zsh detects the available clipboard backend. Ctrl+O copies the edited
buffer; it does not execute the command. These shortcuts do not take over
Atuin's Ctrl+R or Navi's Ctrl+G/Ctrl+Space.

Sources: [copybuffer](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/copybuffer/README.md),
[copypath](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/copypath/README.md),
[copyfile](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/copyfile/README.md),
and [clipboard backends](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh).

## 3. magic-enter: useful information from an empty prompt

Pressing Enter on an empty prompt runs Git status inside a Git working tree,
or a directory listing elsewhere. A command you have typed still runs normally.

If you prefer compact status, add these options to `plugins.zsh` alongside
your chosen extra plugin names:

```zsh
MAGIC_ENTER_GIT_COMMAND='git status --short --branch'
MAGIC_ENTER_OTHER_COMMAND='ls -lh .'
```

You can use `lsd -lh .` for the second command if `lsd` is installed. This
changes the meaning of an empty Enter press, so choose it if that behavior
suits you.

Source: [Oh My Zsh magic-enter](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/magic-enter/README.md).

## 4. auto-notify: desktop notifications for long builds

This is an external plugin, compatible with Oh My Zsh. It is useful for
Cargo builds, Go tests, Maven builds, or frontend builds that you leave running
while working elsewhere. Linux support uses `notify-send` on X11 or Wayland.

If you choose it, install the helper and clone the plugin once:

```zsh
sudo apt install libnotify-bin
auto_notify_dir="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/auto-notify"
if [[ -e "$auto_notify_dir" || -L "$auto_notify_dir" ]]; then
  print -r -- "Already exists; inspect before changing it: $auto_notify_dir"
else
  mkdir -p "${auto_notify_dir:h}"
  git clone --depth=1 https://github.com/MichaelAquilina/zsh-auto-notify.git "$auto_notify_dir"
fi
```

Add **`auto-notify`** to your `MYZSH_EXTRA_PLUGINS` array. Put this threshold in
the same `plugins.zsh` file to notify only after commands exceed 30 seconds:

```zsh
export AUTO_NOTIFY_THRESHOLD=30
```

The plugin's upstream default is 10 seconds. Notifications can show command
text, elapsed time, and exit status; its documentation explains customization.
Use `disable_auto_notify` and `enable_auto_notify` to pause/resume it for the
current shell. A working desktop notification session is required.

This separately cloned plugin can be updated deliberately with:

```zsh
git -C "${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/auto-notify" pull --ff-only
```

Source: [zsh-auto-notify](https://github.com/MichaelAquilina/zsh-auto-notify).

## 5. rust: Rust and Cargo completion

The `rust` plugin adds completion for `rustc`, `cargo`, and `rustup` when the
toolchain is installed. Try Tab after `cargo ` or `rustup ` to discover options.
It is a completion convenience; it does not select a new global Rust version.

Your many Cargo-installed utilities do not automatically imply this OMZ plugin
is enabled. If completion already works well, this addition may be unnecessary.

Source: [Oh My Zsh rust](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/rust/README.md).

## 6. mvn or gradle: pick the build tool your Java projects use

| Plugin | Useful commands | Behavior to know |
|---|---|---|
| `mvn` | `mvnt` = tests; `mvncv` = clean verify; `mvndt` = dependency tree | `mvn` prefers a project Maven wrapper when found |
| `gradle` | `gradle test`; `gradle build` | `gradle` uses the project's `gradlew` when available, including from subdirectories |

These wrappers help a project use its declared build-tool version. They do not
choose its JDK: keep Java version selection in your existing system or project
mise configuration. The changed wrapper behavior is part of these plugins;
if you only want the external executable, `command mvn` or `command gradle`
bypasses a shell function/alias.

Sources: [mvn](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/mvn/README.md)
and [gradle](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/gradle/README.md).

## 7. npm: shorter JS/TS project commands

For npm-based projects, the `npm` plugin supplies completion and shortcuts:

| Shortcut | Runs |
|---|---|
| `npmrd` | `npm run dev` |
| `npmrb` | `npm run build` |
| `npmt` | `npm test` |
| `npmR lint` | `npm run lint` |
| `npmO` | `npm outdated` |

It uses whichever npm your current PATH selects. Add it when npm is part of
your workflow; it does not require enabling the `nvm` plugin.

**If you use Yarn instead:** the bundled `yarn` plugin is another option. Put
`zstyle ':omz:plugins:yarn' global-path no` in `plugins.zsh` to avoid its optional
global-bin PATH modification. For Yarn 2+, also use
`zstyle ':omz:plugins:yarn' berry yes`. The `yd` shortcut collides with this
repository's `yt-dlp` shortcut: here `yd` remains `yt-dlp`, so use `yarn dev`
explicitly or give it your own name in `local.zsh`.

Sources: [npm](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/npm/README.md)
and [yarn](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/yarn/README.md).

## 8. python: manual virtual environments without pyenv

The `python` plugin gives useful aliases and explicit venv helpers:

```zsh
py --version
mkv .venv
python -m pip --version
deactivate
```

`py` calls `python3` when no existing `py` executable is present. `mkv` creates
and activates the environment. On a later visit, `vrun .venv` activates the
existing environment. Add these preferences to `plugins.zsh`:

```zsh
PYTHON_VENV_NAME='.venv'
PYTHON_AUTO_VRUN=false
```

Automatic activation is an optional feature of this plugin. Keeping it off
fits this repository's explicit runtime choices. Activating `.venv` yourself
temporarily selects that environment's Python; `deactivate` returns to the
previous environment. Debian may require `sudo apt install python3-venv` to
create environments.

Source: [Oh My Zsh python](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/python/README.md).

## 9. gitignore: starting templates for new repositories

Use `gi list` to see supported templates, then request a combination:

```zsh
gi go,linux,vim
```

Review the output before adding it to your project's `.gitignore`. Once you
are happy with it, `gi go,linux,vim >> .gitignore` appends it without truncating
existing rules. Running that append repeatedly duplicates the rules. The
plugin uses `curl` to fetch templates from gitignore.io, so it needs a network
connection. Generated rules are a starting point for your project's choices.

Source: [Oh My Zsh gitignore](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/gitignore/README.md).

## Separate terminal programs worth considering

These are standalone programs, not OMZ plugin names. They are also optional
and have not been added to the install manifests.

| Program | Why it fits this workflow | First use |
|---|---|---|
| [lazygit](https://github.com/jesseduffield/lazygit) | A terminal interface for staging, commits, branches, and reviewing changes across all six languages | Run `lazygit` inside a Git repository |
| [delta](https://github.com/dandavison/delta) | A readable diff pager with syntax highlighting and side-by-side display | Try `git diff --color=never \| delta --side-by-side` |
| [bacon](https://dystroy.org/bacon/) | Watch Rust source changes and keep compiler/test results visible alongside Neovim | Run `bacon` in a Rust project; `bacon test` watches tests |
| [just](https://github.com/casey/just) | Give projects consistent commands such as `just test` and `just dev`, regardless of language | Add project recipes, then use `just --list` |

My first standalone addition would be **lazygit** for general development, or
**bacon** if you spend most of your day in Rust. `just` is useful when a team
wants a shared task file; mise also supports tasks, so choose the convention
you want to maintain before adopting another task runner.

## Keep the setup understandable

Add a few choices, use them for a while, and keep the ones that save you work.
Use `als`, `alias NAME`, `type -a COMMAND`, and `bindkey` to inspect what changed.
Atuin already owns searchable history, zoxide owns directory jumping, mise
owns project tool selection, and one highlighter is loaded last. Those existing
roles make it easier to evaluate any future plugin before adding another
integration for the same feature.
