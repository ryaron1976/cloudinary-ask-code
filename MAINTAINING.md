# Maintaining Cloudinary Ask Code

## How to ship a fix to everyone
Installed users auto-update on next use (each session runs
`update.sh --if-newer`, which pulls the latest files if `VERSION` changed).

To release a change:
1. Edit the files (e.g. add a repo to `assets/repo-map.md`, fix a script, reword a SKILL).
2. **Bump `VERSION`** (e.g. `2026-06-04.2` → `2026-06-05.1`). This is what triggers
   every installed user to pull the update — a change that doesn't bump VERSION
   will NOT propagate.
3. Push to the public repo `ryaron1976/cloudinary-ask-code` (the `main` branch).
4. Within ~5 minutes (GitHub raw CDN cache) the new version is live; users get it
   on their next use.

## What's in the package
- `INSTALL.md` — the public bootstrap fetched by the paste-prompt to install the skill.
- `VERSION` — version stamp; bump on every release.
- `cloudinary-ask-code-setup/SKILL.md` — one-time setup wizard.
- `ask-cloudinary-code/SKILL.md` — daily ask flow.
- `assets/bootstrap.sh` — installer (gh, git), clone, stage-state, audit logging.
- `assets/sync.sh` — freshness (pull-on-use + staleness guard).
- `assets/update.sh` — self-update (stage-all-then-swap; safe on partial failure).
- `assets/repo-map.md` — PM area → repos (curated + add-on-demand).

## Notes
- macOS only (the install path assumes `.zip` gh asset, `xcode-select`, `~/.zshrc`).
- The gh install uses GitHub's **unauthenticated** releases API (60 req/hour per IP).
  A single user is fine; on a shared corporate IP this can rate-limit — the
  installer detects it and tells the user to retry shortly.
- Audit log: `~/cloudinary-code/.cac/audit.log`; diagnostic bundle via
  `cac_collect_logs` (lands on the user's Desktop).
