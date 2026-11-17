#!/usr/bin/env bash
# The repo's checks. Exit 0 only when the branch is fit to review.
#
# The gate runs this script from the main checkout with the job's worktree as
# the working directory. Keep it fast, deterministic and non-interactive: no
# watch modes, no prompts, nothing that rewrites files.
#
# The project has no application code yet, so this runs whichever of the
# standard package.json scripts exist. Each must be non-interactive and must
# not rewrite files. Once the stack settles, replace this with explicit
# commands so a missing script fails instead of being skipped.
set -euo pipefail

export CI=true # keeps test runners (vitest, jest) out of watch mode

if [[ -f package.json ]]; then
  if [[ -f package-lock.json ]]; then
    npm ci --prefer-offline --no-audit --no-fund
  else
    npm install --no-audit --no-fund
  fi
  for script in lint typecheck test build; do
    npm run --if-present "$script"
  done
fi
