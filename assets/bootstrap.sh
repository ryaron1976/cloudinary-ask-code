#!/usr/bin/env bash
# cloudinary-ask-code bootstrap: zero-dependency installer + wizard stage-state.
# Sourceable for tests via CAC_LIB_ONLY=1.

cac_detect_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64)  echo "amd64" ;;
    *) echo "amd64" ;;   # safe default for unknown Macs
  esac
}

cac_state_dir() { echo "$HOME/cloudinary-code/.cac"; }

cac_get_stage() {
  local f; f="$(cac_state_dir)/stage"
  if [ -f "$f" ]; then cat "$f"; else echo "0"; fi
}

cac_set_stage() { # $1 = stage number
  mkdir -p "$(cac_state_dir)"
  echo "$1" > "$(cac_state_dir)/stage"
}

cac_pick_gh_asset() { # $1 = arch (arm64|amd64); JSON on stdin -> macOS .zip url
  local arch="$1"
  grep -o 'https://[^"]*macOS_'"$arch"'\.zip' | head -n1
}

cac_fetch_gh_asset_url() { # $1 = arch; hits the live public API
  local arch="$1"
  curl -fsSL "https://api.github.com/repos/cli/cli/releases/latest" \
    | cac_pick_gh_asset "$arch"
}

cac_ensure_local_bin_on_path() {
  mkdir -p "$HOME/.local/bin"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) : ;;   # already present
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
  # Persist for future shells (idempotent append).
  # Assumes zsh / ~/.zshrc — the default login shell on modern macOS (10.15+).
  local rc="$HOME/.zshrc" line='export PATH="$HOME/.local/bin:$PATH"'
  if [ -w "$rc" ] || [ ! -e "$rc" ]; then
    grep -qF "$line" "$rc" 2>/dev/null || echo "$line" >> "$rc"
  fi
}

cac_ensure_gh() {
  cac_ensure_local_bin_on_path
  if [ "${CAC_FORCE_INSTALL_GH:-0}" != "1" ] && command -v gh >/dev/null 2>&1; then
    # Already on PATH (e.g. Homebrew). Skip install, but record WHY so the audit
    # log explains an otherwise-empty ~/.local/bin if someone debugs later.
    cac_log INFO "ensure_gh: gh already present at $(command -v gh) — skipping install"
    return 0
  fi
  local arch url tmp
  arch="$(cac_detect_arch)"
  url="$(cac_fetch_gh_asset_url "$arch")"
  [ -n "$url" ] || { cac_log ERROR "ensure_gh: could not resolve gh download url"; echo "ERROR: could not resolve gh download url" >&2; return 1; }
  cac_log INFO "ensure_gh: arch=$arch url=$url"
  tmp="$(mktemp -d)"
  # Check every step: sourced functions have no `set -e`, so without explicit
  # exit-code checks this function would return the status of its last command
  # (rm, always 0) and report success even when the install failed.
  cac_run curl -fsSL "$url" -o "$tmp/gh.zip" || { echo "ERROR: failed to download gh from $url" >&2; rm -rf "$tmp"; return 1; }
  cac_run unzip -q "$tmp/gh.zip" -d "$tmp" || { echo "ERROR: failed to unzip gh archive" >&2; rm -rf "$tmp"; return 1; }   # unzip ships with macOS — stays zero-dependency
  # zip extracts to gh_X.Y.Z_macOS_<arch>/bin/gh
  local ghbin; ghbin="$(find "$tmp" -type f -name gh -path '*/bin/gh' | head -n1)"
  [ -n "$ghbin" ] || { cac_log ERROR "ensure_gh: gh binary not found in archive"; echo "ERROR: gh binary not found in archive (layout changed?)" >&2; rm -rf "$tmp"; return 1; }
  cp "$ghbin" "$HOME/.local/bin/gh" && chmod +x "$HOME/.local/bin/gh" \
    || { cac_log ERROR "ensure_gh: failed to install gh into ~/.local/bin"; echo "ERROR: failed to install gh into $HOME/.local/bin" >&2; rm -rf "$tmp"; return 1; }
  cac_log INFO "ensure_gh: installed gh to $HOME/.local/bin/gh"
  rm -rf "$tmp"
}

cac_git_present() {
  command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1
}

cac_ensure_git() {
  cac_log INFO "ensure_git: present=$(cac_git_present && echo yes || echo no)"
  if cac_git_present; then return 0; fi
  echo "Installing Apple Command Line Tools (git). Click 'Install' in the dialog; no password needed." >&2
  cac_run xcode-select --install || true
  # Poll up to ~10 min for git to appear.
  local i=0
  while [ "$i" -lt 120 ]; do
    if cac_git_present; then return 0; fi
    sleep 5; i=$((i+1))
  done
  echo "ERROR: git still not available after waiting. Re-run setup once the install finishes." >&2
  return 1
}

cac_clone_root() { echo "${CAC_CLONE_ROOT:-$HOME/cloudinary-code}"; }

