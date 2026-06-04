#!/usr/bin/env bash
# cloudinary-ask-code freshness: ff-only pulls with a staleness guard.
# Sourceable for tests via CAC_LIB_ONLY=1.

cac_clone_root() { echo "${CAC_CLONE_ROOT:-$HOME/cloudinary-code}"; }
cac_sync_dir()  { echo "$(cac_clone_root)/.cac/sync"; }

cac_mark_synced() { # $1 = repo dir name
  mkdir -p "$(cac_sync_dir)"
  date +%s > "$(cac_sync_dir)/$1"
}

cac_needs_sync() { # $1 = repo name, $2 = threshold seconds; returns 0 (true) if stale
  local f now last
  f="$(cac_sync_dir)/$1"
  [ -f "$f" ] || return 0                 # never synced => stale
  now="$(date +%s)"; last="$(cat "$f")"
  [ $((now - last)) -ge "$2" ]
}

cac_sync_repo() { # $1 = repo name; ff-only, skip if dirty/diverged; records timestamp
  local dir; dir="$(cac_clone_root)/$1"
  [ -d "$dir/.git" ] || { echo "  not cloned: $1" >&2; return 0; }
  if [ -n "$(git -C "$dir" status --porcelain)" ]; then
    echo "  skip (local changes): $1" >&2; return 0
  fi
  if git -C "$dir" pull --ff-only -q 2>/dev/null; then
    cac_mark_synced "$1"
  else
    echo "  skip (cannot ff): $1" >&2
  fi
}

cac_main() {
  set -euo pipefail
  local if_stale=0 threshold="${CAC_STALE_SECONDS:-86400}"
  [ "${1:-}" = "--if-stale" ] && { if_stale=1; shift; }
  local repos="$*"
  [ -n "$repos" ] || repos="$(ls -1 "$(cac_clone_root)" 2>/dev/null | grep -v '^\.cac$')"
  for r in $repos; do
    if [ "$if_stale" = "1" ] && ! cac_needs_sync "$r" "$threshold"; then
      continue
    fi
    cac_sync_repo "$r"
  done
}

if [ "${CAC_LIB_ONLY:-0}" != "1" ]; then cac_main "$@"; fi
