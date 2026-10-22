#!/usr/bin/env bash
# The selected Kubernetes/Helm OMZ integrations need the actual clients too.
set -euo pipefail
apply=false
for arg in "$@"; do
    case "$arg" in
        --apply) apply=true ;;
        --dry-run) apply=false ;;
        -h|--help) printf 'Usage: scripts/install-dev-tools.sh [--apply | --dry-run]\nInstall missing kubectl/Helm (SHA-256 checked) and Google Repo (signature checked).\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
    esac
done
: "${HOME:?Set HOME to the account receiving the tools}"
bin_dir="$HOME/.local/bin"
export PATH="$bin_dir:$PATH"
printf 'Keep working kubectl and Helm clients. Install missing clients into %s.\n' "$bin_dir"
printf 'Download from dl.k8s.io and get.helm.sh; check each published SHA-256 before installation.\n'
printf 'Install the signed Google Repo launcher when missing; no Debian contrib repository is needed.\n'
$apply || exit 0
((EUID != 0)) || { printf 'Run this step as your normal account, without sudo.\n' >&2; exit 1; }
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { printf 'This setup targets Linux x86_64.\n' >&2; exit 1; }
for cmd in curl python3 gpg gpgv; do command -v "$cmd" >/dev/null || { printf 'Missing prerequisite: %s\n' "$cmd" >&2; exit 1; }; done
work=$(mktemp -d)
temp_file=
trap '[[ -z ${temp_file:-} ]] || rm -f -- "$temp_file"; rm -rf -- "$work"' EXIT
fetch() { curl --proto '=https' --tlsv1.2 --fail --location --retry 3 "$1" --output "$2"; }
verify_checksum() {
    python3 - "$1" "$2" <<'PY'
import hashlib, re, sys
archive, checksum_file = sys.argv[1:]
checksum = open(checksum_file, encoding="ascii").read().split()[0]
if not re.fullmatch(r"[0-9a-fA-F]{64}", checksum):
    raise SystemExit("Invalid SHA-256 checksum metadata")
with open(archive, "rb") as stream:
    actual = hashlib.file_digest(stream, "sha256").hexdigest()
if actual != checksum.lower():
    raise SystemExit("Downloaded file does not match its published SHA-256")
print("Verified SHA-256: " + archive)
PY
}
assert_free_destination() {
    [[ ! -e $bin_dir/$1 && ! -L $bin_dir/$1 ]] || {
        printf 'Existing %s does not run correctly; repair it before rerunning.\n' "$bin_dir/$1" >&2; exit 1;
    }
}
install_client() {
    local name=$1
    mkdir -p -- "$bin_dir"
    temp_file=$(mktemp "$bin_dir/.my-zsh-$name.XXXXXXXX")
    install -m 0755 -- "$work/$name" "$temp_file"
    assert_free_destination "$name"
    # Hard-link creation fails atomically if a destination appeared meanwhile.
    ln -- "$temp_file" "$bin_dir/$name"
    rm -f -- "$temp_file"
    temp_file=
    printf 'Installed: %s\n' "$bin_dir/$name"
}

if command -v kubectl >/dev/null && kubectl version --client >/dev/null 2>&1; then
    printf 'Keep kubectl: %s\n' "$(command -v kubectl)"
else
    assert_free_destination kubectl
    fetch https://dl.k8s.io/release/stable.txt "$work/kubectl-version"
    version=$(< "$work/kubectl-version")
    [[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { printf 'Invalid Kubernetes release version.\n' >&2; exit 1; }
    base="https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl"
    fetch "$base" "$work/kubectl"
    fetch "$base.sha256" "$work/kubectl.sha256"
    verify_checksum "$work/kubectl" "$work/kubectl.sha256"
    chmod 0755 "$work/kubectl"
    "$work/kubectl" version --client
    install_client kubectl
fi

# Debian packages Repo in contrib. The official signed launcher makes this
# profile work on a standard main-only system without changing APT sources.
if command -v repo >/dev/null && repo version >/dev/null 2>&1; then
    printf 'Keep Google Repo: %s\n' "$(command -v repo)"
else
    assert_free_destination repo
    fetch https://storage.googleapis.com/git-repo-downloads/repo "$work/repo"
    fetch https://storage.googleapis.com/git-repo-downloads/repo.asc "$work/repo.asc"
    fetch 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x8BB9AD793E8E6153AF0F9A4416530D5E920F5C65' "$work/repo-keys.asc"
    mkdir -m 0700 "$work/gnupg"
    # Trust only the key fingerprint published in Android's setup instructions.
    repo_key=8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
    gpg --homedir "$work/gnupg" --batch --quiet --import "$work/repo-keys.asc"
    gpg --homedir "$work/gnupg" --batch --export "$repo_key" > "$work/repo-trusted.gpg"
    [[ -s $work/repo-trusted.gpg ]] || { printf 'Official Repo signing key is absent; refusing installation.\n' >&2; exit 1; }
    gpgv --homedir "$work/gnupg" --keyring "$work/repo-trusted.gpg" "$work/repo.asc" "$work/repo"
    chmod 0755 "$work/repo"
    "$work/repo" version
    install_client repo
fi

if command -v helm >/dev/null && helm version --short >/dev/null 2>&1; then
    printf 'Keep Helm: %s\n' "$(command -v helm)"
else
    assert_free_destination helm
    fetch https://api.github.com/repos/helm/helm/releases/latest "$work/helm-release.json"
    version=$(python3 - "$work/helm-release.json" <<'PY'
import json, re, sys
release = json.load(open(sys.argv[1], encoding="utf-8"))
tag = release.get("tag_name", "")
if release.get("draft") or release.get("prerelease") or not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
    raise SystemExit("Helm API did not return a stable release")
print(tag)
PY
)
    base="https://get.helm.sh/helm-$version-linux-amd64.tar.gz"
    fetch "$base" "$work/helm.tar.gz"
    fetch "$base.sha256sum" "$work/helm.sha256sum"
    verify_checksum "$work/helm.tar.gz" "$work/helm.sha256sum"
    # Read only the one regular executable; never extract paths from the archive.
    python3 - "$work/helm.tar.gz" "$work/helm" <<'PY'
import shutil, sys, tarfile
with tarfile.open(sys.argv[1], "r:gz") as archive:
    matches = [entry for entry in archive.getmembers() if entry.name == "linux-amd64/helm"]
    if len(matches) != 1 or not matches[0].isfile():
        raise SystemExit("Helm archive does not contain exactly one regular client executable")
    with archive.extractfile(matches[0]) as src, open(sys.argv[2], "wb") as dst:
        shutil.copyfileobj(src, dst)
PY
    chmod 0755 "$work/helm"
    "$work/helm" version --short
    install_client helm
fi
