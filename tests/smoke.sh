#!/usr/bin/env bash
# Regression tests for installer safeguards. All writes use a disposable HOME.
# APT and Cargo are mocked; Git never contacts a remote. Requires Bash, Zsh,
# Git, Python 3 and standard Debian coreutils.
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for dependency in bash zsh git python3; do
    command -v "$dependency" >/dev/null || { printf 'Missing test dependency: %s\n' "$dependency" >&2; exit 1; }
done
test_root=$(mktemp -d "${TMPDIR:-/tmp}/my-zsh-config-tests.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/logs"
test_count=0
pass() { test_count=$((test_count + 1)); printf 'ok %s - %s\n' "$test_count" "$1"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
new_case() {
    case_dir="$test_root/$1"
    mkdir -p "$case_dir"
    fixture_home="$case_dir/home with spaces"
    fixture_config="$case_dir/config with spaces"
    fixture_state="$case_dir/state with spaces"
    fixture_zdot="$case_dir/zsh with spaces"
    fixture_zsh="$case_dir/oh my zsh"
    fixture_custom="$case_dir/custom plugins"
    fixture_path=/usr/bin:/bin
    fixture_log="$test_root/logs/$1.commands"
    case_out="$test_root/logs/$1.output"
}
run_clean() {
    env -i PATH="$fixture_path" HOME="$fixture_home" \
        XDG_CONFIG_HOME="$fixture_config" XDG_STATE_HOME="$fixture_state" \
        XDG_CACHE_HOME="$case_dir/cache" ZDOTDIR="$fixture_zdot" \
        ZSH="$fixture_zsh" ZSH_CUSTOM="$fixture_custom" \
        CARGO_HOME="$case_dir/cargo with spaces" TERM=xterm-256color \
        LANG=C LC_ALL=C GIT_CONFIG_NOSYSTEM=1 TEST_LOG="$fixture_log" TEST_REPO="$repo_dir" "$@"
}
snapshot() {
    python3 - "$1" <<'PY'
import hashlib, json, os, pathlib, stat, sys
root = pathlib.Path(sys.argv[1])
result = []
for base, dirs, files in os.walk(root, followlinks=False):
    for name in sorted(dirs + files):
        p = pathlib.Path(base, name)
        s = p.lstat()
        data = os.readlink(p) if p.is_symlink() else (
            hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None)
        result.append((str(p.relative_to(root)), stat.S_IFMT(s.st_mode),
                       stat.S_IMODE(s.st_mode), s.st_mtime_ns, data))
print(json.dumps(sorted(result)))
PY
}

for file in "$repo_dir/install.sh" "$repo_dir"/scripts/*.sh "$repo_dir"/scripts/lib/*.sh; do bash -n "$file"; done
for file in "$repo_dir/install.sh" "$repo_dir"/scripts/*.sh; do
    [[ -x $file ]] || fail "Documented entry point is not executable: $file"
done
"$repo_dir/install.sh" --help >/dev/null
zsh -n "$repo_dir/.zshrc"
pass 'Bash and Zsh syntax, executable entry points, and installer help'

new_case previews
for script in install.sh scripts/install-config.sh scripts/install-apt.sh scripts/install-cargo.sh scripts/install-plugins.sh scripts/install-runtimes.sh scripts/install-fonts.sh scripts/install-neovim.sh scripts/install-dev-tools.sh scripts/finish-setup.sh; do
    run_clean bash "$repo_dir/$script" --dry-run > "$case_out" 2>&1
done
[[ ! -e $fixture_home && ! -e $fixture_config && ! -e $fixture_state && ! -e $fixture_zdot && ! -e $fixture_zsh ]] || fail 'Preview wrote user configuration'
pass 'All dry-run previews create no home, config, state, or plugin directories'

new_case backup
mkdir -p "$fixture_zdot" "$fixture_config/mise" "$fixture_config/kitty" "$fixture_config/nvim" "$fixture_home"
printf 'original zsh\n' > "$fixture_zdot/.zshrc"
printf 'original mise\n' > "$fixture_config/mise/config.toml"
printf 'private editor\n' > "$fixture_config/nvim/init.lua"
printf 'private prompt\n' > "$fixture_home/.p10k.zsh"
printf 'original kitty\n' > "$case_dir/original kitty.conf"
ln -s "$case_dir/original kitty.conf" "$fixture_config/kitty/kitty.conf"
run_clean bash "$repo_dir/scripts/install-config.sh" --apply > "$case_out" 2>&1
cmp -s "$repo_dir/.zshrc" "$fixture_zdot/.zshrc" || fail 'Zsh config copy differs'
cmp -s "$repo_dir/config/mise/config.toml" "$fixture_config/mise/config.toml" || fail 'mise config copy differs'
cmp -s "$repo_dir/config/kitty/kitty.conf" "$fixture_config/kitty/kitty.conf" || fail 'Kitty config copy differs'
shopt -s nullglob
backups=("$fixture_state"/my-zsh-config/backups/*)
[[ ${#backups[@]} == 1 ]] || fail 'Expected one backup set'
[[ $(cat "${backups[0]}/zsh") == 'original zsh' && $(cat "${backups[0]}/mise") == 'original mise' ]] || fail 'Original files were not backed up'
[[ -L ${backups[0]}/kitty && $(readlink "${backups[0]}/kitty") == "$case_dir/original kitty.conf" ]] || fail 'Original symlink was not preserved'
[[ $(cat "$case_dir/original kitty.conf") == 'original kitty' ]] || fail 'Symlink referent changed'
[[ $(cat "$fixture_config/nvim/init.lua") == 'private editor' && $(cat "$fixture_home/.p10k.zsh") == 'private prompt' ]] || fail 'Personal editor/prompt changed'
[[ $(stat -c %a "${backups[0]}") == 700 ]] || fail 'Backup directory is not private'
pass 'Paths with spaces, file backups, symlink preservation, and personal config preservation'
snapshot "$case_dir" > "$test_root/before"
run_clean bash "$repo_dir/scripts/install-config.sh" --apply > "$case_out" 2>&1
snapshot "$case_dir" > "$test_root/after"
cmp -s "$test_root/before" "$test_root/after" || fail 'Second apply changed files or created another backup'
pass 'Repeated configuration installation is idempotent'
new_case shell_start
run_clean bash "$repo_dir/scripts/install-config.sh" --apply --only zsh > "$case_out" 2>&1
run_clean zsh -d -i -c '[[ -n $PROMPT ]] && print -r -- fresh-zsh-ok' > "$case_out" 2>&1
[[ $(cat "$case_out") == fresh-zsh-ok ]] || { cat "$case_out" >&2; fail 'Fresh HOME interactive Zsh failed or emitted startup errors'; }
pass 'Interactive Zsh starts with the installed config and no Oh My Zsh checkout'

new_case completion_permissions
mkdir -p "$fixture_zdot" "$case_dir/safe completions" "$case_dir/unsafe completions"
printf '#compdef myzsh-safe-probe\n' > "$case_dir/safe completions/_myzsh_safe_probe"
printf '#compdef myzsh-unsafe-probe\n' > "$case_dir/unsafe completions/_myzsh_unsafe_probe"
chmod 700 "$case_dir/safe completions"
chmod 777 "$case_dir/unsafe completions"
printf 'fpath=(%q %q $fpath)\n' "$case_dir/safe completions" "$case_dir/unsafe completions" > "$fixture_zdot/.zshenv"
run_clean bash "$repo_dir/scripts/install-config.sh" --apply --only zsh > "$case_out" 2>&1
run_clean zsh -d -i -c '[[ ${_comps[myzsh-safe-probe]-} == _myzsh_safe_probe && -z ${_comps[myzsh-unsafe-probe]-} ]] && print -r -- completion-audit-ok' > "$case_out" 2>&1 || { cat "$case_out" >&2; fail 'Completion security filtering failed'; }
[[ $(cat "$case_out") == completion-audit-ok ]] || { cat "$case_out" >&2; fail 'Completion audit prompted or emitted startup errors'; }
pass 'Fallback completion skips insecure directories and keeps safe completions without prompting'

new_case colorize_dependency
mkdir -p "$fixture_zsh/plugins/colorize" "$fixture_custom/plugins/colorize" "$fixture_custom/plugins/colors" "$fixture_config/zsh"
cat > "$fixture_zsh/oh-my-zsh.sh" <<'MOCK'
autoload -Uz compinit
compinit -i
# OMZ exposes ANSI-valued color names. Without associative c, c[bold] is math.
bold=$'\e[1m'
for plugin in "${plugins[@]}"; do
    if [[ -r "$ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh" ]]; then
        source "$ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh"
    elif [[ -r "$ZSH/plugins/$plugin/$plugin.plugin.zsh" ]]; then
        source "$ZSH/plugins/$plugin/$plugin.plugin.zsh"
    fi
done
unset plugin
MOCK
cat > "$fixture_custom/plugins/colorize/colorize.plugin.zsh" <<'MOCK'
export LESS_TERMCAP_md="${c[bold]}${c[springgreen]}${c[italic]:-${c[coursive]}}"
(( COLORIZE_LOADS += 1 ))
MOCK
printf '(( BUNDLED_COLORIZE_LOADS += 1 ))\n' > "$fixture_zsh/plugins/colorize/colorize.plugin.zsh"
printf 'MYZSH_EXTRA_PLUGINS=(colorize colors colorize)\n' > "$fixture_config/zsh/plugins.zsh"
run_clean bash "$repo_dir/scripts/install-config.sh" --apply --only zsh > "$case_out" 2>&1
run_clean zsh -d -i -c '(( ${COLORIZE_LOADS:-0} == 0 && ${BUNDLED_COLORIZE_LOADS:-0} == 0 )) && print -r -- missing-dependency-ok' > "$case_out" 2>&1 || { cat "$case_out" >&2; fail 'Incomplete custom colorize broke startup'; }
[[ $(cat "$case_out") == missing-dependency-ok ]] || { cat "$case_out" >&2; fail 'Missing colorize dependency emitted startup errors'; }
cat > "$fixture_custom/plugins/colors/colors.plugin.zsh" <<'MOCK'
(( COLORS_LOADS += 1 ))
typeset -Ag c=(bold $'\e[1m' springgreen $'\e[92m' italic $'\e[3m')
MOCK
run_clean zsh -d -i -c '[[ ${(t)c} == *association* && $LESS_TERMCAP_md == "${c[bold]}${c[springgreen]}${c[italic]}" ]] && (( COLORS_LOADS == 1 && COLORIZE_LOADS == 1 && ${BUNDLED_COLORIZE_LOADS:-0} == 0 )) && print -r -- dependency-order-ok' > "$case_out" 2>&1 || { cat "$case_out" >&2; fail 'Custom colorize did not load once after its dependency'; }
[[ $(cat "$case_out") == dependency-order-ok ]] || { cat "$case_out" >&2; fail 'Custom colorize emitted startup errors'; }
pass 'Custom colorize skips a missing dependency and loads once after its color table is available'
for preference in NO_COLOR=1 CLICOLOR=0; do
    run_clean env "$preference" zsh -d -i -c '(( ${COLORS_LOADS:-0} == 0 && ${COLORIZE_LOADS:-0} == 0 )) && print -r -- colors-disabled-ok' > "$case_out" 2>&1 || { cat "$case_out" >&2; fail 'Disabled custom colors were still loaded'; }
    [[ $(cat "$case_out") == colors-disabled-ok ]] || { cat "$case_out" >&2; fail 'Disabled colorize emitted startup errors'; }
done
# A present dependency that never defines c must not make the unsafe expansion run.
printf '(( COLORS_LOADS += 1 ))\n' > "$fixture_custom/plugins/colors/colors.plugin.zsh"
run_clean zsh -d -i -c '(( COLORS_LOADS == 1 && ${COLORIZE_LOADS:-0} == 0 )) && print -r -- missing-table-ok' > "$case_out" 2>&1 || { cat "$case_out" >&2; fail 'Custom colorize ran without an associative color table'; }
[[ $(cat "$case_out") == missing-table-ok ]] || { cat "$case_out" >&2; fail 'Missing color table emitted startup errors'; }
mv "$fixture_custom/plugins/colorize/colorize.plugin.zsh" "$case_dir/custom-colorize-disabled"
run_clean zsh -d -i -c '(( BUNDLED_COLORIZE_LOADS == 1 && ${COLORIZE_LOADS:-0} == 0 )) && print -r -- bundled-fallback-ok' > "$case_out" 2>&1 || { cat "$case_out" >&2; fail 'Bundled colorize fallback did not load'; }
[[ $(cat "$case_out") == bundled-fallback-ok ]] || { cat "$case_out" >&2; fail 'Bundled colorize emitted startup errors'; }
pass 'Custom colorize respects disabled colors and a missing color table; bundled fallback loads only without a custom copy'

new_case preflight
mkdir -p "$fixture_zdot" "$fixture_config/mise/config.toml"
printf 'keep this\n' > "$fixture_zdot/.zshrc"
snapshot "$case_dir" > "$test_root/before"
if run_clean bash "$repo_dir/scripts/install-config.sh" --apply > "$case_out" 2>&1; then fail 'Directory destination was accepted'; fi
snapshot "$case_dir" > "$test_root/after"
cmp -s "$test_root/before" "$test_root/after" || fail 'Preflight error changed another destination'
pass 'Invalid destination aborts before any config is changed'

new_case only
run_clean bash "$repo_dir/scripts/install-config.sh" --apply --only zsh > "$case_out" 2>&1
[[ -f $fixture_zdot/.zshrc && ! -e $fixture_config ]] || fail '--only zsh touched another configuration'
pass 'Selective installation touches only the requested config'

new_case identity
mkdir -p "$case_dir/source/scripts"
cp "$repo_dir/scripts/install-config.sh" "$case_dir/source/scripts/"
cp "$repo_dir/.zshrc" "$case_dir/source/"
fixture_zdot="$case_dir/source"
if run_clean bash "$case_dir/source/scripts/install-config.sh" --apply --only zsh > "$case_out" 2>&1; then fail 'Source=destination was accepted'; fi
ln -s "$case_dir/source" "$case_dir/alias parent"
fixture_zdot="$case_dir/alias parent"
if run_clean bash "$case_dir/source/scripts/install-config.sh" --apply --only zsh > "$case_out" 2>&1; then fail 'Source=destination through a parent symlink was accepted'; fi
cmp -s "$repo_dir/.zshrc" "$case_dir/source/.zshrc" || fail 'Source was modified'
pass 'Source identity checks include symlinked parent directories'

new_case rollback
mkdir -p "$fixture_zdot" "$case_dir/mocks"
printf 'restore me\n' > "$fixture_zdot/.zshrc"
cat > "$case_dir/mocks/mv" <<'MOCK'
#!/usr/bin/env bash
for arg in "$@"; do
    if [[ $arg == */.my-zsh-config.* ]]; then exit 73; fi
