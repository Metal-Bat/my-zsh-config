# mise: system defaults, project-specific runtimes

This setup keeps language versions out of the global mise configuration. The
only global tool is `usage`, a command-line completion helper. Choose other
tools in a project's own `mise.toml`. Python is explicitly disabled in mise.

| Where you are | Intended result |
| --- | --- |
| Home or a directory without an applicable runtime declaration | Use the commands already on your normal `PATH`. |
| A project declaring an installed Node.js or Go version | mise activates that version for the project and its subdirectories. |
| A project declaring Python | The default `disable_tools` setting makes mise ignore Python. |
| A directory you leave | At the next directory/prompt hook, mise adjusts the environment for the new location. |

"System defaults" means mise does not supply those runtimes. It does not mean
mise repairs a `PATH` changed by another version manager, an activated virtual
environment, or your terminal's parent process. The diagnostic steps below help
identify those cases.

Sources: [shell activation](https://mise.jdx.dev/shell-setup.html),
[configuration hierarchy](https://mise.jdx.dev/configuration.html#configuration-hierarchy),
and [settings reference](https://mise.jdx.dev/configuration/settings.html).

## 1. What setup installs

Run `./install.sh` from the cloned repository. It deploys the supplied mise
configuration, installs missing mise from the official standalone installer at
`https://mise.run`, and installs the `usage` helper. The new executable goes to
`~/.local/bin/mise`; an existing working mise is preserved. No extra installation
command or shell-activation line is needed.

The standalone build supports the supplied `self_update.auto` setting. Setup
uses the plain installer rather than its `/zsh` variant, because this
repository's `.zshrc` already activates mise once. The installer never appends
another activation line.

Inspect the active installation with:

```zsh
type -a mise
```

If your existing mise is APT-managed, keep using APT for its updates; package
builds can disable self-update. Set `auto = false` in `[settings.self_update]`
for that existing installation. Setup does not put a second mise ahead of a
working one.

The full setup also installs Debian's Node.js/npm, Go, Java, Python, and Python
venv support. Rust is separate: a fresh system gets the official **rustup minimal
stable** toolchain and Cargo. Working system Cargo/Rust are preserved. Existing
rustup installations gain missing `rust-src`, `rustfmt`, `clippy`, and
`rust-analyzer` components on their active toolchain. These steps add no language
runtime declaration to mise and do not install NVM or pyenv.

Sources: [mise installation and updates](https://mise.jdx.dev/installing-mise.html),
[rustup installation](https://rust-lang.github.io/rustup/installation/other.html),
and the local [runtime installer](../scripts/install-runtimes.sh).

## 2. Use the supplied global configuration

The repository's [configuration file](../config/mise/config.toml) belongs at
`${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml`. Follow the installation
steps in the [README](../README.md) to deploy it with the other dotfiles.

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

| Setting | Meaning |
| --- | --- |
| `usage = "latest"` | Select the completion helper globally. No language runtime is selected here. |
| `disable_tools = ["python"]` | Ignore Python tool declarations, including project declarations. An `enable_tools` allowlist takes precedence over this setting. |
| `activate_shims = false` | Activation excludes mise's shim directories; installed project tools still use their real `bin` directories. |
| `not_found_auto_install = false` | Typing a missing command does not trigger mise's command-not-found installer. Explicit mise install/exec/run commands have their own behavior. |
| `not_found_system_fallback = true` | An unresolved shim may use another executable on `PATH`. With shims excluded, normal shell lookup usually handles this instead. |
| `self_update.auto = true` | Eligible interactive mise commands can update mise itself. Shell activation does not trigger this update. |

Source: [current setting definitions](https://mise.jdx.dev/configuration/settings.html).

Setup installs the helper. Open a fresh terminal and verify:

```zsh
cd "$HOME"
mise config ls
mise ls --current
mise which usage
```

With only this global configuration, the selected-tools list should contain
`usage`. If Node.js, Go, or another runtime also appears, inspect the file shown
in the `Source` column. System configuration, home-directory files,
`.tool-versions`, and parent-directory configuration can also contribute tools.
Changing one file does not erase those other declarations.

Source: [how mise discovers and combines configuration](https://mise.jdx.dev/configuration.html).

## 3. Choose a project deliberately

For a new project, work inside its directory and name the destination file
explicitly. This example chooses the Node.js 24 release line and records the
resolved exact version:

```zsh
mkdir -p "$HOME/src/mise-demo"
cd "$HOME/src/mise-demo"
mise use --path ./mise.toml --pin node@24
mise ls --current
node --version
command -v node
```

`--path ./mise.toml` avoids accidentally editing an existing parent project's
configuration. `--pin` records the resolved version rather than a moving major
version request. Choose a version appropriate for your application.

Run the verification commands at a new prompt after `mise use`; activation
updates the interactive shell at its hook. For a script or an immediate command
in the same shell statement, use:

```zsh
mise exec -- node --version
```

Source: [`mise use`](https://mise.jdx.dev/cli/use.html).

For an existing project, inspect its configuration and trust that particular
file before installing:

```zsh
cd /path/to/your/project
cat mise.toml
mise trust ./mise.toml
mise install
mise ls --current
```

Trust permits configuration features that change the environment or run code.
Current mise versions allow some simple declarations without explicit trust
and automatically trust configuration for certain explicit commands. Trust is
therefore not a directory allowlist. Your runtime scope comes from where you
place configuration files; avoid a runtime declaration at `~/mise.toml` or
another parent of unrelated projects.

Sources: [`mise trust`](https://mise.jdx.dev/cli/trust.html) and
[configuration hierarchy](https://mise.jdx.dev/configuration.html#configuration-hierarchy).

Now leave the project:

```zsh
cd "$HOME"
mise ls --current
type -a node npm
```

At the new prompt, the project Node.js should no longer be selected. The normal
system commands resume if installed; otherwise `node`/`npm` can be unavailable.
This setup does not install a global fallback runtime.

Do not use `mise use --global node@...`, `go@...`, or `python@...` unless you
intentionally decide to change this policy.

## 4. Keep Python independent

Python does not require pyenv for this configuration. For an ordinary Python
project using Debian's Python, create a virtual environment explicitly:

```bash
cd /path/to/your/python-project
/usr/bin/python3 -m venv .venv
source .venv/bin/activate
python --version
deactivate
```

Setup already installs `python3-venv`. The explicit `/usr/bin/python3` selects Debian's interpreter when creating the
environment. Activating `.venv` intentionally changes command lookup until you
deactivate it. Do not globally add `.venv/bin` or PlatformIO's `penv/bin` to
`PATH`.

If you later want mise to manage Python **inside a chosen project**, remove
`"python"` from `disable_tools` in your personal global config, then add a
Python declaration only to that project's `mise.toml`. Removing the setting
also enables any Python declarations already present in other applicable
configs, so inspect `mise config ls` first. Keep global `[tools]` limited to
`usage`; do not reintroduce pyenv initialization.

Sources: [Python virtual environments](https://docs.python.org/3/library/venv.html)
and [mise's Python integration](https://mise.jdx.dev/lang/python.html).

## 5. Diagnose the command that actually runs

From home, run these commands in your current interactive Zsh:

```zsh
cd "$HOME"
mise --version
mise doctor
mise config ls
mise ls --current
type -a mise python python3 node npm go
printf 'VIRTUAL_ENV=%s\n' "${VIRTUAL_ENV-}"
printf '%s\n' "${path[@]}"
```

Interpret the output rather than deleting installations:

| Observation | What to inspect |
| --- | --- |
| `python3` resolves to `/usr/bin/python3` | The expected system interpreter is selected. |
| `python3` resolves inside `.pyenv` | An old shell startup file or inherited environment still adds pyenv. |
| `python3` resolves inside `.platformio/penv` | A PlatformIO environment or a global `PATH` edit is selecting it. |
| `VIRTUAL_ENV` names an intentional project environment | Deactivate that environment when you want the system interpreter. |
| `node` resolves inside `.nvm` | NVM still changes the shell's `PATH`; inspect its initialization. |
| `mise ls --current` shows a runtime at home | Follow its `Source` entry and remove only the unwanted global/parent declaration. |
| `PATH` contains a mise `shims` directory | Check explicit shim exports and restart after changing activation settings. |
| Project tools are missing | Run `mise install` in that project, then check again at a new prompt. |

Look for old initialization without removing files automatically:

```zsh
rg -n 'pyenv|\.pyenv|mise.*/shims|nvm|platformio.*/penv' \
  "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile" \
  "$HOME/.profile" "$HOME/.bashrc" \
  "$HOME/.config/environment.d" 2>/dev/null
```

Remove an obsolete initialization line only after identifying it. Keep
PlatformIO's own environment intact; its Python can be required by PlatformIO
even though you do not want it as your general terminal Python. If your desktop
or terminal inherited an old `PATH`, fully close and reopen the terminal;
logging out and back in may be needed for desktop session variables. Sourcing
`.zshrc` again does not reliably undo previously exported paths or hooks.

The supplied shell activates mise manually once. Do not also enable Oh My
Zsh's `mise` plugin: that plugin runs activation itself and generates
completions. Do not append a separate shims directory to `.zshenv` or
`.zprofile` for this setup.

Sources: [Oh My Zsh's mise plugin](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/mise/mise.plugin.zsh),
[shim behavior](https://mise.jdx.dev/dev-tools/shims.html), and
[mise troubleshooting](https://mise.jdx.dev/troubleshooting.html).

## 6. Update the right thing

| Command or setting | Scope |
| --- | --- |
| `mise self-update` | Standalone mise executable; also updates mise plugins unless `--no-plugins` is used. |
| `[settings.self_update] auto = true` | Periodic mise self-update before eligible interactive commands. |
| `mise upgrade usage` | Update the installed global completion helper within its `latest` request. |
| `mise upgrade` in a project | Review and update tools selected by the applicable configuration. |
| `rustup update` | Rust toolchains managed by rustup; review the resulting compiler version before rebuilding projects. |
| `sudo apt upgrade` | APT-managed packages, including mise if your existing installation came from APT. |

`latest` is a version request, not a background upgrade timer. Automatic
self-update concerns mise itself; it does not continuously update `usage` or
your project runtimes. Exact project pins need deliberate updates. Review a
project's configuration changes before committing them.

Sources: [updating mise](https://mise.jdx.dev/installing-mise.html#updating-mise)
and [`mise upgrade`](https://mise.jdx.dev/cli/upgrade.html).
