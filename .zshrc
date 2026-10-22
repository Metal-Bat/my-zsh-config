# Interactive Zsh configuration. Installation and usage: docs/shell.md.
[[ -o interactive ]] || return

# The requested quote plugin may print on login; do that before instant prompt.
_myzsh_quotes="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/hacker-quotes/hacker-quotes.plugin.zsh"
if [[ -t 1 && -r "$_myzsh_quotes" && -z ${_MYZSH_HACKER_QUOTE_SHOWN:-} ]]; then
  source "$_myzsh_quotes"
  typeset -g _MYZSH_HACKER_QUOTE_SHOWN=1
fi
unset _myzsh_quotes

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
[[ -d /usr/games ]] && path+=(/usr/games)
if [[ -x /opt/nvim-linux-x86_64/bin/nvim ]]; then
  path=(/opt/nvim-linux-x86_64/bin $path)
fi
# Respect an explicitly active virtual environment inherited from the parent.
if [[ -n ${VIRTUAL_ENV:-} && -d "$VIRTUAL_ENV/bin" ]]; then
  path=("$VIRTUAL_ENV/bin" $path)
fi
export PATH

# 2. Basic shell behavior also works before Oh My Zsh has been installed.
# Some upstream plugins append directly; keep reloads from stacking these hooks.
typeset -Ua precmd_functions preexec_functions chpwd_functions
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
bindkey -v
PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f %# '

# Do updates deliberately with `omz update` and scripts/install-plugins.sh.
zstyle ':omz:update' mode disabled
# Reuse a desktop SSH agent and postpone passphrase prompts until a key is used.
zstyle ':omz:plugins:ssh-agent' honor-existing yes
zstyle ':omz:plugins:ssh-agent' lazy yes
zstyle ':omz:plugins:ssh-agent' quiet yes
# The tmux plugin supplies commands; opening a terminal does not launch tmux.
ZSH_TMUX_AUTOSTART=false
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
  aliases ansible colored-man-pages debian dirhistory docker docker-compose \
  emoji emoji-clock encode64 extract gh git gitignore golang helm history httpie \
  jsontools kubectl lol man pass repo ssh ssh-agent sudo tldr thefuck tmux tt \
  vscode vi-mode web-search yt-dlp \
  docker-helpers git-flow-completion zsh-256color you-should-use \
  zsh-autosuggestions zsh-history-substring-search "${MYZSH_EXTRA_PLUGINS[@]}"; do
  # All checkouts are installed; reserve overlapping integrations for one owner.
  case $_myzsh_plugin in
    colors|colorize|hacker-quotes|mise|z|fast-syntax-highlighting|\
    ohmyzsh-full-autoupdate|zsh-syntax-highlighting|zsh-fzf-history-search|\
    zsh-histdb|zsh-navi-plugin|zsh-bat|zsh-lsd|zsh-interactive-cd) continue ;;
    thefuck|tmux|yt-dlp) (( $+commands[$_myzsh_plugin] )) || continue ;;
    ssh-agent)
      [[ -d "$HOME/.ssh" ]] && (( $+commands[ssh-agent] && $+commands[ssh-add] )) || continue ;;
  esac
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
  # zpm-zsh/colorize needs the associative color map from zpm-zsh/colors first.
  # Keep an existing custom checkout; incomplete installs are reported by doctor.
  if [[ -r "$ZSH_CUSTOM/plugins/colorize/colorize.plugin.zsh" ]]; then
    if [[ -r "$ZSH_CUSTOM/plugins/colors/colors.plugin.zsh" &&
          -z ${NO_COLOR:-} && ${CLICOLOR:-} != 0 ]]; then
      source "$ZSH_CUSTOM/plugins/colors/colors.plugin.zsh"
      if [[ ${(t)c} == *association* ]]; then
        source "$ZSH_CUSTOM/plugins/colorize/colorize.plugin.zsh"
      fi
    fi
  elif [[ -r "$ZSH/plugins/colorize/colorize.plugin.zsh" ]]; then
    # OMZ's bundled plugin provides ccat/cless, not zpm's command color settings.
    source "$ZSH/plugins/colorize/colorize.plugin.zsh"
  fi
else
  autoload -Uz compinit
  # Exclude insecure completion paths without a prompt (also works without a TTY).
  compinit -i
fi

# 4. Personal command shortcuts. Executables come from PATH, never an old env.
# lol's catspeak alias must not hide the installed TLRC/tldr client.
[[ ${aliases[tldr]-} == less ]] && unalias tldr
if (( $+commands[batcat] && ! $+commands[bat] )); then
  alias bat='batcat'
fi
# Keep the wrapper's familiar cat shortcut without replacing MANPAGER.
if (( $+commands[bat] )); then
  alias cat='bat --paging=never'
  alias rcat='command cat'
