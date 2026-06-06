if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH=$PATH:/var/lib/flatpak/exports/bin:$HOME/.local/share/flatpak/exports/bin
export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export NVM_DIR="$HOME/.nvm"
export GOPATH="$HOME/.go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$GOBIN"
export SCRIPT_PATH="$HOME/.scripts"
export MISE_PATH="$HOME/.local/bin/mise"
export ZSH_PLUGIN_PATH="$ZSH/custom/plugins"
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_VERSIONS="$PYENV_ROOT/versions"

command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init -)"
eval "$(zoxide init zsh)"
eval "$($MISE_PATH activate zsh)"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    ansible
    colored-man-pages
    colorize
    debian
    dirhistory
    docker
    docker-compose
    docker-helpers
    emoji
    encode64
    extract
    fast-syntax-highlighting
    git
    git-flow-completion
    golang
    hacker-quotes
    helm
    history
    httpie
    jsontools
    kubectl
    man
    mise
    ohmyzsh-full-autoupdate
    pyenv
    ssh
    sudo
    tldr
    thefuck
    tt
    vscode
    web-search
    you-should-use
    yt-dlp
    z
    zsh-256color
    zsh-autosuggestions
    zsh-bat
    zsh-fzf-history-search
    zsh-history-substring-search
    zsh-interactive-cd
    zsh-lsd
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
source $ZSH_PLUGIN_PATH/zsh-navi-plugin/zsh-navi-plugin.zsh
source $ZSH_PLUGIN_PATH/ssh-connect/ssh-connect.sh
source $ZSH_PLUGIN_PATH/zsh-histdb/sqlite-history.zsh

bindkey '^ ' navi_widget
autoload -Uz add-zsh-hook

alias l="lsd -Alhi --blocks permission,user,group,inode,date,name"
alias mylocalip="ip -f inet -o -c a | cut -d ' ' -f 2,7 | cut -d '/' -f 1 | cowsay -n -f ghostbusters | lolcat -a --duration=3"
alias myip="curl -sS showip.net | cowsay -n -f ghostbusters | lolcat -a --duration=3"
alias today_fortune="fortune | boxes -d nuke -a c"
alias bat="batcat"
alias wttr="curl wttr.in/Tehran"
alias kctx="kubectx"
alias kns="kubens"
alias untar="tar -zxvf "
alias www="python3 -m http.server"
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'
alias ports="netstat -tlnp"
alias mnt="mount | awk -F' ' '{ printf \"%s\t%s\n\",\$1,\$3; }' | column -t | egrep ^/dev/ | sort"

alias flutter="$HOME/.flutter/bin/flutter"
alias v2rayN="sudo /opt/v2rayN/v2rayN"

alias fplay="$SCRIPT_PATH/.fplay.sh"
alias q-download="$SCRIPT_PATH/.q-downloader.sh"
alias rmf="$SCRIPT_PATH/rename-files.py"

alias beet="$PYENV_VERSIONS/qobuz-dl/bin/beet"
alias qobuz-dl="$PYENV_VERSIONS/qobuz-dl/bin/qobuz-dl"
alias commit="$PYENV_VERSIONS/commitizen/bin/cz commit"
alias yd="$PYENV_VERSIONS/youtube-dl/bin/youtube-dl"
alias youtube-dl="$PYENV_VERSIONS/youtube-dl/bin/youtube-dl"
alias sherlock="$PYENV_VERSIONS/sherlock/bin/sherlock"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

. "$HOME/.cargo/env"
. "$HOME/.local/bin/env"

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
