# Kitty: terminal, fonts, colors, and kittens

[Back to the setup guide](../README.md)

Kitty is the terminal application. Zsh runs inside it. **Kittens** are Kitty's
helper tools, launched with the `kitten` command. Debian's `kitty` package
[contains both executables](https://packages.debian.org/sid/amd64/kitty/filelist).

The repository's [Kitty configuration](../config/kitty/kitty.conf) preserves
the active settings in Erfan's uploaded file. The upload contained 3,314 lines
of generated documentation and only 15 active settings; the smaller file keeps
those choices readable. The separate color theme was not supplied.

## 1. Open Kitty after setup

The repository's `./install.sh` installs Kitty through APT, copies its config,
and installs all four MesloLGS NF font faces for your account. After setup,
check the installed programs:

```bash
kitty --version
kitten --version
```

Launch **Kitty** from your desktop's application menu. This configuration is
intended for a current Kitty release. If your distribution's version reports
unknown cursor-trail or font options, check `apt-cache policy kitty` and
[Kitty's installation instructions](https://sw.kovidgoyal.net/kitty/binary/).

On KDE, select Kitty under the default terminal setting if you want desktop
terminal shortcuts to launch it. The exact settings label can vary by Plasma
version. Hiding window decorations is part of the supplied config; set
`hide_window_decorations no` in `local.conf` if you prefer the normal title bar.

## 2. Verify MesloLGS NF

The configuration requests **MesloLGS NF**. Its name must match the installed
font family. These are the four official font files linked by
[Powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts):

- [Regular](https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf)
- [Bold](https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold.ttf)
- [Italic](https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Italic.ttf)
- [Bold Italic](https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold%20Italic.ttf)

Setup downloads these files into
`${XDG_DATA_HOME:-$HOME/.local/share}/fonts/MesloLGS-NF` and refreshes the
font cache. It preserves existing valid faces, validates every new download
with `fc-scan` before installing any of them, and backs up invalid files before
replacing them. Font backups go under
`${XDG_STATE_HOME:-$HOME/.local/state}/my-zsh-config/backups/fonts-*`.

Check what Fontconfig resolves:

```bash
fc-match "MesloLGS NF"
fc-list : family | rg 'MesloLGS NF'
```

Open a new Kitty window, then run:

```bash
kitten choose-fonts
```

Choose the family and preview its normal/bold/italic faces. The
[font chooser](https://sw.kovidgoyal.net/kitty/kittens/choose-fonts/) selects
fonts already installed on your machine; it does not download missing fonts.
If `fc-match` reports another family, check the downloaded files and rebuild
the font cache before changing prompt settings.

## 3. Find the config and select a theme

The [main installer](../README.md) copies the config with a backup of any file
it replaces. The usual destination is:

```text
~/.config/kitty/kitty.conf
```

With an explicit `XDG_CONFIG_HOME`, use `$XDG_CONFIG_HOME/kitty/kitty.conf`.
If you separately configured `KITTY_CONFIG_DIRECTORY`, ensure Kitty reads the
same directory that you installed into; that override takes precedence.

The neighboring files are local choices:

| File | Purpose |
|---|---|
| `kitty.conf` | Shared settings from this repository |
| `current-theme.conf` | Your selected color palette |
| `local.conf` | Optional overrides, loaded last |

Keep an existing `current-theme.conf` if you want to preserve your colors.
The uploaded file only referenced that filename, so this repository cannot
reproduce its unseen palette. With no theme file, Kitty's default colors apply.
The optional `globinclude` directives allow the config to load before these
local files exist.

To choose colors interactively, run this **inside Kitty**:

```bash
kitten themes
```

The [themes kitten](https://sw.kovidgoyal.net/kitty/kittens/themes/) previews
colors, writes `current-theme.conf`, and may edit `kitty.conf` to add an include.
It is safe to customize the installed copy: these files are copied by the
setup process, rather than being symlinks into the repository. Save your theme
alongside your other personal backups if you want the same colors elsewhere.

## 4. What the settings do

| Choice | Result |
|---|---|
| `font_family family="MesloLGS NF"` | The supplied font family; automatic bold/italic faces |
| `cursor_trail 200` | Trail after a cursor resting at least 200 ms moves |
| `cursor_trail_decay 0.1 0.4` | Trail fade range in seconds |
| `cursor_trail_start_threshold 2` | Minimum cursor travel threshold in cells |
| `scrollback_lines 5000` | Keep 5,000 lines of terminal scrollback |
| `mouse_hide_wait 3.0` | Hide an idle pointer after three seconds |
| `hide_window_decorations yes` | Hide the normal window title bar/border |
| Powerline tabs, round style | Rounded separators between tabs |
| `background_opacity 0.85` | 85% opaque terminal background |
| `dynamic_background_opacity yes` | Permit live opacity adjustments |

See the [official option reference](https://sw.kovidgoyal.net/kitty/conf/) for
the supported syntax. Transparency depends on the compositor, and an editor
can paint its own opaque background. A font-size choice was not present in the
upload; Kitty's default remains in use until you choose one.

For example, put the following in your installed `local.conf` if you want a
larger font and fully opaque background:

```conf
font_size 13
background_opacity 1.0
```

Edit this file with:

```bash
nvim "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/local.conf"
```

If you use `KITTY_CONFIG_DIRECTORY`, substitute that directory above.

## 5. Useful default keyboard shortcuts

These are Kitty's existing shortcuts; the shared config adds no remappings.
See the [official shortcut list](https://sw.kovidgoyal.net/kitty/overview/).

| Action | Keys |
|---|---|
| Copy / paste | Ctrl+Shift+C / Ctrl+Shift+V |
| Create a tab | Ctrl+Shift+T |
| Next / previous tab | Ctrl+Shift+Right / Ctrl+Shift+Left |
| Create a pane inside the current tab | Ctrl+Shift+Enter |
| Create a separate OS window | Ctrl+Shift+N |
| Next / previous pane | Ctrl+Shift+] / Ctrl+Shift+[ |
| Cycle layouts | Ctrl+Shift+L |
| Close the active pane | Ctrl+Shift+W |
| Increase / decrease font size | Ctrl+Shift+Equal / Ctrl+Shift+Minus |
| Restore font size | Ctrl+Shift+Backspace |
| Edit config | Ctrl+Shift+F2 |
| Reload config | Ctrl+Shift+F5 |
| Show configuration diagnostics | Ctrl+Shift+F6 |

After editing, reload the config. Open a new window if a window-level setting
does not change immediately. Scrollback size changes affect new windows.

## 6. Kittens worth trying

Run these in Kitty. The filenames and SSH destination are examples; replace
them with your own.

| Command | Use |
|---|---|
| `kitten choose-fonts` | Preview and select installed fonts |
| `kitten themes` | Browse terminal palettes |
| `kitten diff before.txt after.txt` | Compare files side by side |
| `kitten diff old-directory new-directory` | Compare directory contents |
| `kitten icat picture.png` | Display an image in the terminal |
| `kitten ssh user@hostname` | Interactive SSH with Kitty integration |

In [the diff viewer](https://sw.kovidgoyal.net/kitty/kittens/diff/), use `n` and
`p` to move between changes and `q` to quit. This command opens its own viewer;
it does not replace your Git configuration.

[Image display](https://sw.kovidgoyal.net/kitty/kittens/icat/) works directly in
Kitty; behavior inside tmux/screen depends on the multiplexer. ImageMagick
adds support for additional image formats beyond Kitty's built-in decoders.

The [SSH kitten](https://sw.kovidgoyal.net/kitty/kittens/ssh/) wraps OpenSSH and
sets up remote terminfo/shell integration. It uses your normal SSH options and
host configuration. Use it explicitly when you want that integration; an
ordinary `ssh` command remains available.

## 7. Quick troubleshooting

| Symptom | Check |
|---|---|
| Boxes instead of prompt icons | Install all font faces; confirm `fc-match "MesloLGS NF"`; reopen Kitty |
| Theme differs from Erfan's machine | Select a theme or copy your own `current-theme.conf`; the original was not included |
| Wrong config appears to load | Ctrl+Shift+F6; inspect `KITTY_CONFIG_DIRECTORY` and XDG settings |
| Missing transparency | Check compositor settings; inspect editor background colors |
| Unknown option on startup | Compare `kitty --version` with the current option documentation |
| New settings do not appear | Ctrl+Shift+F5, then a new window for window-level options |
| `kitten` is missing | Inspect `type -a kitty kitten` and `dpkg -L kitty`; ensure the package and PATH match |

Return to [Neovim and LazyVim](neovim.md) for the editor setup.