elif (( $+commands[batcat] )); then
  alias cat='batcat --paging=never'
  alias rcat='command cat'
fi
if (( $+commands[lsd] )); then
  alias ls='lsd --group-directories-first'
  alias l='lsd -Alhi --blocks permission,user,group,inode,date,name'
  alias ll='lsd -lh --group-directories-first'
  alias la='lsd -A --group-directories-first'
  alias tree='lsd -l --group-directories-first --tree --depth=2'
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
# OMZ's tt uses BSD date flags. This Debian version uses GNU date instead.
function tt() {
  if (( $# == 0 )); then
    command date +%s
  elif (( $# != 1 )); then
    print -u2 'Usage: tt [UNIX_TIMESTAMP | "DATE TIME"]'
    return 2
  elif [[ $1 == <-> || $1 == -<-> ]]; then
    command date --date="@$1" '+%Y-%m-%d %H:%M:%S'
  else
    command date --date="$1" +%s
  fi
}
if (( $+commands[nvim] )); then
  export EDITOR="${EDITOR:-nvim}"
  export VISUAL="${VISUAL:-nvim}"
fi
if (( $+commands[python3] )); then
  # Local preview: `www 8000`, then open http://localhost:8000.
  alias www='python3 -m http.server --bind 127.0.0.1'
fi
# Keep the personal decoration at the terminal; pipelines get useful plain data.
function _myzsh_print_ip() {
  local output="$1" framed
  if [[ -t 1 ]] && (( $+commands[cowsay] )); then
    framed="$(print -r -- "$output" | command cowsay -n -f ghostbusters 2>/dev/null)" && output="$framed"
  fi
  if [[ -t 1 ]] && (( $+commands[lolcat] )); then
    print -r -- "$output" | command lolcat
  else
    print -r -- "$output"
  fi
}
if (( $+commands[ip] )); then
  function mylocalip() {
    local addresses
    addresses="$(command ip -brief -4 address show)" || return
    _myzsh_print_ip "$addresses"
  }
fi
if (( $+commands[curl] )); then
  function myip() {
    local address
    address="$(command curl --fail --silent --show-error --connect-timeout 5 --max-time 10 \
      https://api.ipify.org)" || return
    _myzsh_print_ip "$address"
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
if [[ -r "$ZSH_CUSTOM/plugins/hacker-quotes/hacker-quotes.plugin.zsh" ]]; then
  function hacker_quote() {
    local ZSH_HACKER_QUOTES_ENABLE_WHEN_INTERACTIVE=1
    source "$ZSH_CUSTOM/plugins/hacker-quotes/hacker-quotes.plugin.zsh"
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
  # Atuin binds '/' in vicmd by default; also give Ctrl-R one owner in that map.
  (( $+widgets[atuin-search] )) && bindkey -M vicmd '^r' atuin-search
fi
if (( $+functions[history-substring-search-up] )); then
  for _myzsh_keymap in emacs viins vicmd; do
    bindkey -M "$_myzsh_keymap" '^[[A' history-substring-search-up
    bindkey -M "$_myzsh_keymap" '^[[B' history-substring-search-down
    bindkey -M "$_myzsh_keymap" '^[OA' history-substring-search-up
    bindkey -M "$_myzsh_keymap" '^[OB' history-substring-search-down
    bindkey -M "$_myzsh_keymap" '^p' history-substring-search-up
    bindkey -M "$_myzsh_keymap" '^n' history-substring-search-down
  done
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
  unset _myzsh_keymap
fi

# Navi's native widget inserts a command for review. It also binds Ctrl-G.
if (( $+commands[navi] && $+commands[fzf] )); then
  eval "$(command navi widget zsh)"
  if (( $+widgets[_navi_widget] )); then
    for _myzsh_keymap in emacs viins vicmd; do
      bindkey -M "$_myzsh_keymap" '^g' _navi_widget
      bindkey -M "$_myzsh_keymap" '^ ' _navi_widget
    done
    unset _myzsh_keymap
  fi
fi

# SSH helper installed with the complete plugin collection.
if [[ -r "$ZSH_CUSTOM/plugins/ssh-connect/ssh-connect.sh" &&
      -r "$ZSH_CUSTOM/plugins/ssh-connect/listbox/listbox.sh" ]]; then
  source "$ZSH_CUSTOM/plugins/ssh-connect/ssh-connect.sh"
fi

# 6. Existing personal prompt and private machine-specific customization.
if [[ -r "${ZDOTDIR:-$HOME}/.p10k.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.p10k.zsh"
elif [[ -r "$HOME/.p10k.zsh" ]]; then
  source "$HOME/.p10k.zsh"
fi
[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh" ]] && \
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.zsh"

# Load exactly one syntax highlighter after widgets and personal bindings.
if [[ -r "$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi
