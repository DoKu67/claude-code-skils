---
name: skills-repo-access
description: Clone, branch, push and open a pull request against the skills repository (DoKu67/claude-code-skils) from inside a Devin session, using the personal secret DOKU67_SKILLS_GITHUB_TOKEN instead of Devin's org GitHub integration. Use whenever a change must land in the skills repo — a codified candidate, an edited SKILL.md, a fix to scripts or hooks — and whenever a push to that repo fails with 403 or "Authentication failed" on git-manager.devin.ai. Never pushes to main; every change goes out as a PR for the owner to merge.
---

# skills-repo-access

Devin's built-in git auth only covers the organisation's repositories. The skills repo is
personal, so it is reached with a fine-grained PAT stored as the personal Devin secret
`DOKU67_SKILLS_GITHUB_TOKEN` (Contents + Pull requests, read/write, that one repo only).

Two things get in the way and both are worked around below:

1. The VM's global git config rewrites `https://github.com/` to the Devin proxy, which
   rejects the token. Writing the host as `GitHub.com` defeats the rewrite (it is
   case-sensitive) while GitHub itself does not care.
2. The default credential helper answers for the proxy. Disable it and supply the token via
   `GIT_ASKPASS`.

## Procedure

```sh
# 1. askpass helper — username is arbitrary for a PAT, password is the token
mkdir -p ~/.local/bin
printf '#!/bin/sh\ncase "$1" in *sername*) echo x-access-token;; *) echo "$DOKU67_SKILLS_GITHUB_TOKEN";; esac\n' \
  > ~/.local/bin/doku67-askpass && chmod +x ~/.local/bin/doku67-askpass
export GIT_ASKPASS=~/.local/bin/doku67-askpass GIT_TERMINAL_PROMPT=0

# 2. fresh clone (never edit the materialised plugin under /opt/.devin/plugins)
git -c credential.helper= clone https://GitHub.com/DoKu67/claude-code-skils.git ~/skills-direct
cd ~/skills-direct

# 3. branch, edit, commit, push
git checkout -b devin/<slug>
# ... edit skills/<name>/SKILL.md, skills-staging/..., etc.
git add <paths> && git commit -m "<what and why>"
git -c credential.helper= push -u origin HEAD

# 4. open the PR through the API (the builtin PR tool cannot see this repo)
curl -sS -X POST https://api.github.com/repos/DoKu67/claude-code-skils/pulls \
  -H "Authorization: Bearer $DOKU67_SKILLS_GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
  -d "$(jq -n --arg t "<title>" --arg h "devin/<slug>" --arg b "<body>" '{title:$t,head:$h,base:"main",body:$b}')" \
  | jq -r .html_url
```

The exec tool must bind the secret explicitly:
`env: {"DOKU67_SKILLS_GITHUB_TOKEN": "secret:session:DOKU67_SKILLS_GITHUB_TOKEN"}`.

## Rules

- Never push to `main`, never merge. The owner (DoKu67) reviews and merges every PR.
- Never print, log or commit the token; it appears only as `$DOKU67_SKILLS_GITHUB_TOKEN`.
- One PR per change; keep the diff to the skill surfaces the `.gitignore` allowlists.
- If the API returns 401, the token has expired — ask the user for a new one via the secret
  prompt (`DOKU67_SKILLS_GITHUB_TOKEN`, personal scope); do not attempt other routes.
- If the secret is missing from the session, stop and ask; do not fall back to the org
  integration (it returns 403 for this repo).
