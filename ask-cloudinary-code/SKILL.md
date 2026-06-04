---
name: ask-cloudinary-code
description: Answer plain-English questions about Cloudinary's source code using the colleague's locally cloned repos. Use when the user asks how some Cloudinary feature/behavior works in the code, says "ask my Cloudinary code", or wants to explore their area's repos. Requires cloudinary-ask-code-setup to have been run.
---

# Ask Cloudinary Code

The colleague's repos are cloned under `~/cloudinary-code/`. Answer questions by
reading and grepping those local files. Always cite `file:line`.

If `~/cloudinary-code/` has no repos, tell them to run the setup wizard
(`cloudinary-ask-code-setup`) first and stop.

**Locating the scripts.** The skill's helper scripts are installed at a fixed
path. Set this at the start of every Bash command that needs them:
`ASSETS="$HOME/.claude/skills/cloudinary-ask-code/assets"`
Then call e.g. `"$ASSETS/sync.sh"` and `"$ASSETS/bootstrap.sh"`. Do NOT use
`$(dirname "$0")` — this is a prose instruction, not a script. Shell state does
not persist between Bash tool calls, so when a command needs a helper from
`bootstrap.sh`, source it **in the same command**
(`CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && <helper>`).

**Stay current.** At the very start of a session, check for a newer skill
version (don't block on it): `bash "$ASSETS/update.sh" --if-newer`. If it
reports an update, tell the user "I updated the Cloudinary Ask Code skill to the
latest version" and re-read this SKILL. If the user says "update the Cloudinary
code skill", run `bash "$ASSETS/update.sh"` (force).

**Audit logging.** Every question is logged to `~/cloudinary-code/.cac/audit.log`
(no secrets). Log the question and the repos you searched, self-sourced in the
same command, e.g.:
`CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_log INFO "ask: how does signup verification work | repos: idp,console"`

## On each question
0. **Log the question** (see Audit logging above) before doing anything else.
1. **Freshness (pull-on-use + staleness guard).** Before answering, refresh only
   the repos relevant to the question, and only if stale:
   `bash "$ASSETS/sync.sh" --if-stale <repo1> <repo2>`
   (threshold defaults to 24h; `--if-stale` skips repos synced more recently so
   answers stay fast). Then tell them quietly: "code last updated <X> ago" —
   read the last-sync epoch for the repo from `~/cloudinary-code/.cac/sync/<repo>`
   and express the age in plain words (e.g. "2 hours ago").
   If they say "sync everything now", run `bash "$ASSETS/sync.sh"` with no flag.
2. **Find & read.** Grep the relevant clones for the concepts in their question;
   open the matching files; trace the logic.
3. **Answer** in plain language for a PM (not a developer): what the code does,
   where, and the product-relevant implication. Cite `path/to/file.rb:123`.
4. If the answer spans repos they haven't cloned, offer to clone the extra repo
   (self-sourced in the same command):
   `CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_clone_repo <owner/name> <name>`.

## If anything fails
If a sync, clone, or any other step fails, create the diagnostic bundle and have
the user send it to Yaron:
`CAC_LIB_ONLY=1 source "$ASSETS/bootstrap.sh" && cac_collect_logs`
This prints a file path (on their Desktop, or in `~/cloudinary-code` if the
Desktop isn't available). Tell them in plain language to drag that file into
their Slack DM with Yaron so he can debug it.
