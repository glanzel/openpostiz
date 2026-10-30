# Auto-rebase conflict resolution

A `git rebase upstream/main` is in progress and has conflicts.

You are working in the Postiz fork described by `FORK.md`. **Read `FORK.md` first.**

## Task

1. Inspect the conflict state: `git status`, `git diff`.
2. Resolve every conflict according to the rules in `FORK.md`:
   - `package.json`, `pnpm-lock.yaml`: must end up **identical to `upstream/main`**.
   - `Dockerfile.slim`, `var/docker/**`, `postiz-slim.yaml`: keep the fork's version.
   - `apps/orchestrator/src/main.ts`: keep the fork's watchdog change on top of upstream.
   - Other files: prefer upstream unless `FORK.md` says otherwise.
3. Stage resolved files with `git add`.
4. Continue the rebase with `git -c core.editor=true rebase --continue`.
   Repeat until the rebase is complete.
5. Verify:
   - `docker compose -f postiz-slim.yaml config -q` must succeed.
   - `docker build -f Dockerfile.slim -t postiz-slim:agent-test .` must succeed.
6. Do **not** push. Do **not** create extra commits.
   If you cannot resolve a conflict safely, run `git rebase --abort` and exit non-zero.

## Important

- Never modify files outside the conflict resolution.
- Keep `package.json` and `pnpm-lock.yaml` identical to upstream.
- The fork's intentional changes are listed in `FORK.md`.
