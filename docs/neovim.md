# Neovim in /opt, with LazyVim

[Back to the setup guide](../README.md)

Run `./install.sh` from the cloned repository to install this editor setup with
the rest of the terminal stack. On a fresh machine, you get the official
**Neovim Linux x86_64 build**, **LazyVim**, and language support for **Java,
TypeScript, JavaScript, Python, Go, and Rust**. The installer waits for the
plugins, language tools, and syntax parsers to finish downloading.

A working Neovim at `/opt/nvim-linux-x86_64` is preserved. An existing Neovim
configuration is also preserved, including a configuration directory that is
a symlink. Erfan's personal LazyVim files were not supplied, so fresh installs
use the [official LazyVim starter](https://github.com/LazyVim/starter) with the
language extras described below.

## 1. What happens automatically

The [editor installer](../scripts/install-neovim.sh) runs after APT, Rust/Cargo,
and the Cargo utility list have finished. It performs these steps:

1. Check Linux x86_64 and the required download/build tools.
2. Keep the working `/opt/nvim-linux-x86_64/bin/nvim` executable. If it is
   missing or cannot run, resolve the latest stable release from the official
   GitHub API and download that exact version's archive.
3. Verify the archive against the release asset's SHA-256 digest, reject
   escaping paths, escaping links, and unsupported archive entries, then test
   the extracted binary before changing `/opt`.
4. Stage the installation beside its destination. If a nonworking old target
   exists, keep it as `/opt/nvim-linux-x86_64.backup.TIMESTAMP.PID` and restore it
   if the final move fails.
5. Keep existing editor configuration. If none exists, clone the official
   starter, enable the five extras covering six languages, and bootstrap it
   headlessly for the current user.

Only the `/opt` installation operations use sudo. Editor configuration,
plugins, Mason packages, parsers, and logs are owned by your normal account.
Neovim is never launched with sudo by the setup.

The checksum protects against an incomplete or mismatched download; it comes
from GitHub's release metadata over HTTPS. It is not a separate publisher
signature. An absent or invalid digest stops setup before an unchecked binary
is installed. See [Neovim's installation reference](https://github.com/neovim/neovim/blob/master/INSTALL.md#linux)
and [release assets](https://docs.github.com/en/rest/releases/assets).

## 2. Check the result

Open a fresh Zsh terminal:

```zsh
type -a nvim
nvim --version
tree-sitter --version
nvim
```

The first executable should be `/opt/nvim-linux-x86_64/bin/nvim`. The shell
adds that directory to PATH when present. If a previous command location is
cached, run `rehash`; use `type -a nvim` to expose aliases or functions that
might select another command.

Type commands beginning with `:` **inside Neovim**, then press Enter:

```vim
:LazyHealth
:checkhealth
:echo stdpath('config')
```

The standard config directory is `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`.
The installer uses the standard `nvim` application name. If you export
`NVIM_APPNAME` yourself, an interactive `nvim` can load another configuration;
`:echo stdpath('config')` tells you which one you are actually using.

The [current LazyVim requirements](https://www.lazyvim.org/) include Neovim
0.11.2 or newer with LuaJIT. Fresh binary installs use the current stable
release. A working older binary is preserved; the installer reports the
incompatibility instead of silently replacing it when a fresh starter needs a
newer version. Requirements evolve, so check upstream before updating an
existing installation.

## 3. Languages installed in the fresh starter

The starter's `lazyvim.json` records these official extras. TypeScript and
JavaScript share one extra, giving five entries for six languages.

| Language | LazyVim extra | Installed editing tools |
|---|---|---|
| Java | `lang.java` | `jdtls` language server |
| TypeScript and JavaScript | `lang.typescript` | `vtsls` language server; JavaScript, TypeScript, and TSX parsers |
| Python | `lang.python` | `pyright` type/language server and `ruff` diagnostics/formatting |
| Go | `lang.go` | `gopls`, `goimports`, and `gofumpt` |
| Rust | `lang.rust` | `rust-analyzer`, Rust parser, and the `codelldb` debugger adapter |

Baseline Lua and shell tools include `lua-language-server`, `stylua`, and
`shfmt`. The bootstrap also installs the starter's current default Mason tools
and Tree-sitter parsers. The exact default list can change upstream; explicit
language tools above are checked before setup reports success.

Sources: [Java](https://www.lazyvim.org/extras/lang/java),
[TypeScript](https://www.lazyvim.org/extras/lang/typescript),
[Python](https://www.lazyvim.org/extras/lang/python),
[Go](https://www.lazyvim.org/extras/lang/go), and
[Rust](https://www.lazyvim.org/extras/lang/rust).

These editor tools have supporting runtime requirements. Setup installs
Debian's Node.js/npm, Java development kit, Go, Python/venv support, and C build
tools. Missing Rust/Cargo comes from rustup; `tree-sitter-cli` is installed
through the Cargo manifest. A recent Java runtime is especially important:
[current JDT LS requires Java 21 or newer](https://github.com/eclipse-jdtls/eclipse.jdt.ls#requirements).
An old `JAVA_HOME` can still override the installed system Java, so inspect it
if Java completion fails.

Mason stores its tools inside Neovim's data directory and adds their executable
directory to the editor's environment. It does not put Python into mise or
change the terminal's global runtime policy. For a project with an explicitly
selected mise runtime, enter that project **before** starting Neovim so the
editor inherits its PATH. Python projects can use a normal `.venv` created with
`/usr/bin/python3 -m venv .venv`; see [the mise guide](mise.md).

Installing language support does not create your application's dependencies,
Java build files, Python virtual environment, or Rust/Go project. Open the
project root and follow that project's own build instructions. Debugger UI
extras beyond the Rust setup are available through `:LazyExtras` when needed.

## 4. Completion, logs, and retries

The [bootstrap helper](../scripts/bootstrap-lazyvim.lua) waits for lazy.nvim
plugin tasks, Mason package installations, and configured Tree-sitter parsers.
It returns an error when any requested install fails or times out. The whole
headless editor phase has a 30-minute limit; slow or interrupted downloads can
be resumed on the next run.

Detailed logs live at:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config/logs/lazyvim-bootstrap-*.log
```

A fresh starter has a `.my-zsh-config-bootstrap` marker. Its value stays
`my-zsh-config:pending:v1` until installation has completed, then changes to
`my-zsh-config:ready:v1`. If setup stops during downloads, correct the reported
network or dependency problem and rerun the same command from the repository:

```bash
./install.sh
```

The pending starter is resumed without rewriting its configuration. A normal
pre-existing configuration without this pending marker is left alone. An
already completed starter is also left alone on subsequent runs.

If a language tool fails, inspect `:MasonLog`; parser failures appear in
`:TSLog`. Failures commonly come from network restrictions, a missing compiler,
or an old inherited runtime. Check the actual commands Neovim sees:

```vim
:echo exepath('node')
:echo exepath('go')
:echo exepath('java')
:echo exepath('tree-sitter')
```

The scripts follow current LazyVim, Mason, and Tree-sitter APIs rather than
pinning a frozen editor distribution. Future incompatible upstream changes
can require a bootstrap update. The helper stops on missing APIs or failed
installs, and keeps the starter and log for diagnosis.

## 5. Plugins, extras, and language tools

| Neovim command | Purpose |
|---|---|
| `:LazyExtras` | Browse curated language and feature bundles |
| `:Lazy` | Inspect plugins and their installation/update status |
| `:Lazy sync` | Install missing plugins, remove unused ones, and update plugins |
| `:LazyHealth` | Load LazyVim plugins and check the setup |
| `:checkhealth` | Neovim's general health report |
| `:Mason` | Browse external language servers, formatters, and debugging tools |
| `:MasonLog` | Inspect external-tool installation failures |
| `:TSLog` | Inspect Tree-sitter parser installation output |

For “install something from the LazyVim store,” open **`:LazyExtras`**. The
fresh starter already enables the six languages above; select another extra
only when you need its feature and restart when requested. Existing personal
configs can use the same menu to add language bundles without replacement.

**LazyVim extras** configure editor features. **lazy.nvim**, opened by `:Lazy`,
installs the plugins. **Mason**, opened by `:Mason`, installs their external
tools. Installing a language server in Mason alone does not configure its
editor integration; the appropriate extra provides that configuration.

See [LazyVim extras](https://www.lazyvim.org/extras),
[lazy.nvim commands](https://lazy.folke.io/usage), and
[Mason's documentation](https://github.com/mason-org/mason.nvim).

## 6. Where to customize LazyVim

These paths are relative to `~/.config/nvim`, or your XDG config equivalent:

| File or directory | Put this here |
|---|---|
| `lua/config/options.lua` | Editor options, indentation, and the selected Python/TypeScript server |
| `lua/config/keymaps.lua` | Your global keyboard shortcuts |
| `lua/config/autocmds.lua` | Commands triggered by editor events |
| `lua/plugins/*.lua` | Plugin specifications and option overrides |
| `lazyvim.json` | Extras selected by LazyVim |
| `lazy-lock.json` | Plugin versions recorded by lazy.nvim |

Edit your configuration rather than downloaded plugin files under
`~/.local/share/nvim/lazy`. LazyVim [loads these files](https://www.lazyvim.org/configuration)
at the appropriate time; read [plugin configuration](https://www.lazyvim.org/configuration/plugins)
before adding or replacing a plugin. The starter's upstream Git metadata is
retained by setup; replace that origin deliberately before publishing it as
your own configuration repository.

For your first session, `i` enters insert mode, Escape returns to normal mode,
`:w` saves, and `:q` quits. Press Space in normal mode to discover LazyVim's
leader-key menu. The [keymap reference](https://www.lazyvim.org/keymaps) lists
the defaults. `Space f f` finds files and `Space /` searches project text in
the default setup.

## 7. Updates and recovery

| Component | Update path |
|---|---|
| Neovim under `/opt` | Deliberately update from [official releases](https://github.com/neovim/neovim/releases) after reading release notes; normal setup preserves a working binary |
| LazyVim and Neovim plugins | `:Lazy`, or `:Lazy update` |
| Mason-installed tools | `:Mason`; inspect the selected tool's available actions |
| Tree-sitter parsers | `:TSUpdate` after a plugin update |
| Cargo `tree-sitter-cli` | The repository's Cargo update workflow |
| System dependencies | Your normal APT update/upgrade workflow |

After updating, run `:LazyHealth` and open a real project. Check file finding,
search, highlighting, diagnostics, formatting, and clipboard for the languages
you use. An executable successfully installing is only the first check;
project-specific settings still need a real project to verify.

If setup replaced a nonworking `/opt` target, keep the printed backup directory
until you are satisfied with the replacement. To restore it, close Neovim,
move the new target aside, and move the selected backup to
`/opt/nvim-linux-x86_64`. The installer never deletes these backups or your
existing editor configuration.
