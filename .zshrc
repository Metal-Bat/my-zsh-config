# Interactive Zsh configuration. Installation and usage: docs/shell.md.
[[ -o interactive ]] || return

# Keep Powerlevel10k's instant prompt near the top. It is generated locally.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 1. Paths before integrations. Deduplicate without replacing inherited PATH.
typeset -U path PATH
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
export GOPATH="${GOPATH:-$HOME/.go}"
export GOBIN="${GOBIN:-$GOPATH/bin}"
path=("$HOME/.local/bin" "${CARGO_HOME:-$HOME/.cargo}/bin" "$GOBIN" $path)
path+=(/var/lib/flatpak/exports/bin "$HOME/.local/share/flatpak/exports/bin")
if [[ -x /opt/nvim-linux-x86_64/bin/nvim ]]; then
  path=(/opt/nvim-linux-x86_64/bin $path)
fi
# Respect an explicitly active virtual environment inherited from the parent.
if [[ -n ${VIRTUAL_ENV:-} && -d "$VIRTUAL_ENV/bin" ]]; then
  path=("$VIRTUAL_ENV/bin" $path)
fi
export PATH

# 2. Basic shell behavior also works before Oh My Zsh has been installed.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
bindkey -e
PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f %# '

# Do updates deliberately with `omz update` and scripts/install-plugins.sh.
zstyle ':omz:update' mode disabled
ZSH_THEME=''
if [[ -r "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  ZSH_THEME='powerlevel10k/powerlevel10k'
fi

# 3. Select only installed plugins. Missing optional plugins stay quiet.
# mise, z, fzf-history and the second syntax highlighter are deliberately absent.
typeset -ga MYZSH_EXTRA_PLUGINS
[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.zsh" ]] && \
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins.zsh"
typeset -U plugins
plugins=()
for _myzsh_plugin in \
  ansible colored-man-pages colorize debian dirhistory docker docker-compose \
  emoji encode64 extract git golang helm history httpie jsontools kubectl \
  man ssh sudo tldr thefuck vscode web-search \
  docker-helpers git-flow-completion zsh-256color you-should-use \
  zsh-autosuggestions zsh-history-substring-search "${MYZSH_EXTRA_PLUGINS[@]}"; do
  # This upstream plugin prints an error instead of quietly skipping itself.
  [[ $_myzsh_plugin == thefuck ]] && (( ! $+commands[thefuck] )) && continue
  if [[ -r "$ZSH_CUSTOM/plugins/$_myzsh_plugin/$_myzsh_plugin.plugin.zsh" ||
        -r "$ZSH_CUSTOM/plugins/$_myzsh_plugin/_$_myzsh_plugin" ||
        -r "$ZSH/plugins/$_myzsh_plugin/$_myzsh_plugin.plugin.zsh" ||
        -r "$ZSH/plugins/$_myzsh_plugin/_$_myzsh_plugin" ]]; then
    plugins+=("$_myzsh_plugin")
  fi
done
unset _myzsh_plugin

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
fi

# 4. Portable aliases. Executable paths come from PATH, never an old pyenv env.
if (( $+commands[batcat] && ! $+commands[bat] )); then
  alias bat='batcat'
fi
if (( $+commands[lsd] )); then
  alias l='lsd -Alhi --blocks permission,user,group,inode,date,name'
  alias ll='lsd -lh'
  alias la='lsd -A'
else
  alias l='ls -Alh'
  alias ll='ls -lh'
  alias la='ls -A'
fi
(( $+commands[yt-dlp] )) && alias yd='yt-dlp'
(( $+commands[kubectx] )) && alias kctx='kubectx'
(( $+commands[kubens] )) && alias kns='kubens'
(( $+commands[ss] )) && alias ports='ss -tulpn'
(( $+commands[findmnt] )) && alias mnt='findmnt --real'
alias untar='tar -xzvf'
alias now='date +"%T"'
alias nowtime='now'
alias nowdate='date +"%d-%m-%Y"'
if (( $+commands[nvim] )); then
  export EDITOR="${EDITOR:-nvim}"
  export VISUAL="${VISUAL:-nvim}"
fi
if (( $+commands[python3] )); then
  # Local preview: `www 8000`, then open http://localhost:8000.
  alias www='python3 -m http.server --bind 127.0.0.1'
fi
if (( $+commands[ip] )); then
  function mylocalip() { command ip -brief -4 address show; }
fi
if (( $+commands[curl] )); then
  function myip() {
    command curl --fail --silent --show-error --connect-timeout 5 --max-time 10 \
      https://api.ipify.org && print
  }
  function wttr() {
    local city="${1:-${WEATHER_CITY:-Tehran}}"
    command curl --fail --silent --show-error --connect-timeout 5 --max-time 15 \
      --globoff "https://wttr.in/${city// /+}"
  }
fi
if (( $+commands[fortune] )); then
  function today_fortune() {
    if (( $+commands[boxes] )); then
      command fortune | command boxes -d nuke -a c
    else
      command fortune
    fi
  }
fi

# 5. One owner per integration. None of these commands installs anything.
# The native fzf integration needs fzf >= 0.48; older Debian builds use files.
if (( $+commands[fzf] )); then
  if _myzsh_fzf_init="$(command fzf --zsh 2>/dev/null)"; then
    eval "$_myzsh_fzf_init"
  else
    for _myzsh_fzf_dir in /usr/share/fzf /usr/share/doc/fzf/examples; do
      if [[ -r "$_myzsh_fzf_dir/key-bindings.zsh" ]]; then
        source "$_myzsh_fzf_dir/key-bindings.zsh"
        [[ -r "$_myzsh_fzf_dir/completion.zsh" ]] && source "$_myzsh_fzf_dir/completion.zsh"
        break
      fi
    done
    unset _myzsh_fzf_dir
  fi
  unset _myzsh_fzf_init
fi

(( $+commands[zoxide] )) && eval "$(command zoxide init zsh)"
(( $+commands[mise] )) && eval "$(command mise activate zsh)"

# Atuin owns Ctrl-R; it leaves Up/Down and '?' to the shell.
if (( $+commands[atuin] )); then
  eval "$(command atuin init zsh --disable-up-arrow --disable-ai)"
fi
if (( $+functions[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^[OA' history-substring-search-up
  bindkey '^[OB' history-substring-search-down
fi

# Navi's native widget inserts a command for review. It also binds Ctrl-G.
if (( $+commands[navi] && $+commands[fzf] )); then
  eval "$(command navi widget zsh)"
  (( $+widgets[_navi_widget] )) && bindkey '^ ' _navi_widget
fi

# Optional helper from scripts/install-plugins.sh --extras.
if [[ -r "$ZSH_CUSTOM/plugins/ssh-connect/ssh-connect.sh" &&
      -r "$ZSH_CUSTOM/plugins/ssh-connect/listbox/listbox.sh" ]]; then
  source "$ZSH_CUSTOM/plugins/ssh-connect/ssh-connect.sh"
fi

# 6. Existing personal prompt and private machine-specific customization.
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh" ]] && \
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh"

# Load exactly one syntax highlighter after widgets and personal bindings.
if [[ -r "$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi
