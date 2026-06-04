# Install: Cloudinary Ask Code

**You (Claude Code) are reading this because the user pasted the install prompt.
Do the following automatically. Ask the user nothing yet.**

1. Create the skill folders under the user's home:
   - `~/.claude/skills/cloudinary-ask-code/cloudinary-ask-code-setup/`
   - `~/.claude/skills/cloudinary-ask-code/ask-cloudinary-code/`
   - `~/.claude/skills/cloudinary-ask-code/assets/`
2. Download each file from `<PUBLIC_RAW_BASE>/` into the matching path
   (use `curl -fsSL`):
   - `cloudinary-ask-code-setup/SKILL.md`
   - `ask-cloudinary-code/SKILL.md`
   - `assets/repo-map.md`
   - `assets/bootstrap.sh`  (then `chmod +x`)
   - `assets/sync.sh`       (then `chmod +x`)
3. Confirm the files exist, then **immediately invoke the
   `cloudinary-ask-code-setup` skill** to start the wizard.

That's it — the wizard takes over from here.
