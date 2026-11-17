---
name: factory-setup
description: Finish installing the software factory after `npx agent-factory init`. Tailors factory/checks.sh, the reviewer agents and AGENTS.md to this project, then verifies the install. Use when the user types /factory-setup or asks to finish, adapt or verify the factory install.
---

# Factory setup

`npx agent-factory init` already copied the factory's skill, agents, scripts
and dashboard into this project, set `base_branch` and `merge_method` in
`factory/config.json`, appended the `.gitignore` lines, and (if it could)
generated `factory/checks.sh` from `package.json`. Your job is the part that
needs judgment: make the factory fit this project, verify it, and report.
Work in the project's root.

## 1. `factory/checks.sh`

Read it. If it still says "has no checks yet", or if what `init` generated is
incomplete, replace the body with the project's real checks: install
dependencies if a fresh worktree needs them, then lint, typecheck, tests and
build, whichever the project has. Find them in `AGENTS.md`, `CLAUDE.md`,
`package.json` scripts, `Makefile`, `pyproject.toml` and CI config
(`.github/workflows/`).

The script runs with a job's worktree (a fresh checkout) as its working
directory. It must be non-interactive (no watch modes), must not rewrite files
(no `--fix`, no `--write`, no `--update-snapshots`), and must exit non-zero on
any failure. Keep `set -euo pipefail`. If a `package.json` script it calls does
any of those things, call the underlying tool directly instead.

## 2. `factory/config.json`

- Check `base_branch` and `merge_method` (init detected them; confirm with
  `gh repo view --json defaultBranchRef` and
  `gh api repos/{owner}/{repo} --jq '{allow_merge_commit, allow_squash_merge, allow_rebase_merge}'`).
- `protected_paths`: keep the two factory entries and don't add the project's
  tests. Features legitimately change tests, and a protected test blocks a
  job with no way through. Add a path only when no job should ever change it.
  They are fnmatch patterns, so `*` also matches `/`.
- `ports`: move `base` if the project already uses ports 5100–5199.
- Leave `concurrency`, `max_rounds`, `routing`, `surface_reviewers` and
  `prices_usd_per_mtok` alone unless the user asks.

## 3. Agents

The checklists in `.claude/agents/` are general on purpose. Tailor them to the
stack **without changing their structure, file names, frontmatter, first-line
formats or one-line replies**:

- `reviewer-security.md`: this project's hot spots (its auth, its data access
  rules, its payment and webhook code, where user input meets queries or HTML).
- `reviewer-ui.md`: where the design tokens, theme and shared components live.
- `reviewer-ux.md`: the kinds of users the app has.
- `approver.md`: what a human must always see in this project, added to the
  ESCALATE list.
- `intake.md`: one line under **Decide** saying what the project is for, so
  intake can tell what belongs.

## 4. `AGENTS.md`

Use `AGENTS.md` or `CLAUDE.md`, whichever the project has; create `AGENTS.md`
if neither exists. Every agent reads it. Make sure it says:

- how to set up a fresh checkout (install dependencies, env files to copy);
- how to start the dev server on a given port, if the project has one;
- the validation commands, matching `factory/checks.sh`.

Then add this section if it isn't there:

```markdown
## Software factory

`/factory run` builds every open GitHub issue labeled `factory` through
intake → spec → build → gate → review → approve, one PR per issue. State is in
`factory/jobs/` (gitignored); `factory/bin/job` is its only writer. Checks:
`factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then
open http://localhost:8000/dashboard.html.

Each job works in its own git worktree, a full checkout of the repo at
`.worktrees/<job-id>` (gitignored). A tool run from the repo root that doesn't
read `.gitignore` sees those copies too; exclude `.worktrees/` in its config.
```

If the project has tools that scan the repo without reading `.gitignore`
(some ESLint, Jest, Vitest, TypeScript or Tailwind configs), add `.worktrees/`
to their ignore lists now.

## 5. Labels

Run `npx agent-factory labels` (idempotent). It creates `factory`,
`factory:needs-info` and `factory:needs-human` on GitHub.

## 6. Verify

Run `npx agent-factory doctor --full`. It checks the toolchain, the files,
agent frontmatter, `config.json`, `.gitignore`, the labels, runs
`factory/checks.sh` in the project root and runs `factory/bin/job queue`.
Fix anything it reports. If `checks.sh` fails on the current branch, the
factory can never pass a job: fix the script (not the project) or tell the
user what's broken.

## 7. Hand over

Stay on the branch the user is on. Commit the install with a one-line message
and show the user the diff. Ask before pushing: the factory branches every job
from `origin/<base_branch>`, so the install must be on that branch there
before the first run.

Then tell the user, in a few lines:

- Label one or two small issues `factory`, then run `/factory run` in Claude
  Code from the project root.
- Every job ends as a PR. The approver merges what it approves; the rest wait
  labeled `factory:needs-human`. Approve one by merging it on GitHub, or tell
  the factory what to change with `/factory <anything>`.
- Intake runs on Fable, once per issue. Depending on their plan, Fable can
  bill to usage credits rather than the plan's included usage.
- To start carefully, set `concurrency` to 1 in `factory/config.json` and read
  every PR until they trust it.
- `npx agent-factory update` pulls newer factory scripts later. It overwrites
  only files nobody has edited since install, and never touches
  `factory/checks.sh` or the values in `factory/config.json`.