# --- audit logging -------------------------------------------------------
# Append-only, timestamped. Never pass secrets/tokens to these.
cac_log_dir()  { echo "$(cac_clone_root)/.cac"; }
cac_log_file() { echo "$(cac_log_dir)/audit.log"; }

cac_log() { # $1 = level (INFO|WARN|ERROR), $2 = message
  local dir; dir="$(cac_log_dir)"; mkdir -p "$dir"
  # Best-effort: if the log dir is unwritable, never emit a raw shell error and
  # never abort the caller.
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$dir/audit.log" 2>/dev/null
}

cac_run() { # logged command execution; logs cmd + exit code, captures stderr on failure
  cac_log INFO "RUN: $*"
  local err rc
  err="$(mktemp)"
  [ -n "$err" ] || err=/dev/null
  "$@" 2>"$err"; rc=$?
  if [ "$rc" -eq 0 ]; then
    cac_log INFO "OK: $1"
  else
    cac_log ERROR "FAILED(rc=$rc): $* :: $(tr '\n' ' ' < "$err" | cut -c1-800)"
  fi
  cat "$err" >&2          # still surface stderr to the user/agent
  rm -f "$err"
  return "$rc"
}

cac_log_env() {
  cac_log INFO "ENV: os=$(sw_vers -productVersion 2>/dev/null || echo unknown) arch=$(uname -m) shell=$SHELL"
  cac_log INFO "ENV: git=$(git --version 2>/dev/null || echo none) gh=$(gh --version 2>/dev/null | head -n1 || echo none)"
  cac_log INFO "ENV: clone_root=$(cac_clone_root)"
}

cac_collect_logs() { # bundles audit.log into one file; echoes its path on success
  # Prefer ~/Desktop, but ensure it exists; if that fails, fall back to the
  # clone root (which always exists). Don't echo a path for a file we never wrote.
  local dir
  if mkdir -p "$HOME/Desktop" 2>/dev/null; then
    dir="$HOME/Desktop"
  else
    dir="$(cac_clone_root)"; mkdir -p "$dir" 2>/dev/null
  fi
  local out="$dir/cloudinary-ask-code-logs-$(date '+%Y%m%d-%H%M%S').txt"
  {
    echo "=== Cloudinary Ask Code — diagnostic bundle ==="
    echo "generated: $(date)"
    echo
    echo "=== environment (live) ==="
    echo "os=$(sw_vers -productVersion 2>/dev/null || echo unknown) arch=$(uname -m) shell=$SHELL"
    echo "git=$(git --version 2>/dev/null || echo none) gh=$(gh --version 2>/dev/null | head -n1 || echo none)"
    echo
    echo "=== audit.log ==="
    cat "$(cac_log_file)" 2>/dev/null || echo "(no audit log found)"
  } > "$out" 2>/dev/null
  # Only report success if the file actually exists and is non-empty.
  if [ -s "$out" ]; then
    cac_log INFO "COLLECT: wrote diagnostic bundle to $out"
    echo "$out"
    return 0
  fi
  cac_log ERROR "COLLECT: failed to write diagnostic bundle to $out"
  echo "ERROR: could not write diagnostic bundle to $out" >&2
  return 1
}

cac_clone_repo() { # $1 = url-or-owner/name, $2 = local dir name
  local src="$1" name="$2" root dest
  root="$(cac_clone_root)"; mkdir -p "$root"
  dest="$root/$name"
  if [ -d "$dest/.git" ]; then
    echo "  already cloned: $name" >&2; return 0
  fi
  # owner/name form -> full GitHub https URL; full URLs pass through.
  case "$src" in
    *://*|*@*:*|*/*.git) : ;;            # looks like a URL/path already
    */*) src="https://github.com/$src.git" ;;
  esac
  cac_log INFO "clone: $src -> $dest"
  cac_run git clone -q --depth=1 "$src" "$dest"
}

cac_ensure_gh_auth() {
  command -v gh >/dev/null 2>&1 || { cac_log ERROR "gh_auth: gh not found on PATH"; echo "ERROR: gh not found on PATH — run cac_ensure_gh first." >&2; return 1; }
  cac_log INFO "gh_auth: status check"
  if gh auth status >/dev/null 2>&1; then return 0; fi
  # Browser OAuth over https; also configures gh as git's credential helper.
  # NOTE: never wrap `gh auth login` in cac_run and never log its output — it
  # handles secrets/tokens. Only the fact that login is launching is logged.
  cac_log INFO "gh_auth: launching browser login"
  gh auth login --hostname github.com --git-protocol https --web
  gh auth setup-git >/dev/null 2>&1 || true
}

cac_main() {
  set -euo pipefail
  echo "cloudinary-ask-code bootstrap — use the SKILL wizard to drive this."
}

if [ "${CAC_LIB_ONLY:-0}" != "1" ]; then cac_main "$@"; fi