done
exec /usr/bin/mv "$@"
MOCK
chmod +x "$case_dir/mocks/mv"
fixture_path="$case_dir/mocks:/usr/bin:/bin"
if run_clean bash "$repo_dir/scripts/install-config.sh" --apply --only zsh > "$case_out" 2>&1; then fail 'Failed replacement reported success'; fi
[[ $(cat "$fixture_zdot/.zshrc") == 'restore me' ]] || fail 'Previous config was not restored'
leftovers=("$fixture_zdot"/.my-zsh-config.*)
[[ ${#leftovers[@]} == 0 ]] || fail 'Failed replacement left temporary files'
pass 'A failed final rename restores the previous config and cleans the temporary file'

new_case apt
mkdir -p "$case_dir/mocks"
cat > "$case_dir/mocks/apt-get" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_LOG"
MOCK
cat > "$case_dir/mocks/apt-cache" <<'MOCK'
#!/usr/bin/env bash
if [[ $2 == sherlock ]]; then printf '  Candidate: (none)\n'; else printf '  Candidate: 1.0\n'; fi
MOCK
cat > "$case_dir/mocks/sudo" <<'MOCK'
#!/usr/bin/env bash
exec "$@"
MOCK
chmod +x "$case_dir"/mocks/*
fixture_path="$case_dir/mocks:/usr/bin:/bin"
if run_clean bash "$repo_dir/scripts/install-apt.sh" --apply > "$case_out" 2>&1; then fail 'Unavailable APT package reported success'; fi
[[ $(cat "$fixture_log") == update ]] || fail 'APT installation ran despite a missing candidate'
pass 'Missing APT candidate prevents every package-install transaction'

new_case cargo
mkdir -p "$case_dir/mocks"
cat > "$case_dir/mocks/cargo" <<'MOCK'
#!/usr/bin/env bash
[[ $* != 'install --list' ]] || exit 0
printf '%s\n' "$*" >> "$TEST_LOG"
[[ ${!#} != atuin ]]
MOCK
chmod +x "$case_dir/mocks/cargo"
fixture_path="$case_dir/mocks:/usr/bin:/bin"
if run_clean bash "$repo_dir/scripts/install-cargo.sh" --apply > "$case_out" 2>&1; then fail 'Failed Cargo install reported success'; fi
grep -q 'atuin' "$fixture_log" && grep -q 'tree-sitter-cli' "$fixture_log" || fail 'Cargo did not attempt later selected tools after failure'
if grep -q -- '--force' "$fixture_log"; then fail 'Cargo installer bypassed binary collision checks'; fi
pass 'Cargo reports failure while attempting the remaining selected crates'
[[ $(wc -l < "$fixture_log") == 27 ]] || fail 'Cargo did not attempt all 27 crates by default'

new_case cargo_resume
mkdir -p "$case_dir/mocks" "$case_dir/cargo with spaces/bin"
cat > "$case_dir/mocks/cargo" <<'MOCK'
#!/usr/bin/env bash
if [[ $* == 'install --list' ]]; then
    printf 'atuin v18.24.1:\n    atuin\nnavi v2.24.0:\n    navi\ncargo-update v22.1.1:\n    cargo-install-update\n    cargo-install-update-config\n'
    exit 0
fi
printf '%s\n' "$*" >> "$TEST_LOG"
crate=${!#}
while IFS='|' read -r profile name version executables; do
    [[ $name == "$crate" ]] || continue
    IFS=',' read -r -a bins <<< "$executables"
    for bin in "${bins[@]}"; do
        [[ -e $CARGO_HOME/bin/$bin ]] && continue
        printf '#!/bin/sh\nexit 0\n' > "$CARGO_HOME/bin/$bin"
        chmod +x "$CARGO_HOME/bin/$bin"
    done
done < "$TEST_REPO/manifests/cargo-tools.txt"
MOCK
printf '#!/bin/sh\nexit 0\n' > "$case_dir/cargo with spaces/bin/atuin"
printf '#!/bin/sh\nexit 0\n' > "$case_dir/cargo with spaces/bin/cargo-install-update"
chmod +x "$case_dir/mocks/cargo" "$case_dir/cargo with spaces/bin/atuin" "$case_dir/cargo with spaces/bin/cargo-install-update"
fixture_path="$case_dir/mocks:/usr/bin:/bin"
run_clean bash "$repo_dir/scripts/install-cargo.sh" --apply > "$case_out" 2>&1
[[ $(wc -l < "$fixture_log") == 26 ]] || fail 'Cargo did not skip exactly the intact installed crate'
if grep -q ' atuin$' "$fixture_log"; then fail 'Cargo reinstalled an intact existing tool'; fi
for crate in navi exa btop rtk; do
    grep -q " $crate$" "$fixture_log" || fail "Cargo omitted missing/included crate: $crate"
done
grep -q -- '--git https://github.com/rtk-ai/rtk --branch master rtk' "$fixture_log" || fail 'RTK lost its Git source'
grep -q -- '--version =22.1.1 --bin cargo-install-update-config cargo-update' "$fixture_log" || fail 'Partial Cargo repair did not target only the missing binary at its installed version'
if grep -q -- '--force' "$fixture_log"; then fail 'Cargo repair forced replacement of existing binaries'; fi
pass 'Cargo retry preserves installed binaries, repairs missing binaries, and includes every inventory group'

new_case progress
run_clean bash -c '
    set -euo pipefail
    source "$1/scripts/lib/installer-ui.sh"
    install_ui_init "$2/stage logs" 2
    run_stage "First successful step" first bash -c "printf first-output"
    [[ $install_completed == 1 ]]
    status=0
    run_stage "Second failing step" second bash -c "printf useful-error >&2; exit 37" || status=$?
    [[ $status == 37 && $install_completed == 1 ]]
    [[ $(cat "$2/stage logs/first.log") == first-output ]]
    [[ $(cat "$2/stage logs/second.log") == useful-error ]]
' bash "$repo_dir" "$case_dir" > "$case_out" 2>&1
grep -q '50%' "$case_out" || fail 'Progress did not count completed stages'
grep -q 'FAILED: Second failing step (exit 37)' "$case_out" || fail 'Stage failure was not explained'
if grep -q '100%' "$case_out"; then fail 'Progress reported completion after a failure'; fi
if LC_ALL=C grep -q $'\033' "$case_out"; then fail 'Non-TTY output contains terminal escape sequences'; fi
[[ $(stat -c %a "$case_dir/stage logs") == 700 ]] || fail 'Installation logs directory is not private'
pass 'Progress logs each stage, keeps the exact failure status, and never claims false completion'

new_case complete_plan
run_clean bash "$repo_dir/install.sh" --dry-run > "$case_out" 2>&1
[[ $(grep -c '^== ' "$case_out") == 10 ]] || fail 'Full installation plan is missing a stage'
[[ $(grep -c '^\[[0-9]*/27\] Installing Cargo crate:' "$case_out") == 27 ]] || fail 'Full plan omits Cargo inventory'
for feature in sherlock yt-dlp java kubectl Helm Repo Neovim MesloLGS Docker Powerlevel10k; do
    grep -qi "$feature" "$case_out" || fail "Full plan omitted $feature"
done
[[ ! -e $fixture_home && ! -e $fixture_state ]] || fail 'Full plan wrote files'
pass 'One-command plan covers all ten stages and all 27 Cargo crates without writing files'

new_case git_preview
mkdir -p "$fixture_zsh"
run_clean git init -q "$fixture_zsh"
run_clean git -C "$fixture_zsh" remote add origin https://github.com/ohmyzsh/ohmyzsh.git
printf 'fixture\n' > "$fixture_zsh/tracked"
run_clean git -C "$fixture_zsh" add tracked
run_clean git -C "$fixture_zsh" -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false commit -qm fixture
# Content is unchanged, but a normal `git status` would refresh index metadata.
touch -d @946684800 "$fixture_zsh/tracked"
snapshot "$case_dir" > "$test_root/before"
run_clean bash "$repo_dir/scripts/install-plugins.sh" --dry-run --update > "$case_out" 2>&1
snapshot "$case_dir" > "$test_root/after"
cmp -s "$test_root/before" "$test_root/after" || fail 'Plugin update preview changed the checkout or Git index'
pass 'Plugin update preview leaves the real Git checkout and index unchanged'

printf '\nAll %s smoke checks passed. No packages were installed and no remote was contacted.\n' "$test_count"
