# My Debian KDE Development Environment

A reproducible Debian KDE workstation configuration built from a minimal Debian installation.

## Features

* Debian (Net Install)
* KDE Plasma Desktop
* Zsh as default shell
* Oh My Zsh
* Powerlevel10k theme
* Large collection of productivity plugins
* Docker tooling
* Kubernetes tooling
* Development utilities
* Better shell history and autocompletion
* Syntax highlighting
* FZF integration


## 1. Install Debian

Download Debian NetInstall ISO and perform a minimal installation.

During installation:

* Install SSH Server (optional)
* Do not install additional desktop environments

Reboot after installation.

---

## 2. Install KDE Plasma

```bash
sudo apt update
sudo apt install tasksel
sudo tasksel install kde-desktop
```

Reboot.

---

## 3. Install Base Packages

```bash
sudo apt update

sudo apt install -y \
    git \
    curl \
    wget \
    vim \
    zsh \
    fzf \
    bat \
    eza \
    jq \
    htop \
    unzip \
    zip \
    ripgrep \
    fd-find \
    tmux
```

---

## 4. Set Zsh as Default Shell

```bash
chsh -s $(which zsh)
```

Log out and back in.

---

## 5. Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

## 6. Install Powerlevel10k

```bash
git clone --depth=1 \
https://github.com/romkatv/powerlevel10k.git \
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

Set theme:

```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

Run:

```bash
p10k configure
```

---

## 7. Clone This Repository

```bash
git clone https://github.com/Metal-Bat/my-zsh-config.git

cd my-zsh-config
```

---

## 8. Install Plugins

Run:

```bash
./install-plugins.sh
```

---

## 9. Install Configuration

```bash
cp .zshrc ~/.zshrc
```

or create symlinks:

```bash
ln -sf "$(pwd)/.zshrc" ~/.zshrc
```

---

## 10. Reload Shell

```bash
source ~/.zshrc
```

---

# Included Plugins

| Plugin                       | Purpose                           |
| ---------------------------- | --------------------------------- |
| zsh-autosuggestions          | Fish-like suggestions             |
| zsh-syntax-highlighting      | Syntax highlighting               |
| fast-syntax-highlighting     | Faster highlighting               |
| zsh-history-substring-search | History search                    |
| zsh-fzf-history-search       | FZF history search                |
| zsh-bat                      | Better cat output                 |
| zsh-256color                 | Better terminal colors            |
| colorize                     | Syntax highlighting for files     |
| docker-helpers               | Docker shortcuts                  |
| git-flow-completion          | Git Flow completion               |
| gitignore.plugin.zsh         | Generate .gitignore files         |
| hacker-quotes                | Random hacker quotes              |
| OhMyZsh-full-autoupdate      | Automatic updates                 |
| ssh-connect                  | SSH helper                        |
| zsh-you-should-use           | Alias suggestions                 |
| yt-dlp plugin                | yt-dlp integration                |
| zsh-auto-notify              | Notifications after long commands |
| zsh-histdb                   | SQLite-backed history             |
| zsh-navi-plugin              | Navi integration                  |

---

# Useful Tools

* Git
* Docker
* Kubernetes
* Helm
* Mise
* FZF
* Bat
* Eza
* Ripgrep

---

# Updating

```bash
omz update
```

Update plugins:

```bash
git pull
```

---

# License

MIT

---

# install-plugins.sh

```bash
#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

mkdir -p "$ZSH_CUSTOM/plugins"

plugins=(
"https://github.com/MichaelAquilina/zsh-auto-notify.git"
"https://github.com/zpm-zsh/colorize.git"
"https://github.com/unixorn/docker-helpers.zshplugin"
"https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
"https://github.com/bobthecow/git-flow-completion"
"https://github.com/voronkovich/gitignore.plugin.zsh"
"https://github.com/oldratlee/hacker-quotes.git"
"https://github.com/Pilaton/OhMyZsh-full-autoupdate.git"
"https://github.com/gko/ssh-connect"
"https://github.com/MichaelAquilina/zsh-you-should-use.git"
"https://github.com/clavelm/yt-dlp-omz-plugin.git"
"https://github.com/chrissicool/zsh-256color"
"https://github.com/zsh-users/zsh-autosuggestions"
"https://github.com/fdellwing/zsh-bat.git"
"https://github.com/joshskidmore/zsh-fzf-history-search"
"https://github.com/larkery/zsh-histdb"
"https://github.com/zsh-users/zsh-history-substring-search"
"https://github.com/icatalina/zsh-navi-plugin.git"
"https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

for repo in "${plugins[@]}"; do
    name=$(basename "$repo" .git)

    if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
        git clone "$repo" "$ZSH_CUSTOM/plugins/$name"
    else
        echo "Already installed: $name"
    fi
done

echo
echo "All plugins installed."
```
