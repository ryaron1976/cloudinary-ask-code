#!/usr/bin/env bash
# Self-update for cloudinary-ask-code: re-fetch the package from the public repo.
#   update.sh            -> force update to latest
#   update.sh --if-newer -> update only if remote VERSION differs from local
# Safety: stages ALL files into a temp dir, then swaps them into place only if every
# download succeeded (all-or-nothing), applying VERSION LAST. A mid-download failure
# leaves the install completely untouched, so it can't be left half-updated/bricked
# and the next --if-newer run retries instead of falsely reporting "up to date".
# Env overrides (for tests): CAC_UPDATE_BASE, CAC_SKILL_DIR.

CAC_UPDATE_BASE_DEFAULT="https://raw.githubusercontent.com/ryaron1976/cloudinary-ask-code/main"
cac_update_base()   { echo "${CAC_UPDATE_BASE:-$CAC_UPDATE_BASE_DEFAULT}"; }
cac_skill_dir()     { echo "${CAC_SKILL_DIR:-$HOME/.claude/skills/cloudinary-ask-code}"; }
cac_local_version() { cat "$(cac_skill_dir)/VERSION" 2>/dev/null || echo "none"; }
cac_remote_version(){ curl -fsSL "$(cac_update_base)/VERSION" 2>/dev/null || echo ""; }

cac_do_update() {
  local base dir f stage
  base="$(cac_update_base)"; dir="$(cac_skill_dir)"
  # All-or-nothing: download EVERY file into a fresh staging dir first, touching no
  # installed file. If ANY download fails, wipe staging and bail — the install is
  # left completely untouched (so VERSION still trails the old content and the next
  # --if-newer will retry instead of falsely reporting "up to date"). Only after the
  # whole package downloads cleanly do we swap files into place, applying VERSION
  # LAST (belt and suspenders) so VERSION never leads the content.
  stage="$dir/.update-staging.$$"
  rm -rf "$stage"; mkdir -p "$stage" || { echo "ERROR: cannot create staging dir" >&2; return 1; }
  set -- VERSION INSTALL.md "cloudinary-ask-code-setup/SKILL.md" \
         "ask-cloudinary-code/SKILL.md" "assets/repo-map.md" \
         "assets/bootstrap.sh" "assets/sync.sh" "assets/update.sh"
  # Stage 1: download all files into staging. Abort on the first failure.
  for f in "$@"; do
    mkdir -p "$stage/$(dirname "$f")"
    if ! curl -fsSL "$base/$f" -o "$stage/$f"; then
      rm -rf "$stage"; echo "ERROR: update failed downloading $f (install untouched)" >&2; return 1
    fi
  done
  # Stage 2: everything downloaded — swap into place. VERSION last.
  for f in "$@"; do
    [ "$f" = "VERSION" ] && continue
    mkdir -p "$dir/$(dirname "$f")"
    mv "$stage/$f" "$dir/$f"
  done
  mv "$stage/VERSION" "$dir/VERSION"
  chmod +x "$dir"/assets/*.sh 2>/dev/null || true
  rm -rf "$stage"
  return 0
}

main() {
  set -uo pipefail
  local mode="${1:-force}" local_v remote_v
  local_v="$(cac_local_version)"; remote_v="$(cac_remote_version)"
  if [ "$mode" = "--if-newer" ]; then
    [ -n "$remote_v" ] || { echo "(offline — keeping current version $local_v)"; exit 0; }
    [ "$remote_v" = "$local_v" ] && { echo "Cloudinary Ask Code is up to date ($local_v)."; exit 0; }
    echo "Updating Cloudinary Ask Code: $local_v -> $remote_v ..."
  else
    echo "Updating Cloudinary Ask Code (current: $local_v) ..."
  fi
  if cac_do_update; then
    echo "Updated to $(cac_local_version)."
    if [ -f "$(cac_skill_dir)/assets/bootstrap.sh" ]; then
      CAC_LIB_ONLY=1 source "$(cac_skill_dir)/assets/bootstrap.sh" 2>/dev/null && cac_log INFO "self_update: now $(cac_local_version)" 2>/dev/null || true
    fi
  else
    echo "Update failed — keeping current version $local_v. See audit log." >&2
    exit 1
  fi
}
main "$@"
