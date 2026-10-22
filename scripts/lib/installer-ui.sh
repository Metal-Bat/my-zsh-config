#!/usr/bin/env bash
# Shared by the one-command installer and its regression tests.
# Progress counts completed stages, never invented download/build percentages.
install_ui_init() {
    install_log_dir=$1
    install_total=$2
    install_completed=0
    install_child=
    install_animated=false
    install_cyan= install_green= install_red= install_dim= install_reset=
    if [[ -t 1 && ${TERM:-dumb} != dumb && -z ${NO_COLOR:-} ]]; then
        install_animated=true
        install_cyan=$'\033[36m'; install_green=$'\033[32m'
        install_red=$'\033[31m'; install_dim=$'\033[2m'; install_reset=$'\033[0m'
    fi
    mkdir -p -- "$install_log_dir"
    chmod 700 -- "$install_log_dir"
}

install_progress() {
    local count=$1 width=24 filled empty bar rest
    filled=$((count * width / install_total))
    empty=$((width - filled))
    printf -v bar '%*s' "$filled" ''; bar=${bar// /#}
    printf -v rest '%*s' "$empty" ''; rest=${rest// /-}
    printf '[%s%s] %3s%%' "$bar" "$rest" "$((count * 100 / install_total))"
}

install_stop_child() {
    if [[ -n ${install_child:-} ]]; then
        install_stop_tree "$install_child"
        wait "$install_child" 2>/dev/null || true
        install_child=
    fi
}

install_stop_tree() {
    local pid=$1 child
    # Preserve the controlling TTY for sudo's timestamp. A separate setsid
    # session would lose that timestamp, so cancel descendants explicitly.
    while read -r child; do
        [[ -z $child ]] || install_stop_tree "$child"
    done < <(ps -o pid= --ppid "$pid" 2>/dev/null || true)
    kill -TERM "$pid" 2>/dev/null || true
}

run_stage() {
    local label=$1 log_name=$2
    shift 2
    local log_file="$install_log_dir/$log_name.log" status=0 tick=0 line= frame
    local frames=('|' '/' '-' '\')
    printf '\n%s[%s/%s] %s%s\n' "$install_cyan" "$((install_completed + 1))" "$install_total" "$label" "$install_reset"
    printf '%sLog: %s%s\n' "$install_dim" "$log_file" "$install_reset"
    : > "$log_file"
    # stdin is closed: all prompts must have been handled by the foreground
    # preflight, and a child must fail rather than hang behind the progress UI.
    "$@" </dev/null > "$log_file" 2>&1 &
    install_child=$!
    if $install_animated; then
        while kill -0 "$install_child" 2>/dev/null; do
            # Strip terminal controls from upstream output before displaying it.
            line=$(tail -c 4096 -- "$log_file" | sed $'s/\033\\[[0-9;?]*[ -/]*[@-~]//g' | tr '\r' '\n' | LC_ALL=C tr -cd '\11\12\40-\176' | tail -n 1)
            frame=${frames[tick % ${#frames[@]}]}
            printf '\r\033[2K%s%s %s %s%s' "$install_cyan" "$(install_progress "$install_completed")" "$frame" "${line:0:90}" "$install_reset"
            tick=$((tick + 1))
            sleep 0.2
        done
        printf '\r\033[2K'
    fi
    wait "$install_child" || status=$?
    install_child=
    if ((status != 0)); then
        printf '%sFAILED: %s (exit %s)%s\n' "$install_red" "$label" "$status" "$install_reset" >&2
        tail -n 35 -- "$log_file" >&2
        printf '\nFull log: %s\nFix the reported issue, then rerun ./install.sh.\n' "$log_file" >&2
        return "$status"
    fi
    install_completed=$((install_completed + 1))
    printf '%s%s  Done: %s%s\n' "$install_green" "$(install_progress "$install_completed")" "$label" "$install_reset"
}
