# fly-the-dip

A flight price watcher to catch the lowest flight prices. The project is new:
there is no application code or chosen stack yet.

## Setup

In a fresh checkout:

```bash
npm ci
```

No env files yet. When the project needs secrets (e.g. flight data API keys),
add a committed `.env.example` and copy it to `.env`; never commit `.env`.

## Dev server

None yet. When one is added, document here how to start it on a given port
(e.g. `PORT=5100 npm run dev`); the factory's reviewers use it.

## Validation

`factory/checks.sh` is the source of truth. It runs `npm ci`, then whichever
of `npm run lint`, `npm run typecheck`, `npm test` and `npm run build` exist.
Keep these scripts non-interactive and non-mutating (no watch mode, no
`--fix`).

## Software factory

`/factory run` builds every open GitHub issue labeled `factory` through
intake → spec → build → gate → review → approve, one PR per issue. State is in
`factory/jobs/` (gitignored); `factory/bin/job` is its only writer. Checks:
`factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then
open http://localhost:8000/dashboard.html.

Each job works in its own git worktree, a full checkout of the repo at
`.worktrees/<job-id>` (gitignored). A tool run from the repo root that doesn't
read `.gitignore` sees those copies too; exclude `.worktrees/` in its config.
