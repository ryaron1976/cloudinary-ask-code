---
name: cloudinary-ask-code-setup
description: One-time setup so a Cloudinary PM (no GitHub experience needed) can ask questions about their codebase. Use when the user wants to get set up to query Cloudinary code, mentions installing the cloudinary-ask-code skill, or has just pasted the install prompt. Resumable across sessions.
---

# Cloudinary Ask Code — Setup Wizard

You are setting up a **non-developer** colleague. Do everything for them via the
shell. Ask **one question at a time**. Never assume any tool is installed.

**Locating the scripts.** The skill's helper scripts are installed at a fixed
path. Set this at the start of every Bash command that needs them:
`ASSETS="$HOME/.claude/skills/cloudinary-ask-code/assets"`
Then call e.g. `"$ASSETS/bootstrap.sh"` and `"$ASSETS/sync.sh"`. Do NOT use
`$(dirname "$0")` — this is a prose instruction, not a script.

**Shell state does not persist between Bash tool calls.** Each Bash invocation
is a fresh shell, so a `source` in one call is gone by the next. Always source
`bootstrap.sh` **in the same command** as the helper you call. For example:
`CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_ensure_git`

Check the resume point before doing anything (self-source in the same command):
`CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_get_stage`. Skip any
stage whose number is ≤ the stored stage. After finishing a stage, record it
with `cac_set_stage <n>` (again, self-sourced in the same command).

**Audit logging.** Everything the wizard does is logged to
`~/cloudinary-code/.cac/audit.log` so a failure on the colleague's machine can be
reconstructed. NEVER log secrets or tokens.
- Run once at the START of setup (Stage 0/preflight):
  `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_log_env`
- At the start of each stage, log it, e.g.:
  `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_log INFO "stage 3: install tooling"`
- After the colleague answers a question, log a short summary (no secrets):
  `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_log INFO "answer: has GitHub account = yes"`

## Stage 0 — Preflight (no stage marker — just a gate)
Before Stage 1, confirm the environment:
- This must be **macOS** — the scripts assume it (`.zip` gh asset,
  `xcode-select`, `~/.zshrc`). If not macOS, tell the user this skill currently
  supports macOS only and **stop**.
- Confirm this is running in Claude Code.
- Start the audit log with an environment snapshot (run once):
  `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_log_env`
`~/cloudinary-code/` is created lazily by the scripts, so no mkdir is needed.

## Stage 1 — GitHub account (stage marker: 1)
Cloudinary requires a **dedicated** GitHub account (not a personal one), named
`FirstInitialLastName-cloudinary` (e.g. `jdoe-cloudinary`), registered with the
Cloudinary email, with 2FA on.
- Ask the colleague (one question): "Do you already have a Cloudinary GitHub
  account (username ending in `-cloudinary`)?"
- If no: walk them to https://github.com/signup — tell them the exact username
  to use and to enable 2FA. Wait for them to confirm the username, then continue.
- Record: `cac_set_stage 1`.

## Stage 2 — Okta access (stage marker: 2) — ONLY human-gated step
- Tell them: in Okta, open their profile and put the new GitHub username in the
  "GitHub Username" field, then save. Within ~5–10 min Okta emails an org invite
  and a GitHub-org app appears in Okta; they should log in to the org **through
  Okta** (do NOT press GitHub's "Join").
- Ask (one question): "Do you now see a Cloudinary GitHub organization app in
  your Okta dashboard?"
- If **no after waiting**: this is the only step we cannot automate — tell them
  to open an **IT ticket** ("GitHub org not appearing in Okta") and resume this
  wizard once IT confirms. Stop here; `cac_set_stage 1` stays so they re-enter
  at Stage 2.
- If yes: `cac_set_stage 2`.

## Stage 3 — Install tooling (stage marker: 3)
Run, and report progress plainly (each self-sourced in the same command):
- `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_ensure_git` (may pop the
  Apple Command Line Tools dialog — tell them to click Install; no password).
- `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_ensure_gh` (installs gh to
  `~/.local/bin`, no admin).
- Record: `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_set_stage 3`.

## Stage 4 — Authenticate (stage marker: 4)
- Run `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_ensure_gh_auth`. A
  browser opens; tell them to log in with the **Cloudinary** GitHub account and
  approve.
- Verify (a fresh shell won't have `~/.local/bin` on PATH, so prepend it):
  `export PATH="$HOME/.local/bin:$PATH" && gh api user --jq .login` prints their
  `-cloudinary` username.
- Record: `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_set_stage 4`.

## Stage 5 — Pick area & clone (stage marker: 5)
- Read `"$ASSETS/repo-map.md"`. Show the area names and ask (one question):
  "Which area is yours?" Offer a final option: "My repo isn't listed."
- For the chosen area, clone each repo. The second argument is the local dir
  name — use the part after `/`. Self-source in the same command, e.g.:
  `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_clone_repo CloudinaryLtd/idp idp`
  (local dir = `idp`).
- If "not listed": ask for the `owner/name`, then clone it the same way.
- Record: `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_set_stage 5`.

## Stage 6 — Handoff
- Tell them setup is done. To ask questions, they just say
  "ask my Cloudinary code: <question>" (the `ask-cloudinary-code` skill).
- Run ONE sample question end-to-end to prove it works (grep their clones for a
  recognizable term and answer with a `file:line` citation).
- Create the diagnostic bundle so they have it on hand:
  `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_collect_logs`
  This prints a file path (on their Desktop, or in `~/cloudinary-code` if the
  Desktop isn't available). Tell them in plain words: "drag that file into your
  Slack DM with Yaron if anything ever goes wrong, so he can debug it."

## If ANY step fails (standing rule)
Whenever any stage above fails — or the colleague asks for help — create the
diagnostic bundle and have them send it to Yaron:
`CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_collect_logs`
The command prints a file path (on their Desktop, or in `~/cloudinary-code` if
the Desktop isn't available). Tell them in plain language to drag that file into
their Slack DM with Yaron so he can debug what went wrong. This bundle is the
whole point of the audit log — surface it prominently, don't bury it.
